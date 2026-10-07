#!/usr/bin/env python3
"""I/O characterisation screen of a cold CONSTRUCT export (2026-10-06).

Question: which Wikidata export workloads put the export thread into
io_uring waits long enough (>= 10 % of wall time) that latency-hiding
mechanisms (wave reaping, fibers, depth-2 overlap) could matter?

One binary, a plan of (query, memory cap) configurations, N trials.
Per execution (fresh server, page cache dropped before every start):
  - wall time, time to first body byte (TTFB), response bytes, lines, xxh3_128;
  - per-thread on-CPU / run-queue time from /proc/<pid>/task/*/schedstat; the
    export thread is the thread with the largest on-CPU delta (same rule as
    offcpu_screen.py of the fiber rework);
  - a /proc sampler (default 1 ms) of every thread's state and, while it
    sleeps, its current syscall; the export thread's off-CPU time is split by
    syscall in proportion to its sleeping samples (offcpu_screen.py method);
  - LD_PRELOAD entry counts (io_counts_preload.c): pread/pread64, preadv2 with
    RWF_NOWAIT and its EAGAIN misses, liburing submits.  Page-cache hit share of
    the fast-path vocabulary reads = 1 - EAGAIN / RWF_NOWAIT calls;
  - /proc/<pid>/io deltas (read_bytes, rchar, syscr);
  - /proc/diskstats of the index devices sampled every 0.25 s: bytes read,
    reads, average queue depth (iostat aqu-sz = delta time_in_queue / delta t),
    read await, bandwidth over the whole request and over the export phase
    (TTFB .. end), peak 1 s bandwidth;
  - the server runs in a user systemd scope (systemd-run --user --scope);
    capped configurations set MemoryMax = calibrated peak anonymous RSS +
    headroom, MemorySwapMax=0, and record memory.peak / memory.events /
    memory.stat (workingset_refault_file, pgmajfault).

Plan file (JSON list): {"label": str, "query": path, "cap_headroom_gib": null|float,
                        "rps": ["name=value", ...]}
"""

from __future__ import annotations

import argparse
import collections
import json
import math
import os
import shutil
import signal
import struct
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
MAGIC = 0x514C4556494F4332
FIELDS = ["pread", "preadv2", "preadv2_nowait", "preadv2_eagain", "io_uring_enter", "liburing_submit"]
GIB = 1 << 30


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
    """Samples state and current syscall of every thread of `pid` (offcpu_screen.py)."""

    def __init__(self, pid: int, period_s: float) -> None:
        self.pid, self.period = pid, period_s
        self.counts: dict[int, collections.Counter] = collections.defaultdict(collections.Counter)
        self.iterations = 0
        self.stop_ = threading.Event()
        self.fds: dict[int, tuple[int, int, int]] = {}
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


def diskstats(devs: list[str]) -> dict[str, list[int]]:
    out = {}
    for line in Path("/proc/diskstats").read_text().splitlines():
        f = line.split()
        if len(f) >= 14 and f[2] in devs:
            out[f[2]] = [int(x) for x in f[3:14]]  # reads merged sectors ms_read writes wmerged wsect ms_w inflight io_ticks tiq
    return out


def rss_anon(pid: int) -> int:
    try:
        for line in Path(f"/proc/{pid}/status").read_text().splitlines():
            if line.startswith("RssAnon:"):
                return int(line.split()[1]) * 1024
    except OSError:
        pass
    return -1


