#include <hip/hip_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <vector>

namespace {
struct alignas(8) Args {
  void* expert;
  void* positions;
  void* weights;
  void* output;
};

void check(hipError_t status, const char* what) {
  if (status != hipSuccess) {
    std::fprintf(stderr, "%s: %s\n", what, hipGetErrorString(status));
    std::exit(1);
  }
}
}

int main(int argc, char** argv) {
  if (argc < 2 || argc > 3) {
    std::fprintf(stderr, "usage: %s KERNEL.hsaco [iterations]\n", argv[0]);
    return 2;
  }
  const unsigned tokens = 8192;
  const unsigned hidden = 2048;
  const unsigned topk = 8;
  const int iterations = argc == 3 ? std::atoi(argv[2]) : 1;
  hipModule_t module{};
  hipFunction_t kernel{};
  check(hipModuleLoad(&module, argv[1]), "hipModuleLoad");
  check(hipModuleGetFunction(
      &kernel, module, "expert_weighted_reduce_top8_fp64_gfx1151"),
      "hipModuleGetFunction");

  void* expert{};
  void* positions{};
  void* weights{};
  void* output{};
  const size_t expert_bytes =
      static_cast<size_t>(tokens) * topk * hidden * sizeof(float);
  const size_t positions_bytes =
      static_cast<size_t>(tokens) * topk * sizeof(unsigned);
  const size_t output_bytes =
      static_cast<size_t>(tokens) * hidden * sizeof(unsigned short);
  check(hipMalloc(&expert, expert_bytes), "hipMalloc expert");
  check(hipMalloc(&positions, positions_bytes), "hipMalloc positions");
  check(hipMalloc(&weights, positions_bytes), "hipMalloc weights");
  check(hipMalloc(&output, output_bytes), "hipMalloc output");
  check(hipMemset(expert, 0, expert_bytes), "hipMemset expert");

  std::vector<unsigned> host_positions(tokens * topk);
  std::vector<float> host_weights(tokens * topk, 0.125f);
  for (size_t i = 0; i < host_positions.size(); ++i)
    host_positions[i] = static_cast<unsigned>(i);
  check(hipMemcpy(positions, host_positions.data(), positions_bytes,
                  hipMemcpyHostToDevice), "hipMemcpy positions");
  check(hipMemcpy(weights, host_weights.data(), positions_bytes,
                  hipMemcpyHostToDevice), "hipMemcpy weights");

  Args args{expert, positions, weights, output};
  size_t args_size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
                    HIP_LAUNCH_PARAM_BUFFER_SIZE, &args_size,
                    HIP_LAUNCH_PARAM_END};
  for (int i = 0; i < iterations; ++i) {
    check(hipModuleLaunchKernel(kernel, 8, tokens, 1, 256, 1, 1, 0,
                               nullptr, nullptr, config),
          "hipModuleLaunchKernel");
  }
  check(hipDeviceSynchronize(), "hipDeviceSynchronize");
  std::printf("gfx1151 measured expert reduce tokens=%u hidden=%u topk=%u iterations=%d\n",
              tokens, hidden, topk, iterations);
  check(hipFree(output), "hipFree output");
  check(hipFree(weights), "hipFree weights");
  check(hipFree(positions), "hipFree positions");
  check(hipFree(expert), "hipFree expert");
  check(hipModuleUnload(module), "hipModuleUnload");
  return 0;
}
