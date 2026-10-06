#!/usr/bin/env python3
"""Off-CPU screen of the CONSTRUCT export thread (fiber rework, 2026-10-05).

Question: on top of a given stack part, does the cold export still block in
io_uring waits, and for how long?  Fibers can only hide time that the export
thread spends off-CPU waiting for reads.

Per execution (fresh server, page cache dropped before every cold start):
  - per-thread on-CPU and run-queue time from /proc/<pid>/task/*/schedstat;
    the export thread is the thread with the largest on-CPU delta;
  - a /proc sampler (default every 1 ms) that reads, for every thread, the
    state from task/<tid>/stat and, while the thread sleeps, the current
    syscall number from task/<tid>/syscall.  The off-CPU time of the export
    thread is split by syscall in proportion to its sleeping samples;
  - optional flat on-CPU profile (perf record -F 999, no call graph) of the
    whole server, reported per symbol for the export thread;
  - response bytes + xxh3_128 of the body (byte-identity across arms).
Arms are interleaved per trial with alternating order.  Timing here is a
screen (the sampler costs CPU on another core); verdict timing comes from the
A/B driver.

Arms: --arm LABEL=/path/to/qlever-server[,runtime-param=value,...]
"""

from __future__ import annotations

import argparse
import collections
import json
import os
import shutil
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path

import httpx
import xxhash

READY = "The server is ready, listening for requests on port "
SYSCALLS = {0: "read", 1: "write", 7: "poll", 17: "pread64", 20: "writev", 23: "select", 35: "nanosleep",
            44: "sendto", 46: "sendmsg", 202: "futex", 230: "clock_nanosleep", 232: "epoll_wait",
            270: "pselect6", 271: "ppoll", 281: "epoll_pwait", 327: "preadv2", 426: "io_uring_enter",
            441: "epoll_pwait2", 9: "mmap", 11: "munmap", 28: "madvise", 10: "mprotect"}


def schedstat(pid: int) -> dict[int, tuple[str, int, int]]:
    snap = {}
    for t in Path(f"/proc/{pid}/task").iterdir():
        try:
            run, wait, _ = (int(x) for x in (t / "schedstat").read_text().split())
            snap[int(t.name)] = ((t / "comm").read_text().strip(), run, wait)
        except (OSError, ValueError):
            pass
    return snap


class Sampler:
    """Samples state and current syscall of every thread of `pid`."""

    def __init__(self, pid: int, period_s: float) -> None:
        self.pid, self.period = pid, period_s
        self.counts: dict[int, collections.Counter] = collections.defaultdict(collections.Counter)
        self.iterations = 0
        self.stop_ = threading.Event()
        self.fds: dict[int, tuple[int, int, int]] = {}
        # Last (comm, on-CPU ns, run-queue ns) seen per thread, so threads that
        # exit before the end of the query (per-query workers) still count.
        self.last: dict[int, tuple[str, int, int]] = {}
        self.comm: dict[int, str] = {}
        self.t = threading.Thread(target=self.loop, daemon=True)

    def refresh(self) -> None:
        for name in os.listdir(f"/proc/{self.pid}/task"):
            tid = int(name)
            if tid in self.fds:
                continue
            try:
                self.fds[tid] = (os.open(f"/proc/{self.pid}/task/{tid}/stat", os.O_RDONLY),
                                 os.open(f"/proc/{self.pid}/task/{tid}/syscall", os.O_RDONLY),
                                 os.open(f"/proc/{self.pid}/task/{tid}/schedstat", os.O_RDONLY))
                self.comm[tid] = Path(f"/proc/{self.pid}/task/{tid}/comm").read_text().strip()
            except OSError:
                pass

    def loop(self) -> None:
        while not self.stop_.is_set():
            if self.iterations % 50 == 0:
                try:
                    self.refresh()
                except OSError:
                    return
            for tid, (fs, fc, fq) in list(self.fds.items()):
                try:
                    run, rq, _ = (int(x) for x in os.pread(fq, 128, 0).split())
                    self.last[tid] = (self.comm.get(tid, "?"), run, rq)
                    st = os.pread(fs, 512, 0)
                    state = chr(st[st.rindex(b")") + 2])
                    if state in "SD":
                        tok = os.pread(fc, 64, 0).split(b" ", 1)[0].decode().strip()
                        key = f"{state}:" + (SYSCALLS.get(int(tok), f"nr{tok}") if tok.lstrip("-").isdigit() else tok)
                    else:
                        key = state
                    self.counts[tid][key] += 1
                except (OSError, ValueError):
                    for fd in (fs, fc, fq):
                        try:
                            os.close(fd)
                        except OSError:
                            pass
                    del self.fds[tid]
            self.iterations += 1
            time.sleep(self.period)

    def start(self) -> "Sampler":
        self.refresh()
        self.t.start()
        return self

    def stop(self) -> None:
        self.stop_.set()
        self.t.join()
        for fds in self.fds.values():
            for fd in fds:
                try:
                    os.close(fd)
                except OSError:
                    pass


