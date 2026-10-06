## p12 H-vocab-label-large-de cold-r1: wall 25.31 s, ttfb 0.098 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.22 s
  tid 332872 qlever-server: on-CPU 0.13 s (user 0.01, sys 0.11), runqueue 0.02 s, off-CPU 25.15 s, read 21 MiB, vcs 608, nvcs 162
    samples: S|futex|futex_do_wait 80.4%; S|epoll_wait|ep_poll 16.6%; R|-|- 2.7%; S|running|0 0.2%; S|futex|0 0.1%; S|epoll_wait|0 0.0%
  tid 332871 qlever-server: on-CPU 0.09 s (user 0.00, sys 0.07), runqueue 0.01 s, off-CPU 25.21 s, read 3 MiB, vcs 614, nvcs 152
    samples: S|futex|futex_do_wait 56.4%; S|epoll_wait|ep_poll 42.9%; R|-|- 0.6%; S|running|0 0.1%
  tid 281891 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 25.30 s, read 0 MiB, vcs 13, nvcs 0
    samples: S|futex|futex_do_wait 100.0%
  tid 332867 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 25.30 s, read 0 MiB, vcs 7, nvcs 0
    samples: S|futex|futex_do_wait 99.0%; R|-|- 0.5%; D|pread64|folio_wait_bit_common 0.5%

## p12 H-vocab-label-large-de warm-r1: wall 16.89 s, ttfb 0.035 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.19 s
  tid 332872 qlever-server: on-CPU 0.10 s (user 0.02, sys 0.07), runqueue 0.01 s, off-CPU 16.77 s, read 0 MiB, vcs 588, nvcs 121
    samples: S|futex|futex_do_wait 71.6%; S|epoll_wait|ep_poll 27.1%; R|-|- 1.3%; S|running|0 0.1%
  tid 332871 qlever-server: on-CPU 0.09 s (user 0.01, sys 0.08), runqueue 0.01 s, off-CPU 16.79 s, read 0 MiB, vcs 584, nvcs 126
    samples: S|futex|futex_do_wait 51.8%; S|epoll_wait|ep_poll 47.5%; R|-|- 0.8%
  tid 281891 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 16.88 s, read 0 MiB, vcs 9, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p12 H-vocab-random-label-de-200k cold-r1: wall 11.22 s, ttfb 8.412 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 4.18 s
  tid 495249 qlever-server: on-CPU 3.81 s (user 1.84, sys 1.96), runqueue 0.05 s, off-CPU 7.36 s, read 1454 MiB, vcs 50277, nvcs 161
    samples: R|-|- 46.7%; D|pread64|folio_wait_bit_common 18.9%; D|pread64|0 9.2%; S|epoll_wait|ep_poll 7.8%; S|futex|futex_do_wait 6.4%; D|running|folio_wait_bit_common 6.0%
  tid 495242 qlever-server: on-CPU 0.33 s (user 0.10, sys 0.22), runqueue 0.00 s, off-CPU 10.89 s, read 0 MiB, vcs 3, nvcs 1
    samples: S|futex|futex_do_wait 79.0%; R|-|- 21.0%
  tid 495248 qlever-server: on-CPU 0.04 s (user 0.01, sys 0.02), runqueue 0.00 s, off-CPU 11.18 s, read 0 MiB, vcs 1708, nvcs 10
    samples: S|epoll_wait|ep_poll 89.2%; S|futex|futex_do_wait 10.8%
  tid 495246 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 11.22 s, read 0 MiB, vcs 2, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p12 H-vocab-random-label-de-200k warm-r1: wall 4.82 s, ttfb 3.910 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 2.83 s
  tid 495248 qlever-server: on-CPU 2.46 s (user 1.70, sys 0.77), runqueue 0.01 s, off-CPU 2.36 s, read 0 MiB, vcs 2194, nvcs 32
    samples: R|-|- 68.2%; S|futex|futex_do_wait 19.8%; S|epoll_wait|ep_poll 12.0%
  tid 495242 qlever-server: on-CPU 0.32 s (user 0.11, sys 0.21), runqueue 0.00 s, off-CPU 4.50 s, read 0 MiB, vcs 1, nvcs 5
    samples: S|futex|futex_do_wait 64.8%; R|-|- 35.2%
  tid 495249 qlever-server: on-CPU 0.06 s (user 0.03, sys 0.02), runqueue 0.00 s, off-CPU 4.76 s, read 0 MiB, vcs 2687, nvcs 10
    samples: S|futex|futex_do_wait 50.0%; S|epoll_wait|ep_poll 50.0%

## p13-depth2 H-vocab-label-large-de cold-r1: wall 27.16 s, ttfb 0.394 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.39 s
  tid 584330 qlever-server: on-CPU 0.28 s (user 0.04, sys 0.23), runqueue 0.04 s, off-CPU 26.84 s, read 88 MiB, vcs 812, nvcs 422
    samples: S|futex|futex_do_wait 58.0%; S|epoll_wait|ep_poll 33.3%; R|-|- 8.4%; S|epoll_wait|0 0.0%; D|pread64|0 0.0%; S|running|ep_poll 0.0%
  tid 584331 qlever-server: on-CPU 0.11 s (user 0.00, sys 0.09), runqueue 0.02 s, off-CPU 27.03 s, read 0 MiB, vcs 804, nvcs 421
    samples: S|futex|futex_do_wait 61.7%; S|epoll_wait|ep_poll 37.6%; R|-|- 0.6%; S|futex|0 0.1%; S|running|futex_do_wait 0.1%
  tid 538364 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 27.16 s, read 0 MiB, vcs 14, nvcs 0
    samples: S|futex|futex_do_wait 100.0%
  tid 584326 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 27.16 s, read 0 MiB, vcs 7, nvcs 0
    samples: S|futex|futex_do_wait 98.5%; D|pread64|folio_wait_bit_common 1.5%

