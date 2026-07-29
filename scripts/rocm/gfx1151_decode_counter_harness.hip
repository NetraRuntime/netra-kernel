// Launch-only synthetic-shape harness for raw gfx1151 serving kernels.
#include <hip/hip_runtime.h>

#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

extern "C" int netra_mxfp4_sgl_init();
extern "C" const char* netra_mxfp4_sgl_error();
extern "C" int netra_mxfp4_sgl_decode(
    void*, void*, void*, void*, void*, void*, void*, void*, void*, void*,
    void*, void*, void*, void*, void*);

static void check(hipError_t status, const char* what) {
  if (status != hipSuccess) {
    std::fprintf(stderr, "%s: %s\n", what, hipGetErrorString(status));
    std::exit(2);
  }
}

int main(int argc, char** argv) {
  const int iterations = argc > 1 ? std::atoi(argv[1]) : 1;
  if (iterations < 1) return 2;
  hipDeviceProp_t props{};
  check(hipGetDeviceProperties(&props, 0), "hipGetDeviceProperties");
  if (std::string(props.gcnArchName).find("gfx1151") == std::string::npos) {
    std::fprintf(stderr, "expected gfx1151, got %s\n", props.gcnArchName);
    return 3;
  }

  constexpr size_t gate_weight_bytes = 256ull * 1024 * 512;
  constexpr size_t gate_scale_bytes = 256ull * 64 * 512;
  constexpr size_t down_weight_bytes = 256ull * 256 * 2048;
  constexpr size_t down_scale_bytes = 256ull * 16 * 2048;
  const std::vector<size_t> sizes = {
      gate_weight_bytes, gate_scale_bytes, gate_weight_bytes, gate_scale_bytes,
      down_weight_bytes, down_scale_bytes, 2048 * 2, 8 * 4, 8 * 4,
      8 * 512 * 4, 8 * 512 * 4, 8 * 512 * 2, 8 * 2048 * 4, 2048 * 2};
  std::vector<void*> ptrs(sizes.size(), nullptr);
  for (size_t i = 0; i < sizes.size(); ++i) {
    check(hipMalloc(&ptrs[i], sizes[i]), "hipMalloc");
    check(hipMemset(ptrs[i], 0, sizes[i]), "hipMemset");
  }
  int ids[8] = {7, 1, 5, 2, 6, 3, 4, 0};
  float weights[8] = {.125f, .125f, .125f, .125f, .125f, .125f, .125f, .125f};
  check(hipMemcpy(ptrs[7], ids, sizeof(ids), hipMemcpyHostToDevice), "ids copy");
  check(hipMemcpy(ptrs[8], weights, sizeof(weights), hipMemcpyHostToDevice), "weights copy");
  if (netra_mxfp4_sgl_init() != 0) {
    std::fprintf(stderr, "init: %s\n", netra_mxfp4_sgl_error());
    return 4;
  }

  hipEvent_t begin{}, end{};
  check(hipEventCreate(&begin), "event create");
  check(hipEventCreate(&end), "event create");
  check(hipEventRecord(begin), "event record");
  for (int i = 0; i < iterations; ++i) {
    int status = netra_mxfp4_sgl_decode(
        ptrs[0], ptrs[1], ptrs[2], ptrs[3], ptrs[4], ptrs[5], ptrs[6],
        ptrs[7], ptrs[8], ptrs[9], ptrs[10], ptrs[11], ptrs[12], ptrs[13],
        nullptr);
    if (status != 0) {
      std::fprintf(stderr, "decode launch status=%d\n", status);
      return 5;
    }
  }
  check(hipEventRecord(end), "event record");
  check(hipEventSynchronize(end), "event synchronize");
  float elapsed_ms = 0;
  check(hipEventElapsedTime(&elapsed_ms, begin, end), "event elapsed");
  std::printf("target=gfx1151 measurement=measured input=synthetic-shape-identical "
              "iterations=%d total_gpu_ms=%.6f mean_gpu_ms=%.6f\n",
              iterations, elapsed_ms, elapsed_ms / iterations);
  for (void* ptr : ptrs) check(hipFree(ptr), "hipFree");
  check(hipEventDestroy(begin), "event destroy");
  check(hipEventDestroy(end), "event destroy");
  return 0;
}
