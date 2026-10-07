#!/usr/bin/env python3
"""Categorise folded perf stacks (stackcollapse-perf output) by LEAF frame,
with the categories of the colloquium slide "Idea 3: where the CPU time goes
now" (run pr120-wikidata-j8-ab-identity).

Usage: categorise-leaf.py <stacks.folded>... [--top 25] [--callers SYMREGEX]

Prints, per file, the share of all samples per category and the top leaf
symbols. With --callers, prints the most frequent caller chains (5 frames
above the leaf) of leaves matching SYMREGEX.
"""
import argparse
import collections
import re

# First match on the leaf frame wins.
RULES = [
    ("in-RAM membership: binary search / rank lookup",
     r"positionOfIndex|rankIfContained|BitVectorWithRank|partitionIndicesBySource|prefetchPositionOfIndex|VocabularyInternalExternal::lookupBatch|__popcount"),
    ("FSST decoding", r"fsst|Fsst|DecoderMultiplexer"),
    ("building lookup results", r"makePmrVocabBatchLookupResult|MultiSourceVocabBatchAssembler|ArenaVocabBatch|VocabBatchLookupResult|ContiguousVocabBatch|scatterSubBatch|finalizeVocabBatch|MarkerIndicesAndPositions"),
    ("reading the in-RAM entry", r"wordAtPosition|CompactVectorOfStrings|prefetchWordAtPosition|prefetchOffsets"),
    ("runtime checks", r"adCorrectnessCheckImpl|adContractCheck|AD_CORRECTNESS"),
    ("query evaluation (scan, join, libzstd, compareThreeWay)",
     r"ZSTD|zstd|HUF_|FSE_|compareThreeWay|CompressedRelation|IndexScan|Join|join|CompressedBlock|readAndDecompress|decompressColumn|LocatedTriples|Filter|SparqlExpression|evaluate|IdTable|Permutation|getLangFromLiteral|LanguageExpression|ScanSpec|__introsort|__insertion_sort|std::sort"),
    ("memory allocation and copies",
     r"^(je_|malloc|free|calloc|realloc|operator new|operator delete|_int_malloc|_int_free|cfree|tcache|arena_|sdallocx|mallocx)|jemalloc|memcpy|memmove|memset|__memcpy|__memmove|__memset|basic_string|_M_construct|_M_append|_M_replace|_M_create|_M_mutate|monotonic_buffer|memory_resource|pmr::|_Sp_counted|clear_page|rep_movs|copy_user|copy_page"),
    ("formatting and escaping",
     r"Escape|escape|Csv|csv|serialize|Serialize|Format|format|SimdEscape|ColumnLattice|writeRow|appendCell|literalOrIriToStringAndType|idsToStringAndType|ExportEngineV2|StringBatcher|stream_generator"),
    ("kernel / syscalls / I/O", r"^(entry_SYSCALL|do_syscall|__x64_sys|io_uring|__io_|nvme|blk_|sock_|tcp_|futex|schedule|__schedule|asm_exc|exc_page|handle_mm|filemap|native_|_raw_spin)|\[unknown\]|\[kernel"),
]
RULES = [(c, re.compile(r)) for c, r in RULES]
OTHER = "rest"


def short(sym):
    s = re.sub(r"\(.*", "", sym)
    return s[-110:]


def classify(leaf):
    for cat, rx in RULES:
        if rx.search(leaf):
            return cat
    return OTHER


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--top", type=int, default=25)
    ap.add_argument("--callers", default=None)
    ap.add_argument("--md", action="store_true")
    a = ap.parse_args()
    results = {}
    for f in a.files:
        cats = collections.Counter()
        leaves = collections.Counter()
        callers = collections.Counter()
        total = 0
        for line in open(f, errors="replace"):
            line = line.rstrip("\n")
            if not line:
                continue
            stack, _, n = line.rpartition(" ")
            n = int(n)
            frames = stack.split(";")
            leaf = frames[-1]
            total += n
            cats[classify(leaf)] += n
            leaves[leaf] += n
            if a.callers and re.search(a.callers, leaf):
                callers[" <- ".join(short(x) for x in reversed(frames[-6:]))] += n
        results[f] = (total, cats, leaves, callers)
        print(f"== {f}: {total} samples")
        for cat, _ in RULES + [(OTHER, None)]:
            print(f"  {100 * cats[cat] / total:5.1f} %  {cat}")
        print(f"  top {a.top} leaf symbols:")
        for sym, n in leaves.most_common(a.top):
            print(f"  {100 * n / total:5.1f} %  [{classify(sym)[:22]}] {short(sym)}")
        if a.callers:
            print(f"  caller chains of leaves ~ /{a.callers}/:")
            for ch, n in callers.most_common(12):
                print(f"  {100 * n / total:5.1f} %  {ch}")
    if a.md and len(results) > 1:
        names = list(results)
        print("\n| category | " + " | ".join(names) + " |")
        print("|---|" + "---|" * len(names))
        for cat, _ in RULES + [(OTHER, None)]:
            print(f"| {cat} | " + " | ".join(f"{100 * results[n][1][cat] / results[n][0]:.1f} %" for n in names) + " |")


if __name__ == "__main__":
    main()