def run_query(port: int, query: str, action: str, accept: str) -> tuple[int, str, float, int]:
    h = xxhash.xxh3_128()
    n = 0
    t0 = time.perf_counter()
    with httpx.stream("POST", f"http://127.0.0.1:{port}/", data={"query": query, "action": action},
                      headers={"Accept": accept},
                      timeout=httpx.Timeout(connect=10.0, read=None, write=10.0, pool=10.0)) as r:
        for chunk in r.iter_bytes():
            n += len(chunk)
            h.update(chunk)
        status = r.status_code
    return n, h.hexdigest(), time.perf_counter() - t0, status


def one_exec(args, label: str, binary: str, rps: list[str], qpath: Path, trial: int, out: Path, log) -> dict:
    d = out / qpath.stem / f"{label}-t{trial}"
    d.mkdir(parents=True, exist_ok=True)
    r = subprocess.run(args.evict_cmd, shell=True, capture_output=True, text=True)
    row = {"query": qpath.stem, "arm": label, "trial": trial, "evict_rc": r.returncode}
    cmd = [binary, "--index-basename", args.index_basename, "--port", str(args.port), "--no-access-check",
           "--cache-max-size", "0B", "--cache-max-size-single-entry", "0B", "--cache-max-size-lazy-result", "0B",
           "--cache-max-num-entries", "0", "--default-query-timeout", "1800s", "--num-simultaneous-queries", "1"]
    for rp in rps:
        cmd += ["--set-runtime-parameter", rp]
    logf = (d / "qlever-server.log").open("wb")
    proc = subprocess.Popen(cmd, cwd=Path(args.index_basename).parent, stdout=logf, stderr=subprocess.STDOUT,
                            start_new_session=True)
    try:
        t0 = time.time()
        while READY not in (d / "qlever-server.log").read_text(errors="replace"):
            if proc.poll() is not None or time.time() - t0 > args.ready_timeout:
                raise RuntimeError(f"server not ready (rc={proc.poll()})")
            time.sleep(0.25)
        pid = proc.pid
        query = qpath.read_text()
        perf = None
        if args.perf_cpu and trial == args.trials:
            perf = subprocess.Popen(["perf", "record", "-F", "999", "-p", str(pid), "-o", str(d / "perf-cpu.data")],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(1.0)
        s0 = schedstat(pid)
        sampler = Sampler(pid, args.sample_ms / 1000.0).start()
        nbytes, digest, elapsed, status = run_query(args.port, query, args.action, args.accept)
        sampler.stop()
        s1 = dict(sampler.last)
        s1.update(schedstat(pid))
        if perf is not None:
            perf.send_signal(signal.SIGINT)
            perf.wait(timeout=60)
        threads = []
        for tid, (comm, run1, rq1) in s1.items():
            _, run0, rq0 = s0.get(tid, (comm, 0, 0))
            threads.append({"tid": tid, "comm": comm, "run_s": (run1 - run0) / 1e9, "runq_s": (rq1 - rq0) / 1e9})
        threads.sort(key=lambda t: -t["run_s"])
        ex = threads[0]
        off = max(elapsed - ex["run_s"] - ex["runq_s"], 0.0)
        c = sampler.counts.get(ex["tid"], collections.Counter())
        sleeping = {k: v for k, v in c.items() if k[0] in "SD"}
        nsleep = sum(sleeping.values())
        row.update({"status": status, "bytes": nbytes, "xxh3_128": digest, "elapsed_s": round(elapsed, 3),
                    "export_tid": ex["tid"], "export_run_s": round(ex["run_s"], 3),
                    "export_runq_s": round(ex["runq_s"], 3), "export_offcpu_s": round(off, 3),
                    "server_cpu_s": round(sum(t["run_s"] for t in threads), 3),
                    "sampler_iterations": sampler.iterations, "export_samples": sum(c.values()),
                    "export_sleep_samples": nsleep,
                    "export_offcpu_by_syscall_s": {k: round(off * v / nsleep, 3) for k, v in
                                                   sorted(sleeping.items(), key=lambda kv: -kv[1])} if nsleep else {},
                    "export_state_samples": dict(c.most_common()),
                    "top_threads": threads[:6],
                    "thread_samples": {str(t["tid"]): dict(sampler.counts.get(t["tid"], {})) for t in threads[:6]}})
        if perf is not None and (d / "perf-cpu.data").exists():
            rep = subprocess.run(["perf", "report", "-i", str(d / "perf-cpu.data"), "--stdio", "--no-children",
                                  "--tid", str(ex["tid"]), "--sort", "sym", "--percent-limit", "0.3"],
                                 capture_output=True, text=True)
            (d / "perf-cpu-export-thread.txt").write_text(rep.stdout)
    except Exception as e:  # noqa: BLE001
        row["error"] = repr(e)
        log(f"{label} {qpath.stem} t{trial}: {e!r}")
    finally:
        os.killpg(proc.pid, signal.SIGTERM)
        try:
            proc.wait(timeout=30)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
        logf.close()
    (d / "row.json").write_text(json.dumps(row, indent=1))
    return row


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--index-basename", required=True)
    ap.add_argument("--query", action="append", required=True)
    ap.add_argument("--action", default="turtle_export")
    ap.add_argument("--accept", default="text/turtle")
    ap.add_argument("--arm", action="append", required=True)
    ap.add_argument("--trials", type=int, default=3)
    ap.add_argument("--evict-cmd", required=True)
    ap.add_argument("--sample-ms", type=float, default=1.0)
    ap.add_argument("--perf-cpu", action="store_true", help="flat perf profile on the last trial")
    ap.add_argument("--port", type=int, default=7015)
    ap.add_argument("--ready-timeout", type=float, default=300.0)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    def log(msg: str) -> None:
        line = f"[{time.strftime('%FT%TZ', time.gmtime())}] {msg}"
        print(line, flush=True)
        with (out / "offcpu-screen.log").open("a") as fh:
            fh.write(line + "\n")

    arms = []
    for spec in args.arm:
        label, rest = spec.split("=", 1)
        binary, *rps = rest.split(",")
        ver = subprocess.run([binary, "--version"], capture_output=True, text=True).stdout.splitlines()[:1]
        log(f"arm {label}: {binary} {ver} rps={rps}")
        arms.append((label, binary, rps))
    rows = []
    for trial in range(1, args.trials + 1):
        for q in args.query:
            order = arms if trial % 2 else list(reversed(arms))
            for label, binary, rps in order:
                row = one_exec(args, label, binary, rps, Path(q), trial, out, log)
                log(json.dumps({k: row.get(k) for k in ("query", "arm", "trial", "status", "elapsed_s",
                                                        "export_run_s", "export_offcpu_s",
                                                        "export_offcpu_by_syscall_s", "error")}))
                rows.append(row)
    (out / "rows.json").write_text(json.dumps(rows, indent=1))
    digests = collections.defaultdict(set)
    for r in rows:
        digests[r["query"]].add(r.get("xxh3_128"))
    md = ["| query | arm | trial | elapsed s | export on-CPU s | export off-CPU s | off-CPU by syscall (s) | server CPU s |",
          "|---|---|---|---|---|---|---|---|"]
    for r in rows:
        by = ", ".join(f"{k}={v}" for k, v in list(r.get("export_offcpu_by_syscall_s", {}).items())[:5])
        md.append(f"| {r['query']} | {r['arm']} | {r['trial']} | {r.get('elapsed_s')} | {r.get('export_run_s')} | "
                  f"{r.get('export_offcpu_s')} | {by} | {r.get('server_cpu_s')} |")
    md.append("")
    for q, ds in digests.items():
        md.append(f"{q}: byte-identical across arms and trials: {'yes' if len(ds) == 1 else 'NO ' + str(ds)}")
    (out / "offcpu.md").write_text("\n".join(md) + "\n")
    Path(out / "COMPLETE").write_text("done\n")
    log("done")
    return 0 if all("error" not in r and r.get("status") == 200 for r in rows) else 1


if __name__ == "__main__":
    sys.exit(main())
