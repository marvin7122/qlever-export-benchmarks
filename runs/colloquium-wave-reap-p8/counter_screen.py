#!/usr/bin/env python3
"""Counter screening for export stack parts (author-approved, 2026-09-28).

Screening rows measure mechanism counters instead of timing: one server start
per arm, one untimed warm-up execution, then ONE counted warm execution (and,
with --cold, one counted cold execution on a fresh server after evicting the
index files). Per execution it records, for the server process:
  - libc/liburing entry counts via LD_PRELOAD (io_counts_preload.c):
    pread/pread64, preadv2 (+ RWF_NOWAIT calls, + EAGAIN misses),
    io_uring_enter(2), io_uring_submit*
  - /proc/<pid>/io deltas: read_bytes, rchar, syscr
  - /proc/<pid>/stat deltas: minflt, majflt, utime+stime (CPU s)
  - instructions:u via `perf stat -p` when perf is usable (paranoid <= 2)
  - optional kernel-level syscall counts via `strace -c -f -p` (--strace;
    slows the run, counts only)
  - response bytes + xxh3_128 of the body (byte-identity across arms)
Timing (3 x >= 10 s) is only for a part's final/verdict row; these rows are
screening. Output: <out>/counters.tsv, <out>/counters.md, per-arm logs.

Arms: --arm LABEL=/path/to/qlever-server[,runtime-param=value,...]
Cold eviction: --evict-cmd (default: posix_fadvise DONTNEED on every
<index-basename>.* file = "our-files-only cold"); on Ural pass
--evict-cmd /local/data-ssd/stoetzem/clear-caches for a full drop.
"""

from __future__ import annotations

import argparse
import os
import shutil
import signal
import struct
import subprocess
import sys
import time
from pathlib import Path

import httpx
import xxhash

HERE = Path(__file__).resolve().parent
MAGIC = 0x514C4556494F4332
FIELDS = ["pread", "preadv2", "preadv2_nowait", "preadv2_eagain", "io_uring_enter", "liburing_submit"]
READY = "The server is ready, listening for requests on port "


