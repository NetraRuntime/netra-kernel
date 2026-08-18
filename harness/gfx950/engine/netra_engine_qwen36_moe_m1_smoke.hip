// SPDX-License-Identifier: MIT
#include "../../../runtime/gfx950/engine/netra_engine.h"

#include <hip/hip_runtime.h>

#include <cstdint>
#include <iostream>
#include <vector>

namespace {

void check_hip(hipError_t status, const char* operation) {
  if (status != hipSuccess) {
    std::cerr << operation << ": " << hipGetErrorString(status) << "\n";
    std::exit(1);
  }
}

void* zero_buffer(size_t bytes, std::vector<void*>* allocations) {
  void* pointer = nullptr;
  check_hip(hipMalloc(&pointer, bytes), "hipMalloc");
  check_hip(hipMemset(pointer, 0, bytes), "hipMemset");
  allocations->push_back(pointer);
  return pointer;
}

void bind(netra_engine_t* engine, uint32_t operation, uint32_t argument,
          void* pointer) {
  const netra_status_t status =
      netra_engine_bind(engine, 0, operation, argument, pointer);
  if (status != NETRA_STATUS_OK) {
    std::cerr << "bind " << operation << ":" << argument << " failed: "
              << netra_engine_last_error(engine) << "\n";
    std::exit(1);
  }
}

}  // namespace

int main(int argc, char** argv) {
  if (argc != 2) {
    std::cerr << "usage: " << argv[0] << " ENGINE_DIR\n";
    return 2;
  }
  std::vector<void*> allocations;
  void* hidden = zero_buffer(1ULL * 2048, &allocations);
  void* hidden_scale = zero_buffer(1ULL * 16 * 4, &allocations);
  void* w13 = zero_buffer(257ULL * 1024 * 2048, &allocations);
  void* w13_scale = zero_buffer(257ULL * 8 * 16 * 4, &allocations);
  void* topk_ids = zero_buffer(1ULL * 9 * 4, &allocations);
  void* gate_up_f32 = zero_buffer(9ULL * 1024 * 4, &allocations);
  void* activation_fp8 = zero_buffer(9ULL * 512, &allocations);
  void* activation_scale = zero_buffer(9ULL * 4 * 4, &allocations);
  void* w2 = zero_buffer(257ULL * 2048 * 512, &allocations);
  void* w2_scale = zero_buffer(257ULL * 16 * 4 * 4, &allocations);
  void* topk_weights = zero_buffer(1ULL * 9 * 4, &allocations);
  void* output = zero_buffer(1ULL * 2048 * 2, &allocations);

  netra_engine_options_t options{sizeof(options), 0, 1};
  netra_engine_t* engine = nullptr;
  netra_status_t status = netra_engine_create(argv[1], &options, &engine);
  if (status != NETRA_STATUS_OK) {
    std::cerr << "create failed: " << static_cast<int>(status) << "\n";
    return 1;
  }
  bind(engine, 0, 0, hidden);
  bind(engine, 0, 1, hidden_scale);
  bind(engine, 0, 2, w13);
  bind(engine, 0, 3, w13_scale);
  bind(engine, 0, 4, topk_ids);
  bind(engine, 0, 5, gate_up_f32);
  bind(engine, 1, 0, gate_up_f32);
  bind(engine, 1, 1, activation_fp8);
  bind(engine, 1, 2, activation_scale);
  bind(engine, 2, 0, activation_fp8);
  bind(engine, 2, 1, activation_scale);
  bind(engine, 2, 2, w2);
  bind(engine, 2, 3, w2_scale);
  bind(engine, 2, 4, topk_weights);
  bind(engine, 2, 5, topk_ids);
  bind(engine, 2, 6, output);
  status = netra_engine_finalize_bindings(engine);
  if (status != NETRA_STATUS_OK) {
    std::cerr << "finalize bindings failed: " << netra_engine_last_error(engine)
              << "\n";
    return 1;
  }

  hipStream_t stream = nullptr;
  check_hip(hipStreamCreate(&stream), "hipStreamCreate");
  netra_launch_shape_t shape{1, 1, 0, 1};
  for (uint32_t operation = 0; operation < 3; ++operation) {
    status = netra_engine_launch_operation(engine, 0, operation, &shape, stream);
    if (status != NETRA_STATUS_OK) {
      std::cerr << "operation " << operation << " failed: "
                << netra_engine_last_error(engine) << "\n";
      return 1;
    }
    hipError_t sync_status = hipStreamSynchronize(stream);
    if (sync_status != hipSuccess) {
      std::cerr << "operation " << operation << " sync failed: "
                << hipGetErrorString(sync_status) << "\n";
      return 1;
    }
  }
  hipGraph_t graph = nullptr;
  hipGraphExec_t graph_exec = nullptr;
  check_hip(hipStreamBeginCapture(stream, hipStreamCaptureModeThreadLocal),
            "hipStreamBeginCapture");
  for (uint32_t operation = 0; operation < 3; ++operation) {
    status =
        netra_engine_launch_operation(engine, 0, operation, &shape, stream);
    if (status != NETRA_STATUS_OK) {
      std::cerr << "captured operation " << operation << " failed: "
                << netra_engine_last_error(engine) << "\n";
      return 1;
    }
  }
  check_hip(hipStreamEndCapture(stream, &graph), "hipStreamEndCapture");
  check_hip(hipGraphInstantiate(&graph_exec, graph, nullptr, nullptr, 0),
            "hipGraphInstantiate");
  for (int iteration = 0; iteration < 20; ++iteration) {
    check_hip(hipGraphLaunch(graph_exec, stream), "hipGraphLaunch");
  }
  check_hip(hipStreamSynchronize(stream), "hipStreamSynchronize");
  std::vector<uint16_t> host_output(2048);
  check_hip(hipMemcpy(host_output.data(), output, host_output.size() * 2,
                      hipMemcpyDeviceToHost), "hipMemcpy");
  for (uint16_t value : host_output) {
    if (value != 0) {
      std::cerr << "zero-input graph produced nonzero BF16 output\n";
      return 1;
    }
  }
  check_hip(hipGraphExecDestroy(graph_exec), "hipGraphExecDestroy");
  check_hip(hipGraphDestroy(graph), "hipGraphDestroy");
  check_hip(hipStreamDestroy(stream), "hipStreamDestroy");
  if (netra_engine_destroy(engine) != NETRA_STATUS_OK) return 1;
  for (void* pointer : allocations) check_hip(hipFree(pointer), "hipFree");
  std::cout << "Qwen3.6 M1 golden operation-subset graph replay passed "
               "(20/20, zero oracle)\n";
  return 0;
}
