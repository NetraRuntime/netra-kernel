// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <cstdint>

namespace {
struct Loaded { hipModule_t module{}; hipFunction_t function{}; };
Loaded baseline, candidate;
struct alignas(8) Args {
  void* q; void* k; void* v; void* h; void* g; void* o;
  void* cu_seqlens; void* chunk_indices; float scale; uint32_t tokens;
};
static_assert(sizeof(Args) == 72);
Args baseline_args{}, candidate_args{};
int load(Loaded& loaded, const char* path, const char* symbol) {
  hipError_t status = hipModuleLoad(&loaded.module, path);
  if (status != hipSuccess) return status;
  return hipModuleGetFunction(&loaded.function, loaded.module, symbol);
}
int launch(Loaded& loaded, Args& args, hipStream_t stream) {
  if (!loaded.function || args.tokens != 8192) return hipErrorInvalidValue;
  size_t size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
                    HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
                    HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(loaded.function, 4, 128, 32, 128, 1, 1,
                               0, stream, nullptr, config);
}
}
extern "C" int netra_gdn_chunk_o_dual_init(
    const char* baseline_path, const char* candidate_path,
    const char* candidate_symbol) {
  int status = load(baseline, baseline_path, "gdn_chunk_o_bv32_gfx1151");
  if (status) return status;
  return load(candidate, candidate_path, candidate_symbol);
}
extern "C" int netra_gdn_chunk_o_dual_launch(
    int which, void* q, void* k, void* v, void* h, void* g, void* o,
    void* cu_seqlens, void* chunk_indices, float scale, uint32_t tokens,
    hipStream_t stream) {
  Args& args = which ? candidate_args : baseline_args;
  args = Args{q,k,v,h,g,o,cu_seqlens,chunk_indices,scale,tokens};
  return launch(which ? candidate : baseline, args, stream);
}