## p13-depth2 H-vocab-label-large-de warm-r1: wall 23.94 s, ttfb 0.172 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.28 s
  tid 584331 qlever-server: on-CPU 0.16 s (user 0.06, sys 0.11), runqueue 0.07 s, off-CPU 23.71 s, read 0 MiB, vcs 690, nvcs 276
    samples: S|epoll_wait|ep_poll 58.0%; S|futex|futex_do_wait 38.5%; R|-|- 3.4%; S|futex|0 0.0%; S|running|0 0.0%
  tid 584330 qlever-server: on-CPU 0.11 s (user 0.01, sys 0.10), runqueue 0.08 s, off-CPU 23.76 s, read 0 MiB, vcs 688, nvcs 272
    samples: S|futex|futex_do_wait 62.7%; S|epoll_wait|ep_poll 36.6%; R|-|- 0.7%; S|running|0 0.0%; S|running|ep_poll 0.0%
  tid 538364 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 23.94 s, read 0 MiB, vcs 12, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p13-depth2 H-vocab-random-label-de-200k cold-r1: wall 13.58 s, ttfb 10.612 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 5.97 s
  tid 747790 qlever-server: on-CPU 5.52 s (user 3.05, sys 2.46), runqueue 0.28 s, off-CPU 7.78 s, read 1524 MiB, vcs 49491, nvcs 109
    samples: R|-|- 57.7%; D|pread64|folio_wait_bit_common 11.6%; S|futex|futex_do_wait 10.8%; D|pread64|0 9.0%; D|running|0 6.2%; D|running|folio_wait_bit_common 4.6%
  tid 747784 qlever-server: on-CPU 0.42 s (user 0.13, sys 0.28), runqueue 0.00 s, off-CPU 13.16 s, read 0 MiB, vcs 3, nvcs 7
    samples: S|futex|futex_do_wait 65.9%; R|-|- 34.1%
  tid 747789 qlever-server: on-CPU 0.03 s (user 0.01, sys 0.01), runqueue 0.00 s, off-CPU 13.54 s, read 0 MiB, vcs 2159, nvcs 4
    samples: S|epoll_wait|ep_poll 100.0%
  tid 747788 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 13.58 s, read 0 MiB, vcs 2, nvcs 1
    samples: S|futex|futex_do_wait 100.0%

## p13-depth2 H-vocab-random-label-de-200k warm-r1: wall 5.90 s, ttfb 5.023 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 3.88 s
  tid 747789 qlever-server: on-CPU 3.47 s (user 2.53, sys 0.93), runqueue 0.01 s, off-CPU 2.42 s, read 0 MiB, vcs 1217, nvcs 121
    samples: R|-|- 75.4%; S|futex|futex_do_wait 21.4%; S|epoll_wait|ep_poll 3.1%; S|futex|0 0.0%; S|running|0 0.0%
  tid 747784 qlever-server: on-CPU 0.37 s (user 0.13, sys 0.24), runqueue 0.00 s, off-CPU 5.53 s, read 0 MiB, vcs 1, nvcs 7
    samples: S|futex|futex_do_wait 70.3%; R|-|- 29.7%
  tid 747790 qlever-server: on-CPU 0.05 s (user 0.03, sys 0.01), runqueue 0.01 s, off-CPU 5.85 s, read 0 MiB, vcs 2072, nvcs 26
    samples: S|epoll_wait|ep_poll 100.0%
  tid 788199 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 5.90 s, read 0 MiB, vcs 87, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p13-pipe3 H-vocab-label-large-de cold-r1: wall 25.14 s, ttfb 0.098 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.23 s
  tid 853546 qlever-server: on-CPU 0.15 s (user 0.01, sys 0.13), runqueue 0.01 s, off-CPU 24.97 s, read 21 MiB, vcs 600, nvcs 138
    samples: S|futex|futex_do_wait 57.6%; S|epoll_wait|ep_poll 40.4%; R|-|- 2.0%
  tid 853547 qlever-server: on-CPU 0.08 s (user 0.00, sys 0.06), runqueue 0.01 s, off-CPU 25.05 s, read 3 MiB, vcs 600, nvcs 136
    samples: S|epoll_wait|ep_poll 63.7%; S|futex|futex_do_wait 36.0%; R|-|- 0.3%; S|epoll_wait|0 0.1%
  tid 803179 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 25.13 s, read 0 MiB, vcs 14, nvcs 0
    samples: S|futex|futex_do_wait 100.0%
  tid 853542 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 25.14 s, read 0 MiB, vcs 7, nvcs 0
    samples: S|futex|futex_do_wait 98.0%; D|pread64|folio_wait_bit_common 1.5%; R|-|- 0.5%

## p13-pipe3 H-vocab-label-large-de warm-r1: wall 16.25 s, ttfb 0.038 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.21 s
  tid 853547 qlever-server: on-CPU 0.11 s (user 0.01, sys 0.10), runqueue 0.02 s, off-CPU 16.12 s, read 0 MiB, vcs 541, nvcs 61
    samples: S|futex|futex_do_wait 82.4%; S|epoll_wait|ep_poll 16.7%; R|-|- 0.8%; S|running|0 0.0%
  tid 853546 qlever-server: on-CPU 0.10 s (user 0.01, sys 0.08), runqueue 0.01 s, off-CPU 16.15 s, read 0 MiB, vcs 538, nvcs 71
    samples: S|futex|futex_do_wait 81.3%; S|epoll_wait|ep_poll 17.1%; R|-|- 1.5%; S|running|0 0.0%