class DiskSampler:
    """/proc/diskstats + server RssAnon every `period` s, timestamps from perf_counter."""

    def __init__(self, devs: list[str], pid: int, period: float = 0.25) -> None:
        self.devs, self.pid, self.period = devs, pid, period
        self.samples: list[tuple[float, dict[str, list[int]]]] = []
        self.anon_peak = -1
        self.stop_ = threading.Event()
        self.t = threading.Thread(target=self.loop, daemon=True)

    def loop(self) -> None:
        while True:
            self.samples.append((time.perf_counter(), diskstats(self.devs)))
            self.anon_peak = max(self.anon_peak, rss_anon(self.pid))
            if self.stop_.wait(self.period):
                self.samples.append((time.perf_counter(), diskstats(self.devs)))
                return

    def start(self) -> "DiskSampler":
        self.t.start()
        return self

    def stop(self) -> None:
        self.stop_.set()
        self.t.join()

    def window(self, t0: float, t1: float, devs: list[str]) -> dict:
        """Delta stats between the samples closest to t0 and t1, summed over `devs`."""
        if len(self.samples) < 2:
            return {}
        a = min(self.samples, key=lambda s: abs(s[0] - t0))
        b = min(self.samples, key=lambda s: abs(s[0] - t1))
        dt = b[0] - a[0]
        if dt <= 0:
            return {}
        d = [sum(b[1][x][i] - a[1][x][i] for x in devs if x in a[1] and x in b[1]) for i in range(11)]
        reads, sectors, ms_read, tiq = d[0], d[2], d[3], d[10]
        return {"window_s": round(dt, 3), "read_bytes": sectors * 512, "reads": reads,
                "avg_read_kib": round(sectors * 512 / reads / 1024, 2) if reads else 0.0,
                "read_mb_s": round(sectors * 512 / dt / 1e6, 1),
                "read_iops": round(reads / dt),
                "aqu_sz": round(tiq / (dt * 1000.0), 3),
                "r_await_ms": round(ms_read / reads, 4) if reads else 0.0}

    def peak_bw(self, t0: float, t1: float, devs: list[str], span: float = 1.0) -> float:
        best = 0.0
        s = [x for x in self.samples if t0 - self.period <= x[0] <= t1 + self.period]
        j = 0
        for i in range(len(s)):
            while j < len(s) and s[j][0] - s[i][0] < span:
                j += 1
            if j >= len(s):
                break
            dt = s[j][0] - s[i][0]
            sec = sum(s[j][1][x][2] - s[i][1][x][2] for x in devs if x in s[i][1] and x in s[j][1])
            best = max(best, sec * 512 / dt / 1e6)
        return round(best, 1)


def proc_io(pid: int) -> dict[str, int]:
    try:
        return {k: int(v) for k, v in (l.split(": ") for l in Path(f"/proc/{pid}/io").read_text().splitlines())}
    except OSError:
        return {}


def read_counts(p: Path) -> dict[str, int]:
    vals = struct.unpack_from("<7Q", p.read_bytes())
    if vals[0] != MAGIC:
        return {f: -1 for f in FIELDS}
    return dict(zip(FIELDS, vals[1:]))


def cgroup_dir(pid: int) -> Path | None:
    try:
        for line in Path(f"/proc/{pid}/cgroup").read_text().splitlines():
            if line.startswith("0::"):
                return Path("/sys/fs/cgroup") / line[3:].lstrip("/")
    except OSError:
        pass
    return None


def cg_read(cg: Path | None) -> dict:
    if cg is None:
        return {}
    out: dict = {"cgroup": str(cg)}
    for f in ("memory.max", "memory.peak", "memory.current"):
        try:
            out[f] = (cg / f).read_text().strip()
        except OSError:
            pass
    for f in ("memory.events", "memory.stat"):
        try:
            kv = dict(l.split() for l in (cg / f).read_text().splitlines())
            keep = ("oom", "oom_kill", "max", "high") if f == "memory.events" else (
                "anon", "file", "workingset_refault_file", "workingset_refault_anon", "pgmajfault", "pgfault",
                "pgscan", "pgsteal", "file_mapped")
            out.update({f"{f}.{k}": int(kv[k]) for k in keep if k in kv})
        except (OSError, ValueError):
            pass
    return out


