#!/usr/bin/env python3
"""Categorise `perf report --no-children --sort sym` (self time = leaf frame)
with the categories of categorise-leaf.py. Usage: categorise-self-report.py <label=report>..."""
import re, sys, importlib.util
spec = importlib.util.spec_from_file_location("cl", __file__.replace("categorise-self-report.py", "categorise-leaf.py"))
cl = importlib.util.module_from_spec(spec); spec.loader.exec_module(cl)
res = {}
for arg in sys.argv[1:]:
    label, path = arg.split("=", 1)
    cats, syms, tot = {}, [], 0.0
    for line in open(path):
        m = re.match(r"\s*([\d.]+)%\s+\[(.)\]\s+(.*)", line)
        if not m: continue
        p, kind, sym = float(m.group(1)), m.group(2), m.group(3).strip()
        c = cl.classify(sym) if kind == "." else "kernel / syscalls / I/O"
        if kind == "." and sym.startswith("0x"): c = cl.OTHER
        cats[c] = cats.get(c, 0) + p; tot += p; syms.append((p, c, sym))
    cats["(below 0.1 % each, not listed)"] = 100 - tot
    res[label] = (cats, syms)
names = list(res)
order = [c for c, _ in cl.RULES] + [cl.OTHER, "(below 0.1 % each, not listed)"]
print("| category (by leaf function) | " + " | ".join(names) + " |")
print("|---|" + "---|" * len(names))
for c in order:
    print(f"| {c} | " + " | ".join(f"{res[n][0].get(c, 0):.1f} %" for n in names) + " |")
for n in names:
    print(f"\n### top self symbols: {n}")
    for p, c, s in res[n][1][:22]:
        print(f"- {p:.2f} % [{c}] {re.sub(r'\(.*', '', s)[:120]}")