## p13-pipe3 H-vocab-random-label-de-200k cold-r1: wall 14.17 s, ttfb 10.733 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 5.29 s
  tid 1002702 qlever-server: on-CPU 4.83 s (user 2.32, sys 2.50), runqueue 1.21 s, off-CPU 8.13 s, read 1454 MiB, vcs 48724, nvcs 114
    samples: R|-|- 59.3%; D|pread64|folio_wait_bit_common 9.2%; D|pread64|0 8.8%; S|futex|futex_do_wait 6.9%; D|running|folio_wait_bit_common 6.9%; D|running|0 6.2%
  tid 1002698 qlever-server: on-CPU 0.43 s (user 0.14, sys 0.28), runqueue 0.00 s, off-CPU 13.75 s, read 0 MiB, vcs 3, nvcs 9
    samples: S|futex|futex_do_wait 58.7%; R|-|- 40.5%; D|pread64|folio_wait_bit_common 0.8%
  tid 1002703 qlever-server: on-CPU 0.03 s (user 0.01, sys 0.01), runqueue 0.01 s, off-CPU 14.13 s, read 0 MiB, vcs 1806, nvcs 10
    samples: S|epoll_wait|ep_poll 100.0%
  tid 1002701 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 14.17 s, read 0 MiB, vcs 1, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p13-pipe3 H-vocab-random-label-de-200k warm-r1: wall 5.64 s, ttfb 4.585 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 3.51 s
  tid 1002703 qlever-server: on-CPU 3.03 s (user 2.00, sys 1.03), runqueue 0.02 s, off-CPU 2.60 s, read 0 MiB, vcs 1598, nvcs 44
    samples: R|-|- 72.1%; S|futex|futex_do_wait 25.7%; S|epoll_wait|ep_poll 2.1%
  tid 1002698 qlever-server: on-CPU 0.42 s (user 0.16, sys 0.26), runqueue 0.00 s, off-CPU 5.22 s, read 0 MiB, vcs 1, nvcs 4
    samples: S|futex|futex_do_wait 67.5%; R|-|- 32.5%
  tid 1002702 qlever-server: on-CPU 0.06 s (user 0.03, sys 0.03), runqueue 0.00 s, off-CPU 5.58 s, read 0 MiB, vcs 1707, nvcs 15
    samples: S|epoll_wait|ep_poll 89.9%; S|futex|futex_do_wait 9.8%; R|-|- 0.3%
  tid 1002701 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 5.64 s, read 0 MiB, vcs 3, nvcs 0
    samples: S|futex|futex_do_wait 99.5%; R|-|- 0.5%

## p8-presented H-vocab-label-large-de cold-r1: wall 26.63 s, ttfb 0.425 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.39 s
  tid 1092071 qlever-server: on-CPU 0.32 s (user 0.04, sys 0.27), runqueue 0.01 s, off-CPU 26.29 s, read 88 MiB, vcs 613, nvcs 175
    samples: S|futex|futex_do_wait 76.4%; S|epoll_wait|ep_poll 15.3%; R|-|- 8.3%
  tid 1092072 qlever-server: on-CPU 0.07 s (user 0.01, sys 0.06), runqueue 0.01 s, off-CPU 26.54 s, read 0 MiB, vcs 617, nvcs 158
    samples: S|futex|futex_do_wait 51.6%; S|epoll_wait|ep_poll 47.5%; R|-|- 0.8%; S|futex|0 0.1%; S|running|0 0.1%
  tid 1045587 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 26.63 s, read 0 MiB, vcs 14, nvcs 0
    samples: S|futex|futex_do_wait 100.0%
  tid 1092065 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 26.63 s, read 0 MiB, vcs 7, nvcs 0
    samples: S|futex|futex_do_wait 98.5%; D|pread64|folio_wait_bit_common 1.0%; D|running|0 0.5%

## p8-presented H-vocab-label-large-de warm-r1: wall 17.39 s, ttfb 0.116 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.22 s
  tid 1092071 qlever-server: on-CPU 0.12 s (user 0.03, sys 0.09), runqueue 0.01 s, off-CPU 17.26 s, read 0 MiB, vcs 573, nvcs 106
    samples: S|epoll_wait|ep_poll 50.5%; S|futex|futex_do_wait 46.2%; R|-|- 3.3%
  tid 1092072 qlever-server: on-CPU 0.10 s (user 0.02, sys 0.08), runqueue 0.01 s, off-CPU 17.28 s, read 0 MiB, vcs 569, nvcs 108
    samples: S|futex|futex_do_wait 79.7%; S|epoll_wait|ep_poll 19.5%; R|-|- 0.7%; S|running|0 0.1%; S|futex|0 0.0%
  tid 1045587 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 17.39 s, read 0 MiB, vcs 9, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p8-presented H-vocab-random-label-de-200k cold-r1: wall 11.79 s, ttfb 9.300 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 5.00 s
  tid 1099988 qlever-server: on-CPU 4.61 s (user 2.55, sys 2.06), runqueue 0.01 s, off-CPU 7.16 s, read 1524 MiB, vcs 49908, nvcs 54
    samples: R|-|- 50.8%; D|pread64|folio_wait_bit_common 19.1%; D|pread64|0 8.4%; S|futex|futex_do_wait 8.2%; D|running|0 5.3%; D|running|folio_wait_bit_common 4.3%
  tid 1099983 qlever-server: on-CPU 0.34 s (user 0.11, sys 0.21), runqueue 0.00 s, off-CPU 11.45 s, read 0 MiB, vcs 3, nvcs 4
    samples: S|futex|futex_do_wait 66.5%; R|-|- 33.5%
  tid 1099987 qlever-server: on-CPU 0.05 s (user 0.02, sys 0.02), runqueue 0.00 s, off-CPU 11.73 s, read 0 MiB, vcs 2008, nvcs 5
    samples: S|futex|futex_do_wait 50.0%; S|epoll_wait|ep_poll 50.0%
  tid 1099986 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 11.78 s, read 0 MiB, vcs 3, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p8-presented H-vocab-random-label-de-200k warm-r1: wall 5.53 s, ttfb 4.582 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 3.47 s
  tid 1099987 qlever-server: on-CPU 3.12 s (user 2.25, sys 0.87), runqueue 0.00 s, off-CPU 2.41 s, read 0 MiB, vcs 3090, nvcs 19
    samples: R|-|- 77.0%; S|futex|futex_do_wait 22.0%; S|epoll_wait|ep_poll 1.0%
  tid 1099983 qlever-server: on-CPU 0.32 s (user 0.11, sys 0.21), runqueue 0.00 s, off-CPU 5.21 s, read 0 MiB, vcs 1, nvcs 4
    samples: S|futex|futex_do_wait 67.6%; R|-|- 32.4%
  tid 1099988 qlever-server: on-CPU 0.03 s (user 0.02, sys 0.01), runqueue 0.01 s, off-CPU 5.49 s, read 0 MiB, vcs 998, nvcs 9
    samples: S|epoll_wait|ep_poll 100.0%

