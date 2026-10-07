/* LD_PRELOAD I/O entry counter for io_screen.py (2026-10-06).
 * Same shared-file layout as incoming/counter-screen/io_counts_preload.c
 * (4096 B, little-endian uint64): magic, pread, preadv2, preadv2_nowait,
 * preadv2_eagain, io_uring_enter, liburing_submit.
 * Difference: the real functions are resolved once in the constructor, not
 * with dlsym() on every call, so the counter does not add a dlsym lookup to
 * each of the ~10^7 fast-path preadv2 calls of a timed run.
 * liburing issues io_uring_enter as a raw syscall, so that field stays 0;
 * ring traffic shows in liburing_submit.
 * Path from QLEVER_IO_COUNT_FILE. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/uio.h>
#include <unistd.h>

#define MAGIC 0x514c4556494f4332ull /* "QLEVIOC2" */
struct counts {
  uint64_t magic;
  atomic_uint_least64_t pread, preadv2, preadv2_nowait, preadv2_eagain,
      io_uring_enter, liburing_submit;
};
static struct counts *g;
#define INC(f) do { if (g) atomic_fetch_add_explicit(&g->f, 1, memory_order_relaxed); } while (0)

typedef ssize_t (*pread_fn)(int, void *, size_t, off_t);
typedef ssize_t (*preadv2_fn)(int, const struct iovec *, int, off_t, int);
struct io_uring;
typedef int (*submit_fn)(struct io_uring *);
typedef int (*submit_wait_fn)(struct io_uring *, unsigned);
static pread_fn r_pread, r_pread64;
static preadv2_fn r_preadv2, r_preadv64v2;
static submit_fn r_submit;
static submit_wait_fn r_submit_wait;

static void resolve(void) {
  r_pread = (pread_fn)dlsym(RTLD_NEXT, "pread");
  r_pread64 = (pread_fn)dlsym(RTLD_NEXT, "pread64");
  r_preadv2 = (preadv2_fn)dlsym(RTLD_NEXT, "preadv2");
  r_preadv64v2 = (preadv2_fn)dlsym(RTLD_NEXT, "preadv64v2");
  r_submit = (submit_fn)dlsym(RTLD_NEXT, "io_uring_submit");
  r_submit_wait = (submit_wait_fn)dlsym(RTLD_NEXT, "io_uring_submit_and_wait");
}

__attribute__((constructor)) static void init_counts(void) {
  resolve();
  const char *p = getenv("QLEVER_IO_COUNT_FILE");
  if (!p || !*p) return;
  int fd = open(p, O_RDWR);
  if (fd < 0) return;
  void *m = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  close(fd);
  if (m == MAP_FAILED) return;
  g = m;
  g->magic = MAGIC;
}

ssize_t pread(int fd, void *b, size_t n, off_t o) {
  INC(pread);
  if (!r_pread) resolve();
  return r_pread(fd, b, n, o);
}
ssize_t pread64(int fd, void *b, size_t n, off_t o) {
  INC(pread);
  if (!r_pread64) resolve();
  return r_pread64(fd, b, n, o);
}
static ssize_t count_v2(preadv2_fn r, int fd, const struct iovec *v, int c, off_t o, int fl) {
  INC(preadv2);
  if (fl & RWF_NOWAIT) INC(preadv2_nowait);
  ssize_t x = r(fd, v, c, o, fl);
  if (x < 0 && errno == EAGAIN) INC(preadv2_eagain);
  return x;
}
ssize_t preadv2(int fd, const struct iovec *v, int c, off_t o, int fl) {
  if (!r_preadv2) resolve();
  return count_v2(r_preadv2, fd, v, c, o, fl);
}
ssize_t preadv64v2(int fd, const struct iovec *v, int c, off_t o, int fl) {
  if (!r_preadv64v2) resolve();
  return count_v2(r_preadv64v2, fd, v, c, o, fl);
}
int io_uring_submit(struct io_uring *ring) {
  INC(liburing_submit);
  if (!r_submit) resolve();
  return r_submit(ring);
}
int io_uring_submit_and_wait(struct io_uring *ring, unsigned n) {
  INC(liburing_submit);
  if (!r_submit_wait) resolve();
  return r_submit_wait(ring, n);
}
