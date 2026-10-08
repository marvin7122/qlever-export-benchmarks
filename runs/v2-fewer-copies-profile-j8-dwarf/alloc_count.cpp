// alloc_count.so: LD_PRELOAD shim that counts heap allocation calls and bytes.
//
// It interposes the C allocator (malloc, calloc, realloc, aligned variants,
// free) AND the C++ operator new/delete family. The C++ operators matter for
// QLever: it links jemalloc, whose libjemalloc.so exports its own
// `operator new`, which never goes through the `malloc` symbol, so a
// malloc-only shim misses every `new`/std::string/std::vector allocation.
//
// Signals:
//   SIGUSR1  zero all counters (call after the warm-up query);
//   SIGUSR2  append one line with all counters to $ALLOC_COUNT_OUT
//            (default: stderr).
//
// Build: c++ -O2 -shared -fPIC -o alloc_count.so alloc_count.cpp -ldl
#include <dlfcn.h>
#include <fcntl.h>
#include <unistd.h>

#include <atomic>
#include <csignal>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <initializer_list>
#include <new>

namespace {

using Counter = std::atomic<unsigned long long>;

// One cache line per hot counter group limits false sharing between threads.
struct alignas(64) Counters {
  Counter calls{0};
  Counter bytes{0};
};

Counters cMalloc, cCalloc, cRealloc, cAligned, cNew, cFree, cDelete;
// Size histogram over all allocating calls.
Counters hLe64, hLe1k, hLe64k, hGt64k;

void countSize(size_t n) {
  Counters& h = n <= 64 ? hLe64 : n <= 1024 ? hLe1k : n <= 65536 ? hLe64k : hGt64k;
  h.calls.fetch_add(1, std::memory_order_relaxed);
  h.bytes.fetch_add(n, std::memory_order_relaxed);
}

void count(Counters& c, size_t n) {
  c.calls.fetch_add(1, std::memory_order_relaxed);
  c.bytes.fetch_add(n, std::memory_order_relaxed);
  countSize(n);
}

// dlsym itself may allocate: serve those early calls from a static buffer.
alignas(64) char bootBuf[1 << 20];
std::atomic<size_t> bootUsed{0};
bool inBoot(void* p) {
  return p >= static_cast<void*>(bootBuf) &&
         p < static_cast<void*>(bootBuf + sizeof(bootBuf));
}

using MallocFn = void* (*)(size_t);
using CallocFn = void* (*)(size_t, size_t);
using ReallocFn = void* (*)(void*, size_t);
using FreeFn = void (*)(void*);
using AlignedAllocFn = void* (*)(size_t, size_t);
using PosixMemalignFn = int (*)(void**, size_t, size_t);

MallocFn realMalloc = nullptr;
CallocFn realCalloc = nullptr;
ReallocFn realRealloc = nullptr;
FreeFn realFree = nullptr;
AlignedAllocFn realAlignedAlloc = nullptr;
PosixMemalignFn realPosixMemalign = nullptr;
std::atomic<bool> resolving{false};

void resolve() {
  if (realMalloc != nullptr) return;
  resolving = true;
  realCalloc = reinterpret_cast<CallocFn>(dlsym(RTLD_NEXT, "calloc"));
  realRealloc = reinterpret_cast<ReallocFn>(dlsym(RTLD_NEXT, "realloc"));
  realFree = reinterpret_cast<FreeFn>(dlsym(RTLD_NEXT, "free"));
  realAlignedAlloc =
      reinterpret_cast<AlignedAllocFn>(dlsym(RTLD_NEXT, "aligned_alloc"));
  realPosixMemalign =
      reinterpret_cast<PosixMemalignFn>(dlsym(RTLD_NEXT, "posix_memalign"));
  realMalloc = reinterpret_cast<MallocFn>(dlsym(RTLD_NEXT, "malloc"));
  resolving = false;
}

void* bootAlloc(size_t n) {
  size_t off = bootUsed.fetch_add((n + 15) & ~size_t{15});
  if (off + n > sizeof(bootBuf)) {
    static const char m[] = "[alloc-count] boot buffer exhausted\n";
    (void)!write(2, m, sizeof(m) - 1);
    std::abort();
  }
  return bootBuf + off;
}

void reset(int) {
  for (Counters* c : {&cMalloc, &cCalloc, &cRealloc, &cAligned, &cNew, &cFree,
                      &cDelete, &hLe64, &hLe1k, &hLe64k, &hGt64k}) {
    c->calls.store(0);
    c->bytes.store(0);
  }
}

unsigned long long n(const Counters& c) { return c.calls.load(); }
unsigned long long b(const Counters& c) { return c.bytes.load(); }

void dump(int) {
  char line[1024];
  const unsigned long long allocCalls =
      n(cMalloc) + n(cCalloc) + n(cRealloc) + n(cAligned) + n(cNew);
  const unsigned long long allocBytes =
      b(cMalloc) + b(cCalloc) + b(cRealloc) + b(cAligned) + b(cNew);
  int len = snprintf(
      line, sizeof(line),
      "alloc_calls=%llu alloc_bytes=%llu malloc=%llu/%llu calloc=%llu/%llu "
      "realloc=%llu/%llu aligned=%llu/%llu new=%llu/%llu free=%llu "
      "delete=%llu le64=%llu/%llu le1k=%llu/%llu le64k=%llu/%llu "
      "gt64k=%llu/%llu\n",
      allocCalls, allocBytes, n(cMalloc), b(cMalloc), n(cCalloc), b(cCalloc),
      n(cRealloc), b(cRealloc), n(cAligned), b(cAligned), n(cNew), b(cNew),
      n(cFree), n(cDelete), n(hLe64), b(hLe64), n(hLe1k), b(hLe1k),
      n(hLe64k), b(hLe64k), n(hGt64k), b(hGt64k));
  const char* path = getenv("ALLOC_COUNT_OUT");
  int fd = 2;
  if (path != nullptr) fd = open(path, O_WRONLY | O_CREAT | O_APPEND, 0644);
  if (fd >= 0 && len > 0) (void)!write(fd, line, static_cast<size_t>(len));
  if (fd > 2) close(fd);
}

__attribute__((constructor)) void init() {
  resolve();
  struct sigaction sa {};
  sa.sa_flags = SA_RESTART;
  sigemptyset(&sa.sa_mask);
  sa.sa_handler = reset;
  sigaction(SIGUSR1, &sa, nullptr);
  sa.sa_handler = dump;
  sigaction(SIGUSR2, &sa, nullptr);
}

void* newImpl(size_t size, size_t align, bool nothrow) {
  if (realMalloc == nullptr) resolve();
  count(cNew, size);
  void* p = align <= alignof(std::max_align_t)
                ? realMalloc(size == 0 ? 1 : size)
                : realAlignedAlloc(align, (size + align - 1) / align * align);
  if (p == nullptr && !nothrow) throw std::bad_alloc{};
  return p;
}

void deleteImpl(void* p) {
  if (p == nullptr || inBoot(p)) return;
  if (realFree == nullptr) resolve();
  cDelete.calls.fetch_add(1, std::memory_order_relaxed);
  realFree(p);
}

}  // namespace