## thread-d2 H-vocab-label-large-de cold-r1: wall 29.40 s, ttfb 0.110 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.19 s
  tid 1101417 qlever-server: on-CPU 0.11 s (user 0.01, sys 0.10), runqueue 0.05 s, off-CPU 29.23 s, read 0 MiB, vcs 652, nvcs 206
    samples: S|futex|futex_do_wait 72.1%; S|epoll_wait|ep_poll 26.9%; R|-|- 0.8%; S|futex|0 0.1%; S|running|ep_poll 0.0%; S|running|0 0.0%
  tid 1101418 qlever-server: on-CPU 0.08 s (user 0.00, sys 0.07), runqueue 0.05 s, off-CPU 29.27 s, read 3 MiB, vcs 652, nvcs 203
    samples: S|futex|futex_do_wait 52.8%; S|epoll_wait|ep_poll 46.5%; R|-|- 0.5%; S|running|0 0.1%; S|epoll_wait|0 0.1%
  tid 1100943 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 29.40 s, read 0 MiB, vcs 15, nvcs 0
    samples: S|futex|futex_do_wait 100.0%
  tid 1101413 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 29.40 s, read 0 MiB, vcs 7, nvcs 1
    samples: S|futex|futex_do_wait 98.0%; D|pread64|folio_wait_bit_common 1.5%; R|-|- 0.5%

## thread-d2 H-vocab-label-large-de warm-r1: wall 17.00 s, ttfb 0.042 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.17 s
  tid 1101418 qlever-server: on-CPU 0.11 s (user 0.02, sys 0.10), runqueue 0.02 s, off-CPU 16.87 s, read 0 MiB, vcs 591, nvcs 117
    samples: S|futex|futex_do_wait 70.7%; S|epoll_wait|ep_poll 28.6%; R|-|- 0.7%
  tid 1101417 qlever-server: on-CPU 0.07 s (user 0.00, sys 0.07), runqueue 0.02 s, off-CPU 16.91 s, read 0 MiB, vcs 580, nvcs 122
    samples: S|futex|futex_do_wait 54.7%; S|epoll_wait|ep_poll 44.5%; R|-|- 0.7%

## thread-d2 H-vocab-random-label-de-200k cold-r1: wall 11.29 s, ttfb 8.516 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 4.30 s
  tid 1102807 qlever-server: on-CPU 3.85 s (user 1.87, sys 1.98), runqueue 0.01 s, off-CPU 7.43 s, read 1439 MiB, vcs 48196, nvcs 136
    samples: R|-|- 49.4%; D|pread64|folio_wait_bit_common 20.9%; S|futex|futex_do_wait 10.7%; D|pread64|0 8.2%; D|running|folio_wait_bit_common 5.4%; D|running|0 4.8%
  tid 1102803 qlever-server: on-CPU 0.42 s (user 0.15, sys 0.27), runqueue 0.00 s, off-CPU 10.87 s, read 0 MiB, vcs 3, nvcs 14
    samples: S|futex|futex_do_wait 69.3%; R|-|- 30.7%
  tid 1102808 qlever-server: on-CPU 0.03 s (user 0.00, sys 0.01), runqueue 0.00 s, off-CPU 11.26 s, read 0 MiB, vcs 3498, nvcs 15
    samples: S|epoll_wait|ep_poll 100.0%

## thread-d2 H-vocab-random-label-de-200k warm-r1: wall 4.68 s, ttfb 3.904 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 2.84 s
  tid 1102807 qlever-server: on-CPU 2.48 s (user 1.59, sys 0.89), runqueue 0.00 s, off-CPU 2.20 s, read 0 MiB, vcs 4421, nvcs 13
    samples: R|-|- 71.4%; S|futex|futex_do_wait 23.9%; S|epoll_wait|ep_poll 4.8%
  tid 1102803 qlever-server: on-CPU 0.33 s (user 0.12, sys 0.21), runqueue 0.00 s, off-CPU 4.36 s, read 0 MiB, vcs 1, nvcs 2
    samples: S|futex|futex_do_wait 70.2%; R|-|- 29.8%
  tid 1102808 qlever-server: on-CPU 0.03 s (user 0.01, sys 0.03), runqueue 0.00 s, off-CPU 4.65 s, read 0 MiB, vcs 444, nvcs 5
    samples: S|epoll_wait|ep_poll 100.0%

