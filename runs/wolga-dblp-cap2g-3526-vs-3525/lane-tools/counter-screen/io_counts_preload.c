/* LD_PRELOAD counter for counter-screen.py (screening rows, author 2026-09-28 22:xx).
 * Counts libc entry points on the export I/O path: pread/pread64, preadv2
 * (RWF_NOWAIT fast path; also counts RWF_NOWAIT calls and EAGAIN misses),
 * io_uring_enter/io_uring_enter2 and the liburing submit/wait wrappers.
 * Shared file (4096 B, little-endian uint64): magic, pread, preadv2,
 * preadv2_nowait, preadv2_eagain, io_uring_enter, liburing_submit.
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

__attribute__((constructor)) static void init_counts(void) {
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
  ssize_t (*r)(int, void *, size_t, off_t) = dlsym(RTLD_NEXT, "pread");
  return r(fd, b, n, o);
}
ssize_t pread64(int fd, void *b, size_t n, off_t o) {
  INC(pread);
  ssize_t (*r)(int, void *, size_t, off_t) = dlsym(RTLD_NEXT, "pread64");
  return r(fd, b, n, o);
}
ssize_t preadv2(int fd, const struct iovec *v, int c, off_t o, int fl) {
  INC(preadv2);
  if (fl & RWF_NOWAIT) INC(preadv2_nowait);
  ssize_t (*r)(int, const struct iovec *, int, off_t, int) = dlsym(RTLD_NEXT, "preadv2");
  ssize_t x = r(fd, v, c, o, fl);
  if (x < 0 && errno == EAGAIN) INC(preadv2_eagain);
  return x;
}
ssize_t preadv64v2(int fd, const struct iovec *v, int c, off_t o, int fl) {
  INC(preadv2);
  if (fl & RWF_NOWAIT) INC(preadv2_nowait);
  ssize_t (*r)(int, const struct iovec *, int, off_t, int) = dlsym(RTLD_NEXT, "preadv64v2");
  ssize_t x = r(fd, v, c, o, fl);
  if (x < 0 && errno == EAGAIN) INC(preadv2_eagain);
  return x;
}
typedef int (*enter_fn)(unsigned, unsigned, unsigned, unsigned, void *);
int io_uring_enter(unsigned a, unsigned b, unsigned c, unsigned d, void *e) {
  INC(io_uring_enter);
  enter_fn r = (enter_fn)dlsym(RTLD_NEXT, "io_uring_enter");
  return r(a, b, c, d, e);
}
typedef int (*enter2_fn)(unsigned, unsigned, unsigned, unsigned, void *, size_t);
int io_uring_enter2(unsigned a, unsigned b, unsigned c, unsigned d, void *e, size_t s) {
  INC(io_uring_enter);
  enter2_fn r = (enter2_fn)dlsym(RTLD_NEXT, "io_uring_enter2");
  return r(a, b, c, d, e, s);
}
struct io_uring;
int io_uring_submit(struct io_uring *ring) {
  INC(liburing_submit);
  int (*r)(struct io_uring *) = dlsym(RTLD_NEXT, "io_uring_submit");
  return r(ring);
}
int io_uring_submit_and_wait(struct io_uring *ring, unsigned n) {
  INC(liburing_submit);
  int (*r)(struct io_uring *, unsigned) = dlsym(RTLD_NEXT, "io_uring_submit_and_wait");
  return r(ring, n);
}
