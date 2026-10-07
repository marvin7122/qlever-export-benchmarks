total samples: 11952

| category | share |
|---|---|
| other | 55.8 % |
| page-cache fast path (preadv2, kernel+libc) | 37.8 % |
| other syscalls (futex, mmap, ...) | 4.8 % |
| kernel other | 0.9 % |
| result streaming / HTTP | 0.5 % |
| page faults | 0.2 % |

| # | symbol (self) | share | main call paths |
|---|---|---|---|
| 1 | `qlever-server` | 54.7 % |  (100 %) |
| 2 | `xas_load` | 7.5 % |  (100 %) |
| 3 | `rep_movs_alternative` | 5.2 % |  (100 %) |
| 4 | `filemap_get_read_batch` | 5.0 % |  (100 %) |
| 5 | `filemap_read` | 2.3 % |  (100 %) |
| 6 | `vfs_readv` | 2.1 % |  (100 %) |
| 7 | `srso_safe_ret` | 1.7 % |  (100 %) |
| 8 | `ext4_file_read_iter` | 1.0 % |  (100 %) |
| 9 | `do_preadv` | 0.9 % |  (100 %) |
| 10 | `do_iter_readv_writev` | 0.9 % |  (100 %) |
| 11 | `fdget` | 0.9 % |  (100 %) |
| 12 | `atime_needs_update` | 0.9 % |  (99 %); open64 < _IO_file_open < _IO_file_fopen < fopen (1 %) |
| 13 | `do_syscall_64` | 0.9 % |  (100 %) |
| 14 | `arch_exit_to_user_mode_prepare.isra.0` | 0.8 % |  (100 %) |
| 15 | `copy_page_to_iter` | 0.8 % |  (100 %) |
| 16 | `_copy_to_iter` | 0.8 % |  (100 %) |
| 17 | `entry_SYSCALL_64_after_hwframe` | 0.7 % |  (100 %) |
| 18 | `entry_SYSCALL_64` | 0.7 % |  (100 %) |
| 19 | `aa_file_perm` | 0.7 % |  (100 %) |
| 20 | `__import_iovec` | 0.6 % |  (100 %) |