## thread-d2 H-vocab-label-large-de cold-r2: wall 27.98 s, ttfb 0.088 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.21 s
  tid 1103660 qlever-server: on-CPU 0.12 s (user 0.01, sys 0.10), runqueue 0.05 s, off-CPU 27.82 s, read 0 MiB, vcs 699, nvcs 275
    samples: S|futex|futex_do_wait 57.9%; S|epoll_wait|ep_poll 41.2%; R|-|- 0.9%; S|running|0 0.0%; S|epoll_wait|0 0.0%
  tid 1103661 qlever-server: on-CPU 0.09 s (user 0.01, sys 0.07), runqueue 0.05 s, off-CPU 27.85 s, read 0 MiB, vcs 704, nvcs 274
    samples: S|futex|futex_do_wait 51.3%; S|epoll_wait|ep_poll 48.1%; R|-|- 0.6%; S|running|0 0.1%
  tid 1103306 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 27.98 s, read 0 MiB, vcs 14, nvcs 0
    samples: S|futex|futex_do_wait 100.0%
  tid 1103656 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 27.98 s, read 0 MiB, vcs 7, nvcs 0
    samples: S|futex|futex_do_wait 98.5%; D|pread64|folio_wait_bit_common 1.0%; S|running|0 0.5%

## thread-d2 H-vocab-label-large-de warm-r2: wall 19.97 s, ttfb 0.042 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.20 s
  tid 1103660 qlever-server: on-CPU 0.10 s (user 0.02, sys 0.09), runqueue 0.06 s, off-CPU 19.81 s, read 0 MiB, vcs 655, nvcs 213
    samples: S|futex|futex_do_wait 51.8%; S|epoll_wait|ep_poll 47.4%; R|-|- 0.6%; S|running|0 0.1%; S|futex|0 0.0%
  tid 1103661 qlever-server: on-CPU 0.10 s (user 0.01, sys 0.09), runqueue 0.05 s, off-CPU 19.82 s, read 0 MiB, vcs 652, nvcs 212
    samples: S|futex|futex_do_wait 51.4%; S|epoll_wait|ep_poll 47.6%; R|-|- 0.9%; S|running|0 0.0%
  tid 1103306 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 19.97 s, read 0 MiB, vcs 10, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## thread-d2 H-vocab-random-label-de-200k cold-r2: wall 11.69 s, ttfb 8.679 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 4.40 s
  tid 1106106 qlever-server: on-CPU 3.97 s (user 1.88, sys 2.08), runqueue 0.03 s, off-CPU 7.69 s, read 1439 MiB, vcs 48804, nvcs 132
    samples: R|-|- 46.3%; D|pread64|folio_wait_bit_common 19.1%; S|futex|futex_do_wait 9.7%; D|pread64|0 9.7%; D|running|0 6.6%; D|running|folio_wait_bit_common 4.6%
  tid 1106102 qlever-server: on-CPU 0.38 s (user 0.13, sys 0.24), runqueue 0.00 s, off-CPU 11.31 s, read 0 MiB, vcs 3, nvcs 17
    samples: S|futex|futex_do_wait 67.7%; R|-|- 32.3%
  tid 1106107 qlever-server: on-CPU 0.06 s (user 0.02, sys 0.02), runqueue 0.00 s, off-CPU 11.63 s, read 0 MiB, vcs 2309, nvcs 6
    samples: S|epoll_wait|ep_poll 50.5%; S|futex|futex_do_wait 49.5%
  tid 1106105 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 11.68 s, read 0 MiB, vcs 2, nvcs 1
    samples: S|futex|futex_do_wait 100.0%

## thread-d2 H-vocab-random-label-de-200k warm-r2: wall 5.01 s, ttfb 4.092 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 2.96 s
  tid 1106106 qlever-server: on-CPU 2.53 s (user 1.67, sys 0.86), runqueue 0.01 s, off-CPU 2.47 s, read 0 MiB, vcs 1120, nvcs 25
    samples: R|-|- 74.2%; S|futex|futex_do_wait 25.7%; S|futex|0 0.0%
  tid 1106102 qlever-server: on-CPU 0.37 s (user 0.13, sys 0.24), runqueue 0.00 s, off-CPU 4.64 s, read 0 MiB, vcs 1, nvcs 6
    samples: S|futex|futex_do_wait 70.0%; R|-|- 30.0%
  tid 1106107 qlever-server: on-CPU 0.06 s (user 0.04, sys 0.02), runqueue 0.00 s, off-CPU 4.95 s, read 0 MiB, vcs 1264, nvcs 102
    samples: S|epoll_wait|ep_poll 100.0%
  tid 1106105 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 5.01 s, read 0 MiB, vcs 1, nvcs 1
    samples: S|futex|futex_do_wait 100.0%

## p8-presented H-vocab-label-large-de cold-r2: wall 25.78 s, ttfb 0.440 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.40 s
  tid 1107045 qlever-server: on-CPU 0.31 s (user 0.04, sys 0.27), runqueue 0.02 s, off-CPU 25.44 s, read 85 MiB, vcs 699, nvcs 258
    samples: S|futex|futex_do_wait 61.9%; S|epoll_wait|ep_poll 29.2%; R|-|- 8.9%; S|running|0 0.1%
  tid 1107046 qlever-server: on-CPU 0.08 s (user 0.00, sys 0.07), runqueue 0.01 s, off-CPU 25.69 s, read 0 MiB, vcs 686, nvcs 267
    samples: S|futex|futex_do_wait 61.5%; S|epoll_wait|ep_poll 37.7%; R|-|- 0.9%
  tid 1106707 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 25.78 s, read 0 MiB, vcs 13, nvcs 0
    samples: S|futex|futex_do_wait 100.0%
  tid 1107041 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 25.78 s, read 0 MiB, vcs 7, nvcs 0
    samples: S|futex|futex_do_wait 98.0%; D|pread64|folio_wait_bit_common 2.0%

