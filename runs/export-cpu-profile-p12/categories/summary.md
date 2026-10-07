# CPU categories of export-cpu-profile-p12

perf record -g of the whole server during the measured request (see driver.log);
classified by export-cpu-categories.py (leaf-first rules, copied here).
process = all threads of the server; thread = the thread with the most samples.

## H-vocab-label-large-cold-rec (process)

total samples: 18369

| category | share |
|---|---|
| other | 96.3 % |
| result streaming / HTTP | 1.3 % |
| kernel other | 1.1 % |
| other syscalls (futex, mmap, ...) | 0.7 % |
| page-cache fast path (preadv2, kernel+libc) | 0.3 % |
| page faults | 0.3 % |
| string building / memcpy | 0.0 % |


## H-vocab-label-large-de-cold-rec (process)

total samples: 17130

| category | share |
|---|---|
| page-cache fast path (preadv2, kernel+libc) | 58.0 % |
| vocab lookup: internal/external membership probe | 16.2 % |
| triple instantiation | 4.3 % |
| FSST decode | 4.1 % |
| allocation / refcount | 3.4 % |
| other | 2.1 % |
| sort / dedup of IDs | 1.9 % |
| vocab lookup: offsets / batch plumbing | 1.7 % |
| Turtle formatting / escaping | 1.6 % |
| io_uring (submit/wait, kernel+lib) | 1.5 % |
| string building / memcpy | 1.4 % |
| other syscalls (futex, mmap, ...) | 1.2 % |
| correctness checks | 0.9 % |
| kernel other | 0.7 % |
| IdCache (LRU) | 0.5 % |
| result streaming / HTTP | 0.4 % |
| page faults | 0.2 % |


## H-vocab-label-large-de-warm-rec (process)

total samples: 11952

| category | share |
|---|---|
| other | 55.8 % |
| page-cache fast path (preadv2, kernel+libc) | 37.8 % |
| other syscalls (futex, mmap, ...) | 4.8 % |
| kernel other | 0.9 % |
| result streaming / HTTP | 0.5 % |
| page faults | 0.2 % |


## H-vocab-label-large-warm-rec (process)

total samples: 17765

| category | share |
|---|---|
| other | 96.7 % |
| result streaming / HTTP | 1.2 % |
| kernel other | 1.0 % |
| other syscalls (futex, mmap, ...) | 0.7 % |
| page faults | 0.2 % |
| page-cache fast path (preadv2, kernel+libc) | 0.1 % |
| allocation / refcount | 0.0 % |
| string building / memcpy | 0.0 % |


