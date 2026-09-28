#!/usr/bin/env python3
# Aggregate pr73 micro A/B: results.csv + perf/*.stat (differenced x2-x1 = exactly
# one block of timed passes) + perf/*.top.txt (self-time shares by symbol).
import csv, sys, statistics as st, collections, re, os
out = sys.argv[1]
rows = list(csv.DictReader(open(out + "/results.csv")))
g = collections.OrderedDict()
for r in rows: g.setdefault((r["bench"], r["config"], r["arm"]), []).append(r)
def share(f, pat):
    if not os.path.exists(f): return float("nan")
    t = 0.0
    for l in open(f):
        m = re.match(r"\s+([0-9.]+)%\s+(.*)", l)
        if m and re.search(pat, m.group(2)): t += float(m.group(1))
    return t
def stat(f):
    d = {}
    if not os.path.exists(f): return d
    for l in open(f):
        p = l.strip().split(",")
        if len(p) > 3:
            try: d[p[2]] = float(p[0])
            except ValueError: pass
    return d
def f(x, n=2):
    return "–" if x is None or (isinstance(x, float) and x != x) else f"{x:.{n}f}"
lines = ["| bench | config | arm | trials | ns/item median | min | max | Δ median vs first arm | alloc requests/item | alloc bytes/item | peak live heap B | per-word buffer B | provisioned buffer B | memset % | allocator % | fsst_decompress % | instructions/item | L1d misses/item |", "|" + "---|" * 18]
first = {}
for (b, c, a), rs in g.items():
    ns = [float(r["ns_per_item"]) for r in rs]; it = float(rs[0]["items"])
    med = st.median(ns)
    first.setdefault((b, c), med)
    def m(k):
        v = [float(r[k]) for r in rs if r[k] not in ("", None)]
        return st.median(v) if v else None
    ar = m("alloc_requests"); ab = m("alloc_bytes"); pk = m("peak_live_bytes")
    key = f"{out}/perf/{b}-{c}-{a}"
    top = key + ".top.txt"
    ms = share(top, r"memset|__memset")
    al = share(top, r"jemalloc|\bje_|malloc|\bfree\b|sdallocx|_Znwm|_ZdlPv|operator new|operator delete|_M_create|_M_dispose")
    fd = share(top, r"fsst_decompress")
    s1 = stat(key + ".x1.stat"); s2 = stat(key + ".x2.stat")
    per = None
    if os.path.exists(key + ".reps"):
        p, w = map(int, open(key + ".reps").read().split()); per = p * w
    ins = (s2.get("instructions", 0) - s1.get("instructions", 0)) / per if per and "instructions" in s1 else None
    l1 = (s2.get("L1-dcache-load-misses", 0) - s1.get("L1-dcache-load-misses", 0)) / per if per and "L1-dcache-load-misses" in s1 else None
    lines.append(f"| {b} | {c} | {a} | {len(ns)} | {f(med)} | {f(min(ns))} | {f(max(ns))} | {100*(med-first[(b,c)])/first[(b,c)]:+.1f} % | {f(ar/it if ar is not None else None,3)} | {f(ab/it if ab is not None else None,1)} | {f(pk,0)} | {rs[0]['max_per_word_buffer_bytes'] or '–'} | {rs[0]['provisioned_buffer_bytes'] or '–'} | {f(ms,1)} | {f(al,1)} | {f(fd,1)} | {f(ins,1)} | {f(l1,3)} |")
open(out + "/aggregate.md", "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