## p8-presented H-vocab-label-large-de warm-r2: wall 16.76 s, ttfb 0.111 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.22 s
  tid 1107046 qlever-server: on-CPU 0.15 s (user 0.03, sys 0.12), runqueue 0.00 s, off-CPU 16.60 s, read 0 MiB, vcs 595, nvcs 138
    samples: S|futex|futex_do_wait 83.2%; S|epoll_wait|ep_poll 14.0%; R|-|- 2.7%; S|futex|0 0.1%; S|running|0 0.1%
  tid 1107045 qlever-server: on-CPU 0.07 s (user 0.01, sys 0.06), runqueue 0.00 s, off-CPU 16.69 s, read 0 MiB, vcs 593, nvcs 136
    samples: S|epoll_wait|ep_poll 58.1%; S|futex|futex_do_wait 41.3%; R|-|- 0.6%
  tid 1106707 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 16.76 s, read 0 MiB, vcs 9, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p8-presented H-vocab-random-label-de-200k cold-r2: wall 12.34 s, ttfb 9.778 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 5.46 s
  tid 1108726 qlever-server: on-CPU 5.05 s (user 2.81, sys 2.22), runqueue 0.00 s, off-CPU 7.28 s, read 1524 MiB, vcs 48899, nvcs 76
    samples: R|-|- 52.1%; D|pread64|folio_wait_bit_common 17.3%; S|futex|futex_do_wait 11.9%; D|pread64|0 7.8%; D|running|0 5.8%; D|running|folio_wait_bit_common 2.7%
  tid 1108721 qlever-server: on-CPU 0.39 s (user 0.12, sys 0.26), runqueue 0.00 s, off-CPU 11.95 s, read 0 MiB, vcs 3, nvcs 3
    samples: S|futex|futex_do_wait 66.0%; R|-|- 34.0%
  tid 1108725 qlever-server: on-CPU 0.03 s (user 0.01, sys 0.01), runqueue 0.00 s, off-CPU 12.31 s, read 0 MiB, vcs 1610, nvcs 5
    samples: S|futex|futex_do_wait 50.0%; S|epoll_wait|ep_poll 50.0%

## p8-presented H-vocab-random-label-de-200k warm-r2: wall 5.62 s, ttfb 4.664 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 3.54 s
  tid 1108725 qlever-server: on-CPU 3.17 s (user 2.25, sys 0.91), runqueue 0.00 s, off-CPU 2.46 s, read 0 MiB, vcs 2173, nvcs 27
    samples: R|-|- 75.0%; S|futex|futex_do_wait 19.8%; S|epoll_wait|ep_poll 5.2%
  tid 1108721 qlever-server: on-CPU 0.34 s (user 0.11, sys 0.22), runqueue 0.00 s, off-CPU 5.29 s, read 0 MiB, vcs 1, nvcs 2
    samples: S|futex|futex_do_wait 65.9%; R|-|- 34.1%
  tid 1108726 qlever-server: on-CPU 0.03 s (user 0.01, sys 0.02), runqueue 0.00 s, off-CPU 5.59 s, read 0 MiB, vcs 1880, nvcs 0
    samples: S|futex|futex_do_wait 50.0%; S|epoll_wait|ep_poll 50.0%
  tid 1109191 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 5.62 s, read 0 MiB, vcs 83, nvcs 0
    samples: S|futex|futex_do_wait 99.5%; R|-|- 0.5%

## p13-pipe3 H-vocab-label-large-de cold-r2: wall 23.55 s, ttfb 0.103 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.22 s
  tid 1109813 qlever-server: on-CPU 0.17 s (user 0.01, sys 0.15), runqueue 0.02 s, off-CPU 23.36 s, read 21 MiB, vcs 540, nvcs 63
    samples: S|futex|futex_do_wait 91.9%; S|epoll_wait|ep_poll 5.9%; R|-|- 2.1%; S|futex|0 0.0%; S|running|0 0.0%
  tid 1109814 qlever-server: on-CPU 0.04 s (user 0.00, sys 0.04), runqueue 0.02 s, off-CPU 23.49 s, read 0 MiB, vcs 538, nvcs 56
    samples: S|futex|futex_do_wait 54.0%; S|epoll_wait|ep_poll 45.2%; R|-|- 0.5%; S|futex|0 0.2%; S|running|0 0.1%
  tid 1109342 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 23.55 s, read 0 MiB, vcs 12, nvcs 0
    samples: S|futex|futex_do_wait 100.0%
  tid 1109809 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 23.55 s, read 0 MiB, vcs 7, nvcs 0
    samples: S|futex|futex_do_wait 98.0%; D|pread64|folio_wait_bit_common 1.0%; R|-|- 0.5%; D|pread64|0 0.5%

## p13-pipe3 H-vocab-label-large-de warm-r2: wall 15.24 s, ttfb 0.033 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.18 s
  tid 1109814 qlever-server: on-CPU 0.10 s (user 0.01, sys 0.09), runqueue 0.01 s, off-CPU 15.14 s, read 0 MiB, vcs 539, nvcs 63
    samples: S|futex|futex_do_wait 81.9%; S|epoll_wait|ep_poll 16.5%; R|-|- 1.5%; S|futex|0 0.1%
  tid 1109813 qlever-server: on-CPU 0.09 s (user 0.00, sys 0.08), runqueue 0.01 s, off-CPU 15.15 s, read 0 MiB, vcs 538, nvcs 65
    samples: S|futex|futex_do_wait 75.0%; S|epoll_wait|ep_poll 23.8%; R|-|- 1.1%; S|running|ep_poll 0.1%