extern "C" {

void* malloc(size_t size) {
  if (realMalloc == nullptr) {
    if (resolving) return bootAlloc(size);
    resolve();
  }
  count(cMalloc, size);
  return realMalloc(size);
}

void* calloc(size_t num, size_t size) {
  if (realCalloc == nullptr) {
    // dlsym's own calloc during resolution: zeroed boot memory.
    if (resolving || realMalloc == nullptr) {
      void* p = bootAlloc(num * size);
      memset(p, 0, num * size);
      return p;
    }
    resolve();
  }
  count(cCalloc, num * size);
  return realCalloc(num, size);
}

void* realloc(void* p, size_t size) {
  if (realRealloc == nullptr) resolve();
  if (inBoot(p)) {
    count(cMalloc, size);
    void* q = realMalloc(size);
    if (q != nullptr) memcpy(q, p, size);  // boot blocks are never shrunk
    return q;
  }
  count(cRealloc, size);
  return realRealloc(p, size);
}

void* aligned_alloc(size_t align, size_t size) {
  if (realAlignedAlloc == nullptr) resolve();
  count(cAligned, size);
  return realAlignedAlloc(align, size);
}

int posix_memalign(void** out, size_t align, size_t size) {
  if (realPosixMemalign == nullptr) resolve();
  count(cAligned, size);
  return realPosixMemalign(out, align, size);
}

void free(void* p) {
  if (p == nullptr || inBoot(p)) return;
  if (realFree == nullptr) resolve();
  cFree.calls.fetch_add(1, std::memory_order_relaxed);
  realFree(p);
}

}  // extern "C"

void* operator new(size_t s) { return newImpl(s, 0, false); }
void* operator new[](size_t s) { return newImpl(s, 0, false); }
void* operator new(size_t s, const std::nothrow_t&) noexcept {
  return newImpl(s, 0, true);
}
void* operator new[](size_t s, const std::nothrow_t&) noexcept {
  return newImpl(s, 0, true);
}
void* operator new(size_t s, std::align_val_t a) {
  return newImpl(s, static_cast<size_t>(a), false);
}
void* operator new[](size_t s, std::align_val_t a) {
  return newImpl(s, static_cast<size_t>(a), false);
}
void operator delete(void* p) noexcept { deleteImpl(p); }
void operator delete[](void* p) noexcept { deleteImpl(p); }
void operator delete(void* p, size_t) noexcept { deleteImpl(p); }
void operator delete[](void* p, size_t) noexcept { deleteImpl(p); }
void operator delete(void* p, std::align_val_t) noexcept { deleteImpl(p); }
void operator delete[](void* p, std::align_val_t) noexcept { deleteImpl(p); }
void operator delete(void* p, size_t, std::align_val_t) noexcept {
  deleteImpl(p);
}
void operator delete[](void* p, size_t, std::align_val_t) noexcept {
  deleteImpl(p);
}
void operator delete(void* p, const std::nothrow_t&) noexcept { deleteImpl(p); }
void operator delete[](void* p, const std::nothrow_t&) noexcept {
  deleteImpl(p);
}