def build_preload(out: Path) -> Path | None:
    so = out / "libio_counts.so"
    cc = shutil.which("cc") or shutil.which("gcc")
    if cc is None:
        return None
    r = subprocess.run([cc, "-shared", "-fPIC", "-O2", "-o", str(so), str(HERE / "io_counts_preload.c"), "-ldl"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        (out / "preload-build.log").write_text(r.stdout + r.stderr)
        return None
    return so


def read_counts(p: Path) -> dict[str, int]:
    data = p.read_bytes()
    vals = struct.unpack_from("<7Q", data)
    if vals[0] != MAGIC:
        return {f: -1 for f in FIELDS}
    return dict(zip(FIELDS, vals[1:]))


def proc_snapshot(pid: int) -> dict[str, int]:
    snap: dict[str, int] = {}
    try:
        for line in Path(f"/proc/{pid}/io").read_text().splitlines():
            k, v = line.split(":")
            snap[k.strip()] = int(v)
    except OSError:
        pass
    try:
        # Fields after the ")" of comm: state is index 0 -> minflt 7, majflt 9, utime 11, stime 12.
        st = Path(f"/proc/{pid}/stat").read_text()
        f = st[st.rindex(")") + 2:].split()
        snap["minflt"], snap["majflt"] = int(f[7]), int(f[9])
        snap["cpu_ticks"] = int(f[11]) + int(f[12])
    except (OSError, ValueError, IndexError):
        pass
    return snap


def perf_usable() -> bool:
    if shutil.which("perf") is None:
        return False
    try:
        return int(Path("/proc/sys/kernel/perf_event_paranoid").read_text()) <= 2
    except (OSError, ValueError):
        return False


def evict(args: argparse.Namespace, log) -> str:
    if args.evict_cmd:
        r = subprocess.run(args.evict_cmd, shell=True, capture_output=True, text=True)
        return f"evict-cmd rc={r.returncode}: {(r.stdout + r.stderr).strip()[-300:]}"
    files = sorted(Path(args.index_basename).parent.glob(Path(args.index_basename).name + ".*"))
    for f in files:
        try:
            fd = os.open(f, os.O_RDONLY)
            os.posix_fadvise(fd, 0, 0, os.POSIX_FADV_DONTNEED)
            os.close(fd)
        except OSError as e:
            log(f"evict {f}: {e}")
    res = ""
    if shutil.which("fincore"):
        r = subprocess.run(["fincore", "-b", "-n", "-o", "RES", *map(str, files)], capture_output=True, text=True)
        res = f" resident_after={sum(int(x) for x in r.stdout.split() if x.isdigit())}B"
    return f"our-files-only cold: fadvise DONTNEED on {len(files)} files{res}"


def run_query(port: int, query: str, action: str, accept: str) -> tuple[int, str, float, int]:
    h = xxhash.xxh3_128()
    n = 0
    t0 = time.perf_counter()
    with httpx.stream("POST", f"http://127.0.0.1:{port}/", data={"query": query, "action": action},
                      headers={"Accept": accept}, timeout=httpx.Timeout(connect=10.0, read=None, write=10.0, pool=10.0)) as r:
        for chunk in r.iter_bytes():
            n += len(chunk)
            h.update(chunk)
        status = r.status_code
    return n, h.hexdigest(), time.perf_counter() - t0, status


def one_server(args, label: str, binary: str, rps: list[str], scen: str, out: Path, so: Path | None, log) -> dict:
    d = out / label / scen
    d.mkdir(parents=True, exist_ok=True)
    note = evict(args, log) if scen == "cold" else ""
    count_file = d / "io-counts.bin"
    count_file.write_bytes(b"\0" * 4096)
    env = os.environ.copy()
    if so is not None:
        env["QLEVER_IO_COUNT_FILE"] = str(count_file)
        env["LD_PRELOAD"] = f"{so}:{env['LD_PRELOAD']}" if env.get("LD_PRELOAD") else str(so)
    tracing = scen == "cold" and args.trace_io and shutil.which("strace") is not None
    # D8: the traced cold run starts the server UNDER strace (ptrace_scope=1 forbids attaching).
    tracer = (["strace", "-f", "-ttt", "-T", "-qq", "-s0", "-e", "abbrev=none",
               "-e", "trace=openat,io_uring_enter", "-o", str(d / "io-trace.txt")] if tracing else [])
    cmd = [*args.server_prefix, *tracer, binary, "--index-basename", args.index_basename, "--port", str(args.port),
           "--no-access-check", "--cache-max-size", "0B", "--cache-max-size-single-entry", "0B",
           "--cache-max-size-lazy-result", "0B", "--cache-max-num-entries", "0",
           "--default-query-timeout", "1800s", "--num-simultaneous-queries", "1"]
    for rp in rps:
        cmd += ["--set-runtime-parameter", rp]
    logf = (d / "qlever-server.log").open("wb")
    proc = subprocess.Popen(cmd, cwd=Path(args.index_basename).parent, stdout=logf, stderr=subprocess.STDOUT,
                            env=env, start_new_session=True)
    row = {"arm": label, "scenario": scen, "binary": binary, "runtime_params": " ".join(rps) or "-", "note": note}
    try:
        t0 = time.time()
        while READY not in (d / "qlever-server.log").read_text(errors="replace"):
            if proc.poll() is not None or time.time() - t0 > args.ready_timeout:
                raise RuntimeError(f"server not ready (rc={proc.poll()})")
            time.sleep(0.25)
        # With a wrapper/loader prefix the server may be a child; take the process holding the port.
        pid = proc.pid
        fu = subprocess.run(["fuser", f"{args.port}/tcp"], capture_output=True, text=True)
        if fu.stdout.split():
            pid = int(fu.stdout.split()[0])
        query = Path(args.query).read_text()
        if scen == "warm":
            run_query(args.port, query, args.action, args.accept)  # untimed warm-up
        c0, p0 = read_counts(count_file), proc_snapshot(pid)
        perf = None
        if args.perf and perf_usable():
            perf = subprocess.Popen(["perf", "stat", "-x,", "-e", "instructions:u", "-p", str(pid), "-o", str(d / "perf.txt")],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        prec = None
        if args.perf_record and scen == "cold":
            prec = subprocess.Popen(["perf", "record", "-F", "999", "-g", "-p", str(pid), "-o", str(d / "perf.data")],
                                    stdout=subprocess.DEVNULL, stderr=open(d / "perf-record.log", "w"))
            time.sleep(1.0)
        st = None
        if args.strace and shutil.which("strace"):
            st = subprocess.Popen(["strace", "-c", "-f", "-p", str(pid), "-o", str(d / "strace-c.txt")],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(1.0)
        tq0 = time.time()
        nbytes, digest, elapsed, status = run_query(args.port, query, args.action, args.accept)
        tq1 = time.time()
        for tool in (perf, st, prec):
            if tool is not None:
                tool.send_signal(signal.SIGINT)
                tool.wait(timeout=30)
        c1, p1 = read_counts(count_file), proc_snapshot(pid)
        row.update({k: c1[k] - c0[k] if c0[k] >= 0 else -1 for k in FIELDS})
        for k in ("read_bytes", "rchar", "syscr", "minflt", "majflt"):
            row[k] = p1.get(k, 0) - p0.get(k, 0)
        row["cpu_s"] = round((p1.get("cpu_ticks", 0) - p0.get("cpu_ticks", 0)) / os.sysconf("SC_CLK_TCK"), 2)
        row["instructions_u"] = "-"
        if perf is not None and (d / "perf.txt").exists():
            for line in (d / "perf.txt").read_text().splitlines():
                if "instructions" in line and line.split(",")[0].strip().isdigit():
                    row["instructions_u"] = int(line.split(",")[0])
        row["strace_syscalls"] = "-"
        if st is not None and (d / "strace-c.txt").exists():
            wanted = ("io_uring_enter", "pread64", "preadv2", "read", "mmap", "madvise")
            parts = []
            for line in (d / "strace-c.txt").read_text().splitlines():
                cols = line.split()
                if cols and cols[-1] in wanted and len(cols) >= 4:
                    parts.append(f"{cols[-1]}={cols[3]}")
            row["strace_syscalls"] = " ".join(parts) or "-"
        row.update({"bytes": nbytes, "xxh3_128": digest, "status": status, "elapsed_s_screening": round(elapsed, 3)})
        row["io_pattern"] = "-"
        if tracing:
            row["elapsed_s_screening"] = f"{row['elapsed_s_screening']} (strace'd)"
            r = subprocess.run([sys.executable, str(HERE / "io_pattern.py"), str(d / "io-trace.txt"), "--from", str(tq0),
                                "--to", str(tq1), "--index-prefix", str(Path(args.index_basename).parent),
                                "--out", str(d / "io-pattern.json")], capture_output=True, text=True)
            row["io_pattern"] = (r.stdout.strip() or r.stderr.strip()[-200:]).replace("\t", " ")
    except Exception as e:  # noqa: BLE001
        row["error"] = repr(e)
        log(f"{label}/{scen}: {e!r}")
    finally:
        os.killpg(proc.pid, signal.SIGTERM)
        try:
            proc.wait(timeout=30)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
        subprocess.run(["fuser", "-k", f"{args.port}/tcp"], capture_output=True)
        logf.close()
    return row


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--index-basename", required=True)
    ap.add_argument("--query", required=True, help=".rq file")
    ap.add_argument("--action", default="turtle_export")
    ap.add_argument("--accept", default=None)
    ap.add_argument("--arm", action="append", required=True, help="LABEL=/bin/qlever-server[,rp=v,...]")
    ap.add_argument("--cold", action="store_true", help="also one cold execution per arm (I/O mechanisms)")
    ap.add_argument("--no-warm", action="store_true")
    ap.add_argument("--evict-cmd", default="", help="shell command run before each cold server start")
    ap.add_argument("--server-prefix-arg", action="append", default=[], dest="server_prefix", help="token before the binary, repeatable, use --server-prefix-arg=TOKEN")
    ap.add_argument("--port", type=int, default=7015)
    ap.add_argument("--ready-timeout", type=float, default=300.0)
    ap.add_argument("--perf", action="store_true", default=True)
    ap.add_argument("--strace", action="store_true", help="strace -c -p on the running server (needs ptrace_scope 0)")
    ap.add_argument("--trace-io", action="store_true",
                    help="D8: run the COLD execution under strace and derive the I/O pattern (io_pattern.py); counts only, never timing")
    ap.add_argument("--perf-record", action="store_true", help="perf record -g the cold execution (cycles, kernel+user)")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    args.accept = args.accept or {"turtle_export": "text/turtle", "csv_export": "text/csv",
                                  "tsv_export": "text/tab-separated-values"}.get(args.action, "*/*")
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    logp = out / "counter-screen.log"

    def log(msg: str) -> None:
        line = f"[{time.strftime('%FT%TZ', time.gmtime())}] {msg}"
        print(line, flush=True)
        with logp.open("a") as fh:
            fh.write(line + "\n")

    if subprocess.run(["fuser", f"{args.port}/tcp"], capture_output=True).stdout.strip():
        log(f"port {args.port} busy; refusing")
        return 2
    so = build_preload(out)
    log(f"preload: {so or 'UNAVAILABLE (entry counts = -1)'}; perf instructions: {args.perf and perf_usable()}")
    scens = ([] if args.no_warm else ["warm"]) + (["cold"] if args.cold else [])
    rows = []
    for scen in scens:
        for spec in args.arm:
            label, rest = spec.split("=", 1)
            binary, *rps = rest.split(",")
            ver = subprocess.run([binary, "--version"], capture_output=True, text=True).stdout.splitlines()[:1]
            log(f"{scen} {label}: {binary} {ver} rps={rps}")
            rows.append(one_server(args, label, binary, rps, scen, out, so, log))
    cols = ["arm", "scenario", "runtime_params", *FIELDS, "read_bytes", "syscr", "majflt", "minflt", "cpu_s",
            "instructions_u", "strace_syscalls", "io_pattern", "bytes", "xxh3_128", "elapsed_s_screening", "note", "error"]
    with (out / "counters.tsv").open("w") as fh:
        fh.write("\t".join(cols) + "\n")
        for r in rows:
            fh.write("\t".join(str(r.get(c, "")) for c in cols) + "\n")
    digests = {r.get("xxh3_128") for r in rows if r.get("xxh3_128")}
    md = ["| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |",
          "|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for r in rows:
        md.append(f"| {r['arm']} | {r['scenario']} | {r['runtime_params']} | {r.get('pread','')} | "
                  f"{r.get('preadv2','')} ({r.get('preadv2_nowait','')}/{r.get('preadv2_eagain','')}) | "
                  f"{r.get('io_uring_enter','')} | {r.get('liburing_submit','')} | {r.get('read_bytes','')} | "
                  f"{r.get('majflt','')} | {r.get('cpu_s','')} | {r.get('instructions_u','')} | {r.get('bytes','')} |")
    for r in rows:
        if r.get("io_pattern", "-") != "-":
            md.append(f"\nI/O pattern {r['arm']} ({r['scenario']}, traced): {r['io_pattern']}")
    md.append("")
    md.append(f"Byte-identical output across arms: {'yes' if len(digests) == 1 else 'NO (' + str(len(digests)) + ' digests)'}. "
              "Screening counters (one execution per arm and scenario); timing only in the verdict row.")
    (out / "counters.md").write_text("\n".join(md) + "\n")
    log("done")
    print("\n".join(md))
    return 0 if all("error" not in r for r in rows) else 1


if __name__ == "__main__":
    sys.exit(main())