## p13-pipe3 H-vocab-random-label-de-200k cold-r2: wall 13.16 s, ttfb 9.699 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 5.10 s
  tid 1112033 qlever-server: on-CPU 4.66 s (user 2.26, sys 2.40), runqueue 0.36 s, off-CPU 8.14 s, read 1454 MiB, vcs 48794, nvcs 81
    samples: R|-|- 52.3%; S|futex|futex_do_wait 13.5%; D|pread64|folio_wait_bit_common 12.9%; D|pread64|0 8.9%; D|running|folio_wait_bit_common 6.2%; D|running|0 5.8%
  tid 1112029 qlever-server: on-CPU 0.38 s (user 0.13, sys 0.24), runqueue 0.00 s, off-CPU 12.78 s, read 0 MiB, vcs 3, nvcs 8
    samples: S|futex|futex_do_wait 73.8%; R|-|- 26.2%
  tid 1112034 qlever-server: on-CPU 0.06 s (user 0.03, sys 0.02), runqueue 0.01 s, off-CPU 13.09 s, read 0 MiB, vcs 1814, nvcs 7
    samples: S|epoll_wait|ep_poll 66.5%; S|futex|futex_do_wait 33.0%; R|-|- 0.3%; S|epoll_wait|0 0.2%
  tid 1111531 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 13.16 s, read 0 MiB, vcs 7, nvcs 2
    samples: S|futex|futex_do_wait 100.0%
  tid 1112032 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 13.16 s, read 0 MiB, vcs 1, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p13-pipe3 H-vocab-random-label-de-200k warm-r2: wall 5.45 s, ttfb 4.450 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 3.35 s
  tid 1112034 qlever-server: on-CPU 2.93 s (user 1.92, sys 1.01), runqueue 0.01 s, off-CPU 2.50 s, read 0 MiB, vcs 1525, nvcs 63
    samples: R|-|- 72.2%; S|futex|futex_do_wait 16.7%; S|epoll_wait|ep_poll 11.1%; S|running|0 0.0%
  tid 1112029 qlever-server: on-CPU 0.38 s (user 0.14, sys 0.24), runqueue 0.00 s, off-CPU 5.06 s, read 0 MiB, vcs 1, nvcs 8
    samples: S|futex|futex_do_wait 69.8%; R|-|- 30.2%
  tid 1112033 qlever-server: on-CPU 0.03 s (user 0.01, sys 0.02), runqueue 0.00 s, off-CPU 5.41 s, read 0 MiB, vcs 2084, nvcs 14
    samples: S|epoll_wait|ep_poll 100.0%

## p13-depth2 H-vocab-label-large-de cold-r2: wall 27.66 s, ttfb 0.449 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.39 s
  tid 1113126 qlever-server: on-CPU 0.29 s (user 0.03, sys 0.25), runqueue 0.01 s, off-CPU 27.36 s, read 85 MiB, vcs 596, nvcs 159
    samples: S|futex|futex_do_wait 54.4%; S|epoll_wait|ep_poll 34.5%; R|-|- 11.0%; S|futex|0 0.1%
  tid 1113125 qlever-server: on-CPU 0.09 s (user 0.00, sys 0.08), runqueue 0.02 s, off-CPU 27.54 s, read 0 MiB, vcs 595, nvcs 132
    samples: S|futex|futex_do_wait 61.9%; S|epoll_wait|ep_poll 37.5%; R|-|- 0.6%; S|epoll_wait|0 0.1%
  tid 1112699 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 27.66 s, read 0 MiB, vcs 14, nvcs 0
    samples: S|futex|futex_do_wait 100.0%
  tid 1113121 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 27.66 s, read 0 MiB, vcs 7, nvcs 0
    samples: S|futex|futex_do_wait 98.5%; D|pread64|folio_wait_bit_common 1.5%

## p13-depth2 H-vocab-label-large-de warm-r2: wall 17.60 s, ttfb 0.119 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.22 s
  tid 1113126 qlever-server: on-CPU 0.14 s (user 0.04, sys 0.10), runqueue 0.00 s, off-CPU 17.46 s, read 0 MiB, vcs 559, nvcs 108
    samples: S|futex|futex_do_wait 66.5%; S|epoll_wait|ep_poll 30.4%; R|-|- 3.0%; S|running|0 0.1%; S|futex|0 0.0%
  tid 1113125 qlever-server: on-CPU 0.08 s (user 0.00, sys 0.08), runqueue 0.00 s, off-CPU 17.52 s, read 0 MiB, vcs 573, nvcs 96
    samples: S|futex|futex_do_wait 51.1%; S|epoll_wait|ep_poll 48.2%; R|-|- 0.7%; S|running|ep_poll 0.1%
  tid 1112699 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 17.60 s, read 0 MiB, vcs 9, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p13-depth2 H-vocab-random-label-de-200k cold-r2: wall 11.68 s, ttfb 9.199 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 4.89 s
  tid 1114720 qlever-server: on-CPU 4.52 s (user 2.43, sys 2.08), runqueue 0.01 s, off-CPU 7.15 s, read 1524 MiB, vcs 49014, nvcs 34
    samples: R|-|- 53.5%; D|pread64|folio_wait_bit_common 17.2%; S|futex|futex_do_wait 11.3%; D|pread64|0 7.8%; D|running|0 5.8%; D|running|folio_wait_bit_common 4.2%
  tid 1114716 qlever-server: on-CPU 0.35 s (user 0.11, sys 0.22), runqueue 0.00 s, off-CPU 11.33 s, read 0 MiB, vcs 3, nvcs 6
    samples: S|futex|futex_do_wait 64.8%; R|-|- 34.8%; D|pread64|folio_wait_bit_common 0.4%
  tid 1114721 qlever-server: on-CPU 0.03 s (user 0.01, sys 0.01), runqueue 0.00 s, off-CPU 11.65 s, read 0 MiB, vcs 1688, nvcs 0
    samples: S|epoll_wait|ep_poll 99.7%; S|epoll_wait|0 0.3%
  tid 1114807 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 11.67 s, read 0 MiB, vcs 204, nvcs 1
    samples: S|futex|futex_do_wait 100.0%

