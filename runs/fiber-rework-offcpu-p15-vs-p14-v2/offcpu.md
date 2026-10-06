| query | arm | trial | elapsed s | export on-CPU s | export off-CPU s | off-CPU by syscall (s) | server CPU s |
|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | p14-3476 | 1 | 25.078 | 24.106 | 0.957 | S:futex=0.459, S:io_uring_enter=0.399, S:running=0.1 | 28.404 |
| H-vocab-label-large-de | p15-3477 | 1 | 24.782 | 23.922 | 0.856 | S:futex=0.363, S:io_uring_enter=0.354, S:running=0.139 | 28.13 |
| H-vocab-random-label-de-200k | p14-3476 | 1 | 10.691 | 4.469 | 6.217 | D:pread64=2.884, S:epoll_wait=2.485, S:futex=0.598, D:running=0.242, D:nr-1=0.006 | 7.925 |
| H-vocab-random-label-de-200k | p15-3477 | 1 | 10.695 | 4.429 | 6.263 | D:pread64=2.946, S:epoll_wait=2.428, S:futex=0.635, D:running=0.244, S:running=0.005 | 7.957 |
| H-vocab-label-large-de | p15-3477 | 2 | 24.986 | 24.123 | 0.853 | S:io_uring_enter=0.373, S:futex=0.373, S:running=0.107 | 28.277 |
| H-vocab-label-large-de | p14-3476 | 2 | 25.298 | 24.351 | 0.914 | S:io_uring_enter=0.423, S:futex=0.403, S:running=0.088 | 28.697 |
| H-vocab-random-label-de-200k | p15-3477 | 2 | 11.611 | 5.004 | 6.581 | D:pread64=2.834, S:epoll_wait=2.757, S:futex=0.7, D:running=0.286, S:running=0.002 | 8.835 |
| H-vocab-random-label-de-200k | p14-3476 | 2 | 11.265 | 4.88 | 6.376 | S:futex=3.033, D:pread64=2.879, D:running=0.277, S:epoll_wait=0.184, S:running=0.001 | 8.499 |
| H-vocab-label-large-de | p14-3476 | 3 | 25.315 | 24.38 | 0.921 | S:futex=0.417, S:io_uring_enter=0.386, S:running=0.118 | 28.676 |
| H-vocab-label-large-de | p15-3477 | 3 | 25.935 | 25.043 | 0.868 | S:io_uring_enter=0.374, S:futex=0.374, S:running=0.12 | 29.326 |
| H-vocab-random-label-de-200k | p14-3476 | 3 | 11.102 | 4.97 | 6.129 | D:pread64=2.93, S:futex=2.915, D:running=0.255, S:epoll_wait=0.021, S:running=0.006 | 8.332 |
| H-vocab-random-label-de-200k | p15-3477 | 3 | 10.551 | 4.505 | 6.043 | D:pread64=2.959, S:futex=2.823, D:running=0.234, S:epoll_wait=0.021, S:running=0.006 | 7.732 |

H-vocab-label-large-de: byte-identical across arms and trials: yes
H-vocab-random-label-de-200k: byte-identical across arms and trials: yes