def run_query(port: int, query: str, action: str, accept: str, timeout_s: float) -> dict:
    h = xxhash.xxh3_128()
    n = lines = 0
    ttfb = None
    t0 = time.perf_counter()
    with httpx.stream("POST", f"http://127.0.0.1:{port}/", data={"query": query, "action": action},
                      headers={"Accept": accept},
                      timeout=httpx.Timeout(connect=10.0, read=timeout_s, write=10.0, pool=10.0)) as r:
        for chunk in r.iter_bytes():
            if ttfb is None and chunk:
                ttfb = time.perf_counter()
            n += len(chunk)
            lines += chunk.count(b"\n")
            h.update(chunk)
        status = r.status_code
    t1 = time.perf_counter()
    return {"t0": t0, "t_first": ttfb or t1, "t1": t1, "bytes": n, "lines": lines, "xxh3_128": h.hexdigest(),
            "status": status}


class Server:
    def __init__(self, args, d: Path, rps: list[str], mem_max: str | None, so: Path | None) -> None:
        self.d = d
        self.count_file = d / "io-counts.bin"
        self.count_file.write_bytes(b"\0" * 4096)
        env = os.environ.copy()
        if so is not None:
            env["QLEVER_IO_COUNT_FILE"] = str(self.count_file)
            env["LD_PRELOAD"] = f"{so}:{env['LD_PRELOAD']}" if env.get("LD_PRELOAD") else str(so)
        prefix = []
        if args.scope:
            prefix = ["systemd-run", "--user", "--scope", "--quiet", "--collect",
                      "-p", f"MemoryMax={mem_max or 'infinity'}", "-p", "MemorySwapMax=0"]
        cmd = [*prefix, args.binary, "--index-basename", args.index_basename, "--port", str(args.port),
               "--no-access-check", "--cache-max-size", "0B", "--cache-max-size-single-entry", "0B",
               "--cache-max-size-lazy-result", "0B", "--cache-max-num-entries", "0",
               "--default-query-timeout", "1800s", "--num-simultaneous-queries", "1"]
        for rp in rps:
            cmd += ["--set-runtime-parameter", rp]
        (d / "server-cmd.txt").write_text(" ".join(cmd) + "\n")
        self.logf = (d / "qlever-server.log").open("wb")
        self.proc = subprocess.Popen(cmd, cwd=Path(args.index_basename).parent, stdout=self.logf,
                                     stderr=subprocess.STDOUT, env=env, start_new_session=True)
        t0 = time.time()
        while READY not in (d / "qlever-server.log").read_text(errors="replace"):
            if self.proc.poll() is not None or time.time() - t0 > args.ready_timeout:
                raise RuntimeError(f"server not ready (rc={self.proc.poll()})")
            time.sleep(0.25)
        self.ready_s = time.time() - t0
        self.pid = self.proc.pid
        fu = subprocess.run(["fuser", f"{args.port}/tcp"], capture_output=True, text=True)
        if fu.stdout.split():
            self.pid = int(fu.stdout.split()[0])
        self.exe = os.readlink(f"/proc/{self.pid}/exe")

    def stop(self) -> None:
        try:
            os.killpg(self.proc.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            self.proc.wait(timeout=30)
        except subprocess.TimeoutExpired:
            os.killpg(self.proc.pid, signal.SIGKILL)
            self.proc.wait(timeout=30)
        self.logf.close()


def one_exec(args, cfg: dict, cap_bytes: int | None, trial: int, out: Path, so: Path | None, log) -> dict:
    qpath = Path(cfg["query"])
    d = out / cfg["label"] / f"t{trial}"
    d.mkdir(parents=True, exist_ok=True)
    r = subprocess.run(args.evict_cmd, shell=True, capture_output=True, text=True)
    row = {"label": cfg["label"], "query": qpath.stem, "trial": trial, "evict_rc": r.returncode,
           "cap_headroom_gib": cfg.get("cap_headroom_gib"), "mem_max_bytes": cap_bytes,
           "rps": cfg.get("rps", [])}
    srv = None
    try:
        srv = Server(args, d, cfg.get("rps", []), str(cap_bytes) if cap_bytes else None, so)
        pid = srv.pid
        cg = cgroup_dir(pid)
        row.update({"server_pid": pid, "server_exe": srv.exe, "ready_s": round(srv.ready_s, 2),
                    "anon_at_ready": rss_anon(pid)})
        query = qpath.read_text()
        s0, io0, c0 = schedstat(pid), proc_io(pid), read_counts(srv.count_file)
        cg0 = cg_read(cg)
        ds = DiskSampler(args.devices, pid).start()
        sampler = Sampler(pid, args.sample_ms / 1000.0).start()
        q = run_query(args.port, query, args.action, args.accept, args.query_timeout)
        sampler.stop()
        ds.stop()
        s1 = dict(sampler.last)
        s1.update(schedstat(pid))
        io1, c1, cg1 = proc_io(pid), read_counts(srv.count_file), cg_read(cg)
        elapsed = q["t1"] - q["t0"]
        ttfb = q["t_first"] - q["t0"]
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
        by = {k: off * v / nsleep for k, v in sleeping.items()} if nsleep else {}
        uring_s = sum(v for k, v in by.items() if k.endswith(":io_uring_enter"))
        # Any thread's io_uring_enter share (samples / samples of that thread), top thread reported.
        uring_threads = []
        for t in threads[:12]:
            ct = sampler.counts.get(t["tid"], collections.Counter())
            tot = sum(ct.values())
            u = sum(v for k, v in ct.items() if k.endswith(":io_uring_enter"))
            if tot and u:
                uring_threads.append({"tid": t["tid"], "comm": t["comm"], "uring_sample_share": round(u / tot, 4),
                                      "run_s": round(t["run_s"], 3)})
        uring_threads.sort(key=lambda x: -x["uring_sample_share"])
        dc = {k: c1[k] - c0[k] for k in FIELDS} if c0["pread"] >= 0 and c1["pread"] >= 0 else {}
        nowait, eagain = dc.get("preadv2_nowait", 0), dc.get("preadv2_eagain", 0)
        nv = [x for x in args.devices if x.startswith("nvme")] or args.devices
        whole = ds.window(q["t0"], q["t1"], nv)
        export = ds.window(q["t_first"], q["t1"], nv)
        row.update({
            "status": q["status"], "bytes": q["bytes"], "lines": q["lines"], "xxh3_128": q["xxh3_128"],
            "elapsed_s": round(elapsed, 3), "ttfb_s": round(ttfb, 3), "export_phase_s": round(elapsed - ttfb, 3),
            "server_cpu_s": round(sum(t["run_s"] for t in threads), 3),
            "export_tid": ex["tid"], "export_comm": ex["comm"], "export_run_s": round(ex["run_s"], 3),
            "export_runq_s": round(ex["runq_s"], 3), "export_offcpu_s": round(off, 3),
            "export_uring_wait_s": round(uring_s, 3),
            "export_uring_share_wall": round(uring_s / elapsed, 4) if elapsed else None,
            "export_uring_share_export_phase": round(uring_s / (elapsed - ttfb), 4) if elapsed > ttfb else None,
            "export_offcpu_by_syscall_s": {k: round(v, 3) for k, v in sorted(by.items(), key=lambda kv: -kv[1])},
            "export_state_samples": dict(c.most_common()),
            "uring_threads": uring_threads[:4],
            "counts": dc,
            "fastpath_hit_share": round(1 - eagain / nowait, 4) if nowait else None,
            "proc_io": {k: io1.get(k, 0) - io0.get(k, 0) for k in ("rchar", "syscr", "read_bytes")},
            "disk_whole": whole, "disk_export": export,
            "disk_peak_1s_mb_s": ds.peak_bw(q["t0"], q["t1"], nv),
            "md_whole": ds.window(q["t0"], q["t1"], [x for x in args.devices if x.startswith("md")]),
            "anon_peak": ds.anon_peak, "cg_before": cg0, "cg_after": cg1,
            "sampler_iterations": sampler.iterations, "top_threads": threads[:6]})
        (d / "disk-samples.json").write_text(json.dumps([(round(t - q["t0"], 3), s) for t, s in ds.samples]))
    except Exception as e:  # noqa: BLE001
        row["error"] = repr(e)
        log(f"{cfg['label']} t{trial}: {e!r}")
    finally:
        if srv is not None:
            srv.stop()
    (d / "row.json").write_text(json.dumps(row, indent=1))
    return row


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--index-basename", required=True)
    ap.add_argument("--binary", required=True)
    ap.add_argument("--plan", required=True)
    ap.add_argument("--trials", type=int, default=3)
    ap.add_argument("--evict-cmd", required=True)
    ap.add_argument("--sample-ms", type=float, default=1.0)
    ap.add_argument("--devices", default="md1,nvme0n1,nvme1n1")
    ap.add_argument("--preload-so", default="")
    ap.add_argument("--calibrate-query", default="", help="uncapped run whose peak RssAnon sets the cap base")
    ap.add_argument("--no-scope", dest="scope", action="store_false")
    ap.add_argument("--action", default="turtle_export")
    ap.add_argument("--accept", default="text/turtle")
    ap.add_argument("--port", type=int, default=7015)
    ap.add_argument("--ready-timeout", type=float, default=600.0)
    ap.add_argument("--query-timeout", type=float, default=900.0)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    args.devices = args.devices.split(",")
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    so = Path(args.preload_so) if args.preload_so else None

    def log(msg: str) -> None:
        line = f"[{time.strftime('%FT%TZ', time.gmtime())}] {msg}"
        print(line, flush=True)
        with (out / "io-screen.log").open("a") as fh:
            fh.write(line + "\n")

    ver = subprocess.run([args.binary, "--version"], capture_output=True, text=True).stdout.splitlines()[:1]
    log(f"binary {args.binary} {ver}")
    plan = json.loads(Path(args.plan).read_text())
    base_anon = None
    if any(c.get("cap_headroom_gib") for c in plan):
        cal = {"label": "calibration", "query": args.calibrate_query or plan[0]["query"], "rps": []}
        row = one_exec(args, cal, None, 0, out, so, log)
        if "error" in row or row.get("anon_peak", -1) <= 0:
            log(f"calibration failed: {row.get('error')}; capped configurations are skipped")
            plan = [c for c in plan if not c.get("cap_headroom_gib")]
        else:
            base_anon = row["anon_peak"]
            log(f"calibration: peak RssAnon {base_anon / GIB:.2f} GiB, anon at ready {row['anon_at_ready'] / GIB:.2f} GiB")
        (out / "calibration.json").write_text(json.dumps(row, indent=1))
    rows = []
    for trial in range(1, args.trials + 1):
        order = plan if trial % 2 else list(reversed(plan))
        for cfg in order:
            cap = None
            if cfg.get("cap_headroom_gib") and base_anon:
                cap = int(math.ceil(base_anon / (GIB / 4)) * (GIB / 4) + cfg["cap_headroom_gib"] * GIB)
            row = one_exec(args, cfg, cap, trial, out, so, log)
            log(json.dumps({k: row.get(k) for k in ("label", "trial", "status", "elapsed_s", "ttfb_s", "bytes",
                                                    "server_cpu_s", "export_run_s", "export_uring_wait_s",
                                                    "export_uring_share_wall", "fastpath_hit_share", "error")}))
            rows.append(row)
            (out / "rows.json").write_text(json.dumps(rows, indent=1))
    (out / "COMPLETE").write_text("done\n")
    log("done")
    return 0 if all("error" not in r and r.get("status") == 200 for r in rows) else 1


if __name__ == "__main__":
    sys.exit(main())
