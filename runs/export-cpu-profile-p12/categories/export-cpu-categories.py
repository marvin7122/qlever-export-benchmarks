#!/usr/bin/env python3
"""Break the export thread's cycles (stacks.collapsed of one thread) into
cost categories, and list the top symbols (self) with their main call paths.

Usage: export-cpu-categories.py <stacks.collapsed> [--top 15] [--md]

Each sample is classified by its leaf frame first; kernel and libc leaves are
attributed by the first recognisable user frame or syscall frame on the stack.
"""
import argparse
import collections
import re
import sys

# (category, regex on a frame), checked leaf-first. First match wins.
LEAF_RULES = [
    ("page-cache fast path (preadv2, kernel+libc)", r"preadv64v2|preadv2|readPageCacheHits"),
    ("FSST decode", r"fsst_decompress|FsstRepeatedDecoder|Fsst\w*decompress|FsstSquared|decompressInto"),
    ("vocab lookup: internal/external membership probe", r"positionOfIndex|VocabularyInMemoryBinSearch|VocabularyInternalExternal::lookupBatch|indexAtPosition"),
    ("vocab lookup: offsets / batch plumbing", r"readOffsetPairs|readStrings|VocabularyOnDisk::|CompressedVocabulary|MultiSourceVocabBatchAssembler|VocabBatch|ArenaVocabBatch|ContiguousVocabBatch|idsToStringAndType|getDecoderIdx|SplitVocabulary|PolymorphicVocabulary|lookupBatch|ResidentFileMapping|MarkerIndices"),
    ("IdCache (LRU)", r"LRUCache|IdCache|tryGet|getOrCompute|flat_hash_map|raw_hash_set|hash_internal|AbslHash|node_hash"),
    ("sort / dedup of IDs", r"compareThreeWay|__introsort|__insertion_sort|pdqsort|__unguarded|__adjust_heap|std::sort|ConstructDeduplicator"),
    ("triple instantiation", r"instantiateBatch|ConstructTripleInstantiator|evaluateVariableByColumn|evaluateBatch|ConstructBatchEvaluator|EvaluatedTerm|computeBatch|stringAndTypeToEvaluatedTerm|ExportIds|exportIds|idToStringAndType"),
    ("Turtle formatting / escaping", r"FastExportStreamFormatter|writeEscaped|formatTriple|Escape|escape|Turtle|toRdfLiteral|formatTriplesAsTurtle"),
    ("allocation / refcount", r"^(je_|malloc|free|calloc|realloc|operator new|operator delete|_int_malloc|_int_free|tcache|arena_|extent_|imalloc|ifree|sdallocx|mallocx)|jemalloc|_Sp_counted_base|shared_ptr|__shared_count|make_shared|pmr::|monotonic_buffer|memory_resource"),
    ("string building / memcpy", r"memcpy|memmove|__memcpy|__memmove|basic_string|_M_construct|_M_append|_M_replace|_M_mutate|_M_create|string_view|StrCat|StrAppend|resize_and_overwrite|rep_movs"),
    ("result streaming / HTTP", r"stream_generator|StringBatcher|beast|asio|writev|tcp_|sock_|inet_|__sys_sendmsg|ip_|skb|netif|net_rx|nf_|streamable_body|convertStreamGenerator|AdaptiveChunkSizer|awaitable"),
    ("correctness checks", r"adCorrectnessCheckImpl|AD_CORRECTNESS|adContractCheck"),
]
LEAF_RULES = [(c, re.compile(r)) for c, r in LEAF_RULES]

SYSCALL_RULES = [
    ("page-cache fast path (preadv2, kernel+libc)", re.compile(r"preadv2|preadv64v2|readPageCacheHits|__x64_sys_preadv2|do_preadv|filemap_read")),
    ("io_uring (submit/wait, kernel+lib)", re.compile(r"io_uring|IoUring|__io_|io_cqring|io_submit|BatchManager|readThroughManager")),
    ("result streaming / HTTP", re.compile(r"writev|sendmsg|tcp_|sock_|beast|asio")),
    ("page faults", re.compile(r"asm_exc_page_fault|exc_page_fault|handle_mm_fault|do_user_addr_fault")),
    ("other syscalls (futex, mmap, ...)", re.compile(r"entry_SYSCALL|do_syscall_64|futex|madvise|mmap|munmap")),
]


KENTRY = re.compile(r"^(entry_SYSCALL|asm_exc_|asm_sysvec|asm_common_interrupt|ret_from_fork|irq_exit|common_interrupt)")


def is_kernel(frame):
    return frame.endswith("_[k]") or "[kernel" in frame


def kernel_start(frames):
    """Index of the first kernel-entry frame, or None (stackcollapse-perf
    does not mark kernel frames by default)."""
    for i, f in enumerate(frames):
        if KENTRY.search(f) or is_kernel(f):
            return i
    return None


def classify(frames):
    ks = kernel_start(frames)
    if ks is not None:
        for cat, rx in SYSCALL_RULES:
            if any(rx.search(f) for f in frames):
                return cat
        return "kernel other"
    # libc / library leaf: memcpy etc. are categories of their own; otherwise
    # walk up to the first frame that matches a rule
    for f in reversed(frames):
        for cat, rx in LEAF_RULES:
            if rx.search(f):
                return cat
    return "other"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("collapsed")
    ap.add_argument("--top", type=int, default=15)
    ap.add_argument("--paths", type=int, default=2)
    a = ap.parse_args()
    cats = collections.Counter()
    sym = collections.Counter()
    paths = collections.defaultdict(collections.Counter)
    total = 0
    for line in open(a.collapsed):
        line = line.rstrip("\n")
        if not line:
            continue
        stack, _, n = line.rpartition(" ")
        n = int(n)
        frames = stack.split(";")[1:] if ";" in stack else [stack]
        if not frames:
            continue
        total += n
        cats[classify(frames)] += n
        leaf = frames[-1]
        sym[leaf] += n
        # call path: up to 4 nearest user frames above the leaf (skip kernel)
        ks = kernel_start(frames)
        ufr = frames[:ks] if ks is not None else frames[:-1]
        users = [re.sub(r"\(.*", "", f)[:70] for f in ufr]
        paths[leaf][" < ".join(reversed(users[-4:]))] += n
    print(f"total samples: {total}")
    print("\n| category | share |\n|---|---|")
    for c, n in cats.most_common():
        print(f"| {c} | {100.0 * n / total:.1f} % |")
    print(f"\n| # | symbol (self) | share | main call paths |\n|---|---|---|---|")
    for i, (s, n) in enumerate(sym.most_common(a.top), 1):
        p = "; ".join(f"{q} ({100.0 * m / n:.0f} %)" for q, m in paths[s].most_common(a.paths))
        name = re.sub(r"\(.*", "", s)[:90]
        print(f"| {i} | `{name}` | {100.0 * n / total:.1f} % | {p} |")


if __name__ == "__main__":
    sys.exit(main())
