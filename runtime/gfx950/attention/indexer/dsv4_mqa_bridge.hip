// SPDX-License-Identifier: MIT
// Module ownership and caller-stream dispatch only; all compute is AMDGCN.
#include <hip/hip_runtime.h>
#include <cstdint>
#include <new>
#include <string>

namespace {
struct Context { hipModule_t module; hipFunction_t function; hipFunction_t small[13]; int device; };
thread_local std::string error;
int fail(const char* message) { error = message; return -1; }
int checked(hipError_t status) {
  if (status != hipSuccess) error = hipGetErrorString(status);
  return static_cast<int>(status);
}
}

extern "C" const char* netra_mqa_error() { return error.c_str(); }
extern "C" int netra_mqa_create(const char* path, void** handle) {
  if (!path || !handle) return fail("path and handle are required");
  *handle = nullptr;
  Context c{};
  hipDeviceProp_t prop{};
  if (int e = checked(hipGetDevice(&c.device))) return e;
  if (int e = checked(hipGetDeviceProperties(&prop, c.device))) return e;
  if (std::string(prop.gcnArchName).substr(0, 6) != "gfx950")
    return fail("requires gfx950");
  if (int e = checked(hipModuleLoad(&c.module, path))) return e;
  int e = checked(hipModuleGetFunction(&c.function, c.module,
      "netra_dsv4_mqa_fp8_h64_d128_gfx950"));
  if (e) { (void)hipModuleUnload(c.module); return e; }
  constexpr const char* small_symbols[] = {
    "netra_dsv4_mqa_fp8_tile16_w1_gfx950",
    "netra_dsv4_mqa_fp8_tile16_w4_gfx950",
    "netra_dsv4_mqa_fp8_pipeline_gfx950",
    "netra_dsv4_mqa_fp8_tile32_gfx950",
    "netra_dsv4_mqa_fp8_pair32_gfx950",
    "netra_dsv4_mqa_fp8_pair32_w4_gfx950",
    "netra_dsv4_mqa_fp8_transposed_gfx950",
    "netra_dsv4_mqa_fp8_pair_prefetch_gfx950",
    "netra_dsv4_mqa_fp8_headsplit_gfx950",
    "netra_dsv4_mqa_fp8_shared_q_gfx950",
    "netra_dsv4_mqa_fp8_preload_pair_gfx950",
    "netra_dsv4_mqa_fp8_preload_shared_gfx950",
    "netra_dsv4_mqa_fp8_shared_prefetch_gfx950",
  };
  for (int i = 0; i < 13; ++i) {
    e = checked(hipModuleGetFunction(&c.small[i], c.module, small_symbols[i]));
    if (e) { (void)hipModuleUnload(c.module); return e; }
  }
  auto* owner = new (std::nothrow) Context(c);
  if (!owner) { (void)hipModuleUnload(c.module); return fail("allocation failed"); }
  *handle = owner;
  return 0;
}

extern "C" int netra_mqa_destroy(void* handle) {
  if (!handle) return 0;
  auto* c = static_cast<Context*>(handle);
  int device;
  if (int e = checked(hipGetDevice(&device))) return e;
  if (device != c->device) return fail("destroy on the owning device");
  if (int e = checked(hipModuleUnload(c->module))) return e;
  delete c;
  return 0;
}

extern "C" int netra_mqa_launch_v2(void* handle, const void* q, const void* kv,
    const void* weights, const void* lengths, const void* pages, void* out,
    uint32_t rows, uint32_t out_stride, uint32_t q_bytes,
    uint32_t w_bytes, uint32_t pages_bytes, uint32_t kv_bytes,
    uint32_t width, uint32_t pages_per_wave, uint32_t mode, hipStream_t stream) {
  if (!handle || !q || !kv || !weights || !lengths || !pages || !out)
    return fail("module and tensor pointers are required");
  if (mode > 13 || !rows || rows > 65535 || !width || width > 262144 ||
      (pages_per_wave != 1 && pages_per_wave != 2 && pages_per_wave != 4 && pages_per_wave != 8) ||
      out_stride < width || out_stride > UINT32_MAX / 4 ||
      q_bytes < 8192 || q_bytes % 16 || w_bytes < 256 || w_bytes % 16 ||
      pages_bytes < ((width + 63) / 64) * 4 || pages_bytes % 4 ||
      kv_bytes < 8448 || kv_bytes % 16)
    return fail("unsupported dimensions or strides");
  if ((reinterpret_cast<uintptr_t>(q) % 16) ||
      (reinterpret_cast<uintptr_t>(kv) % 16) ||
      (reinterpret_cast<uintptr_t>(weights) % 16) ||
      (reinterpret_cast<uintptr_t>(lengths) % 4) ||
      (reinterpret_cast<uintptr_t>(pages) % 4) ||
      (reinterpret_cast<uintptr_t>(out) % 4))
    return fail("unaligned tensor pointer");
  auto* c = static_cast<Context*>(handle);
  int device;
  if (int e = checked(hipGetDevice(&device))) return e;
  if (device != c->device) return fail("launch on the owning device");
  void* args[] = {&q, &kv, &weights, &lengths, &pages, &out,
    &out_stride, &q_bytes, &w_bytes, &pages_bytes, &kv_bytes, &width, &pages_per_wave};
  const uint32_t tile = mode == 7 ? 16 * pages_per_wave : (mode == 6 || mode == 10 || mode == 12 || mode == 13) ? 256 * pages_per_wave :
      (mode == 0 || mode == 3 || mode == 5 || mode == 8 || mode == 9 || mode == 11) ? 64 * pages_per_wave :
      mode == 1 ? 16 : mode == 4 ? 32 : 64;
  const uint32_t threads = (mode == 2 || mode == 6 || mode == 9 || mode == 10 || mode == 12 || mode == 13) ? 256 : 64;
  hipFunction_t fn = mode == 0 ? c->function : c->small[mode - 1];
  return checked(hipModuleLaunchKernel(fn, (width + tile - 1) / tile,
      rows, 1, threads, 1, 1, 0, stream, args, nullptr));
}