## p13-depth2 H-vocab-random-label-de-200k warm-r2: wall 5.41 s, ttfb 4.634 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 3.53 s
  tid 1114721 qlever-server: on-CPU 3.17 s (user 2.31, sys 0.86), runqueue 0.00 s, off-CPU 2.24 s, read 0 MiB, vcs 1493, nvcs 5
    samples: R|-|- 73.4%; S|futex|futex_do_wait 21.4%; S|epoll_wait|ep_poll 5.2%
  tid 1114716 qlever-server: on-CPU 0.33 s (user 0.14, sys 0.20), runqueue 0.00 s, off-CPU 5.08 s, read 0 MiB, vcs 1, nvcs 3
    samples: S|futex|futex_do_wait 71.3%; R|-|- 28.7%
  tid 1114720 qlever-server: on-CPU 0.03 s (user 0.00, sys 0.01), runqueue 0.00 s, off-CPU 5.39 s, read 0 MiB, vcs 890, nvcs 1
    samples: S|epoll_wait|ep_poll 50.1%; S|futex|futex_do_wait 49.9%

## p12 H-vocab-label-large-de cold-r2: wall 31.42 s, ttfb 0.132 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.27 s
  tid 1116050 qlever-server: on-CPU 0.16 s (user 0.01, sys 0.13), runqueue 0.06 s, off-CPU 31.21 s, read 21 MiB, vcs 651, nvcs 211
    samples: S|futex|futex_do_wait 54.2%; S|epoll_wait|ep_poll 43.1%; R|-|- 2.7%
  tid 1116049 qlever-server: on-CPU 0.11 s (user 0.01, sys 0.09), runqueue 0.05 s, off-CPU 31.26 s, read 0 MiB, vcs 652, nvcs 206
    samples: S|futex|futex_do_wait 63.7%; S|epoll_wait|ep_poll 35.3%; R|-|- 0.9%; S|running|0 0.1%
  tid 1115311 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 31.42 s, read 0 MiB, vcs 16, nvcs 0
    samples: S|futex|futex_do_wait 100.0%
  tid 1116045 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 31.42 s, read 0 MiB, vcs 7, nvcs 1
    samples: S|futex|futex_do_wait 93.0%; D|pread64|folio_wait_bit_common 6.0%; R|-|- 1.0%

## p12 H-vocab-label-large-de warm-r2: wall 18.85 s, ttfb 0.040 s, bytes 504927346, sha dcd2b1bc77fc, process on-CPU 0.20 s
  tid 1116050 qlever-server: on-CPU 0.10 s (user 0.01, sys 0.08), runqueue 0.02 s, off-CPU 18.73 s, read 0 MiB, vcs 616, nvcs 164
    samples: S|futex|futex_do_wait 67.0%; S|epoll_wait|ep_poll 31.4%; R|-|- 1.3%; S|running|0 0.2%
  tid 1116049 qlever-server: on-CPU 0.10 s (user 0.01, sys 0.09), runqueue 0.02 s, off-CPU 18.72 s, read 0 MiB, vcs 619, nvcs 161
    samples: S|futex|futex_do_wait 54.7%; S|epoll_wait|ep_poll 44.5%; R|-|- 0.7%; S|futex|0 0.0%; S|epoll_wait|0 0.0%
  tid 1115311 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 18.84 s, read 0 MiB, vcs 10, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p12 H-vocab-random-label-de-200k cold-r2: wall 11.70 s, ttfb 8.649 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 4.35 s
  tid 1117886 qlever-server: on-CPU 3.94 s (user 1.85, sys 2.09), runqueue 0.12 s, off-CPU 7.64 s, read 1454 MiB, vcs 49024, nvcs 66
    samples: R|-|- 47.0%; D|pread64|folio_wait_bit_common 18.7%; S|futex|futex_do_wait 13.4%; D|pread64|0 8.7%; D|running|0 6.9%; D|running|folio_wait_bit_common 4.8%
  tid 1117882 qlever-server: on-CPU 0.35 s (user 0.12, sys 0.23), runqueue 0.00 s, off-CPU 11.35 s, read 0 MiB, vcs 3, nvcs 12
    samples: S|futex|futex_do_wait 58.6%; R|-|- 41.1%; D|pread64|folio_wait_bit_common 0.2%
  tid 1117887 qlever-server: on-CPU 0.05 s (user 0.02, sys 0.02), runqueue 0.00 s, off-CPU 11.65 s, read 0 MiB, vcs 2366, nvcs 1
    samples: S|epoll_wait|ep_poll 100.0%
  tid 1117885 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 11.70 s, read 0 MiB, vcs 2, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

## p12 H-vocab-random-label-de-200k warm-r2: wall 4.99 s, ttfb 4.044 s, bytes 19297737, sha 497dacfdffcc, process on-CPU 2.98 s
  tid 1117887 qlever-server: on-CPU 2.55 s (user 1.68, sys 0.87), runqueue 0.01 s, off-CPU 2.44 s, read 0 MiB, vcs 1673, nvcs 28
    samples: R|-|- 72.7%; S|futex|futex_do_wait 27.3%
  tid 1117882 qlever-server: on-CPU 0.37 s (user 0.14, sys 0.23), runqueue 0.00 s, off-CPU 4.62 s, read 0 MiB, vcs 1, nvcs 1
    samples: S|futex|futex_do_wait 57.4%; R|-|- 42.6%
  tid 1117886 qlever-server: on-CPU 0.07 s (user 0.02, sys 0.05), runqueue 0.00 s, off-CPU 4.93 s, read 0 MiB, vcs 2199, nvcs 4
    samples: S|epoll_wait|ep_poll 66.6%; S|futex|futex_do_wait 33.4%
  tid 1118334 qlever-server: on-CPU 0.00 s (user 0.00, sys 0.00), runqueue 0.00 s, off-CPU 4.99 s, read 0 MiB, vcs 70, nvcs 0
    samples: S|futex|futex_do_wait 100.0%

