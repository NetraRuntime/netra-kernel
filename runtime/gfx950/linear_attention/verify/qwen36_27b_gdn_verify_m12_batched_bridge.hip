// SPDX-License-Identifier: MIT
// Qwen3.6-27B HV48 module management and caller-stream dispatch only.
#include "qwen36_27b_gdn_verify_m12_batched_bridge.h"

#include <hip/hip_runtime.h>

#include <algorithm>
#include <array>
#include <mutex>
#include <string>

namespace {

std::mutex module_mutex;
hipModule_t precompute_module = nullptr;
hipModule_t core_module = nullptr;
hipFunction_t precompute_function = nullptr;
hipFunction_t core_function = nullptr;
hipModule_t state_replay_module = nullptr;
hipFunction_t state_replay_function = nullptr;
hipModule_t qkvz_conv_t8_module = nullptr;
hipFunction_t qkvz_conv_t8_function = nullptr;
std::string loaded_precompute_path;
std::string loaded_core_path;
std::string loaded_state_replay_path;
std::string loaded_qkvz_conv_t8_path;
// Verification block size: 12 (promoted) or 8 (block-8 experiment). Affects
// only the precompute grid (tokens x 16 QK heads per request); the core and
// replay grids are token-count independent (HV x value tiles).
unsigned int block_tokens = 12;
thread_local std::string last_error;

int fail(const char* operation, hipError_t error) {
  last_error = std::string(operation) + ": " + hipGetErrorString(error);
  return static_cast<int>(error);
}

int fail_message(const std::string& message) {
  last_error = message;
  return -1;
}

hipError_t get_function_with_legacy_fallback(
    hipFunction_t* function,
    hipModule_t module,
    const char* model_independent_symbol,
    const char* legacy_symbol) {
  hipError_t error =
      hipModuleGetFunction(function, module, model_independent_symbol);
  if (error == hipSuccess) return error;
  if (error != hipErrorNotFound) return error;
  // The legacy artifact is an initialization-only compatibility path. Clear
  // the expected model-independent-symbol miss before returning to PyTorch;
  // otherwise HIP reports the stale miss at the caller's next runtime API.
  (void)hipGetLastError();
  return hipModuleGetFunction(function, module, legacy_symbol);
}

void clear_modules() {
  if (qkvz_conv_t8_module != nullptr) (void)hipModuleUnload(qkvz_conv_t8_module);
  if (state_replay_module != nullptr) (void)hipModuleUnload(state_replay_module);
  if (core_module != nullptr) (void)hipModuleUnload(core_module);
  if (precompute_module != nullptr) (void)hipModuleUnload(precompute_module);
  precompute_module = nullptr;
  core_module = nullptr;
  state_replay_module = nullptr;
  state_replay_function = nullptr;
  loaded_state_replay_path.clear();
  qkvz_conv_t8_module = nullptr;
  qkvz_conv_t8_function = nullptr;
  loaded_qkvz_conv_t8_path.clear();
  precompute_function = nullptr;
  core_function = nullptr;
  loaded_precompute_path.clear();
  loaded_core_path.clear();
}

int validate_device() {
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(
        std::string("Qwen3.6-27B GDN verify requires gfx950; got ") +
        properties.gcnArchName);
  return 0;
}

}  // namespace

extern "C" int netra_qwen36_gdn_verify_m12_batched_load(
    const char* precompute_hsaco_path,
    const char* core_hsaco_path) {
  if (precompute_hsaco_path == nullptr || precompute_hsaco_path[0] == '\0' ||
      core_hsaco_path == nullptr || core_hsaco_path[0] == '\0')
    return fail_message("both hsaco paths must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (precompute_module != nullptr || core_module != nullptr) {
    if (loaded_precompute_path == precompute_hsaco_path &&
        loaded_core_path == core_hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("different Qwen3.6-27B GDN modules are already loaded");
  }
  if (validate_device() != 0) return -1;
  hipError_t error = hipModuleLoad(&precompute_module, precompute_hsaco_path);
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleLoad(precompute)", error);
  }
  error = hipModuleGetFunction(
      &precompute_function, precompute_module,
      "qwen36_27b_gdn_verify_m12_batched_precompute_gfx950");
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleGetFunction(precompute)", error);
  }
  error = hipModuleLoad(&core_module, core_hsaco_path);
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleLoad(core)", error);
  }
  error = get_function_with_legacy_fallback(
      &core_function, core_module,
      "netra_gdn_verify_t8_bv16_hv48_k0_bf16_state_gfx950",
      "qwen36_27b_gdn_verify_m12_batched_precomputed_bv16_gfx950");
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleGetFunction(core)", error);
  }
  loaded_precompute_path = precompute_hsaco_path;
  loaded_core_path = core_hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_verify_m12_batched_load_wavegroup_variants(
    const char*, const char*, const char*, const char*) {
  return fail_message(
      "Qwen3.6-27B HV48 verification currently supports one wave only");
}

extern "C" int netra_gdn_qkvz_conv_t8_d10240_load(
    const char* qkvz_conv_hsaco_path) {
  if (qkvz_conv_hsaco_path == nullptr || qkvz_conv_hsaco_path[0] == '\0')
    return fail_message("QKVZ convolution hsaco path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (qkvz_conv_t8_module != nullptr) {
    if (loaded_qkvz_conv_t8_path == qkvz_conv_hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different T=8 QKVZ convolution module is loaded");
  }
  if (validate_device() != 0) return -1;
  hipError_t error = hipModuleLoad(
      &qkvz_conv_t8_module, qkvz_conv_hsaco_path);
  if (error != hipSuccess) return fail("hipModuleLoad(qkvz conv T=8)", error);
  error = hipModuleGetFunction(
      &qkvz_conv_t8_function, qkvz_conv_t8_module,
      "netra_gdn_qkvz_conv_t8_d10240_gfx950");
  if (error != hipSuccess) {
    (void)hipModuleUnload(qkvz_conv_t8_module);
    qkvz_conv_t8_module = nullptr;
    qkvz_conv_t8_function = nullptr;
    return fail("hipModuleGetFunction(qkvz conv T=8)", error);
  }
  loaded_qkvz_conv_t8_path = qkvz_conv_hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_gdn_qkvz_conv_t8_d10240_launch(
    const void* qkvz_bf16,
    const void* weight_bf16,
    void* state_bf16,
    const void* state_indices_i32,
    void* intermediate_window_bf16,
    const void* intermediate_indices_i32,
    void* output_bf16,
    uint32_t batch_size,
    hipStream_t stream) {
  if (qkvz_conv_t8_function == nullptr)
    return fail_message("T=8 QKVZ convolution module is not loaded");
  const std::array<const void*, 7> pointers = {
      qkvz_bf16, weight_bf16, state_bf16, state_indices_i32,
      intermediate_window_bf16, intermediate_indices_i32, output_bf16};
  if (std::any_of(pointers.begin(), pointers.end(),
                  [](const void* pointer) { return pointer == nullptr; }))
    return fail_message("T=8 QKVZ convolution pointers must be nonnull");
  if (batch_size == 0 || batch_size > 256)
    return fail_message("T=8 QKVZ convolution batch must be in [1,256]");

  void* qkvz_pointer = const_cast<void*>(qkvz_bf16);
  void* weight_pointer = const_cast<void*>(weight_bf16);
  void* state_indices_pointer = const_cast<void*>(state_indices_i32);
  void* intermediate_indices_pointer =
      const_cast<void*>(intermediate_indices_i32);
  void* arguments[] = {
      &qkvz_pointer,
      &weight_pointer,
      &state_bf16,
      &state_indices_pointer,
      &intermediate_window_bf16,
      &intermediate_indices_pointer,
      &output_bf16,
      &batch_size,
  };
  const hipError_t error = hipModuleLaunchKernel(
      qkvz_conv_t8_function, 40, batch_size, 1, 256, 1, 1, 0, stream,
      arguments, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(qkvz conv T=8)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_verify_m12_batched_launch_precomputed(
    const void* q_normalized_f32,
    const void* k_normalized_f32,
    const void* v_bf16,
    const void* decay_f32,
    const void* beta_f32,
    void* output_bf16,
    const void* initial_state_bf16,
    void* intermediate_state_bf16,
    const void* initial_state_indices_i32,
    const void* intermediate_state_indices_i32,
    uint32_t stride_v,
    uint32_t batch_size,
    uint32_t state_capacity,
    hipStream_t stream) {
  if (core_function == nullptr)
    return fail_message("Qwen3.6-27B GDN core module is not loaded");
  const std::array<const void*, 10> pointers = {
      q_normalized_f32, k_normalized_f32, v_bf16, decay_f32, beta_f32,
      output_bf16, initial_state_bf16, intermediate_state_bf16,
      initial_state_indices_i32, intermediate_state_indices_i32,
  };
  if (std::any_of(pointers.begin(), pointers.end(),
                  [](const void* pointer) { return pointer == nullptr; }))
    return fail_message("precomputed GDN launch pointers must be nonnull");
  if (stride_v < 6144 || batch_size == 0 || batch_size > 256 ||
      state_capacity == 0)
    return fail_message("invalid precomputed Qwen3.6-27B GDN launch shape");

  void* q_pointer = const_cast<void*>(q_normalized_f32);
  void* k_pointer = const_cast<void*>(k_normalized_f32);
  void* v_pointer = const_cast<void*>(v_bf16);
  void* decay_pointer = const_cast<void*>(decay_f32);
  void* beta_pointer = const_cast<void*>(beta_f32);
  void* initial_pointer = const_cast<void*>(initial_state_bf16);
  void* initial_indices_pointer = const_cast<void*>(initial_state_indices_i32);
  void* intermediate_indices_pointer =
      const_cast<void*>(intermediate_state_indices_i32);
  void* core_arguments[] = {
      &q_pointer, &k_pointer, &v_pointer, &decay_pointer, &beta_pointer,
      &output_bf16, &initial_pointer, &intermediate_state_bf16,
      &initial_indices_pointer, &intermediate_indices_pointer, &stride_v,
      &state_capacity,
  };
  hipError_t error = hipModuleLaunchKernel(
      core_function, batch_size * 384, 1, 1, 64, 1, 1, 0, stream,
      core_arguments, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(core precomputed)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_verify_m12_batched_launch_precompute(
    const void* A_log_f32,
    const void* a_bf16,
    const void* dt_bias_bf16,
    const void* q_bf16,
    const void* k_bf16,
    const void* b_bf16,
    void* q_normalized_f32,
    void* k_normalized_f32,
    void* decay_f32,
    void* beta_f32,
    uint32_t stride_q,
    uint32_t stride_k,
    uint32_t stride_a,
    uint32_t stride_b,
    uint32_t batch_size,
    hipStream_t stream) {
  if (precompute_function == nullptr)
    return fail_message("Qwen3.6-27B GDN precompute module is not loaded");
  const std::array<const void*, 10> pointers = {
      A_log_f32, a_bf16, dt_bias_bf16, q_bf16, k_bf16, b_bf16,
      q_normalized_f32, k_normalized_f32, decay_f32, beta_f32,
  };
  if (std::any_of(pointers.begin(), pointers.end(),
                  [](const void* pointer) { return pointer == nullptr; }))
    return fail_message("GDN precompute launch pointers must be nonnull");
  if (stride_q < 2048 || stride_k < 2048 || stride_a < 48 ||
      stride_b < 48 || batch_size == 0 || batch_size > 256)
    return fail_message("invalid Qwen3.6-27B GDN precompute shape");

  void* A_log_pointer = const_cast<void*>(A_log_f32);
  void* a_pointer = const_cast<void*>(a_bf16);
  void* dt_bias_pointer = const_cast<void*>(dt_bias_bf16);
  void* q_pointer = const_cast<void*>(q_bf16);
  void* k_pointer = const_cast<void*>(k_bf16);
  void* b_pointer = const_cast<void*>(b_bf16);
  void* arguments[] = {
      &A_log_pointer, &a_pointer, &dt_bias_pointer, &q_pointer, &k_pointer,
      &b_pointer, &q_normalized_f32, &k_normalized_f32, &decay_f32,
      &beta_f32, &stride_q, &stride_k, &stride_a, &stride_b,
  };
  hipError_t error = hipModuleLaunchKernel(
      precompute_function, batch_size * block_tokens * 16, 1, 1, 64, 1, 1, 0, stream,
      arguments, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(precompute only)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_verify_m12_batched_launch(
    void* output_bf16,
    const void* A_log_f32,
    const void* a_bf16,
    const void* dt_bias_bf16,
    const void* q_bf16,
    const void* k_bf16,
    const void* v_bf16,
    const void* b_bf16,
    const void* initial_state_bf16,
    const void* initial_state_indices_i32,
    void* intermediate_state_bf16,
    const void* intermediate_state_indices_i32,
    void* q_normalized_f32,
    void* k_normalized_f32,
    void* decay_f32,
    void* beta_f32,
    uint32_t stride_q,
    uint32_t stride_k,
    uint32_t stride_v,
    uint32_t stride_a,
    uint32_t stride_b,
    uint32_t batch_size,
    uint32_t state_capacity,
    hipStream_t stream) {
  if (precompute_function == nullptr || core_function == nullptr)
    return fail_message("Qwen3.6-27B GDN modules are not loaded");
  const std::array<const void*, 16> pointers = {
      output_bf16, A_log_f32, a_bf16, dt_bias_bf16,
      q_bf16, k_bf16, v_bf16, b_bf16,
      initial_state_bf16, initial_state_indices_i32,
      intermediate_state_bf16, intermediate_state_indices_i32,
      q_normalized_f32, k_normalized_f32, decay_f32, beta_f32,
  };
  if (std::any_of(pointers.begin(), pointers.end(),
                  [](const void* pointer) { return pointer == nullptr; }))
    return fail_message("Qwen3.6-27B GDN launch pointers must be nonnull");
  if (stride_q < 2048 || stride_k < 2048 || stride_v < 6144 ||
      stride_a < 48 || stride_b < 48)
    return fail_message("Qwen3.6-27B GDN tensor stride is smaller than its row");
  if (batch_size == 0 || batch_size > 256)
    return fail_message("Qwen3.6-27B M=12 verify batch must be in [1,256]");
  if (state_capacity == 0)
    return fail_message("Qwen3.6-27B state capacity must be positive");

  void* A_log_pointer = const_cast<void*>(A_log_f32);
  void* a_pointer = const_cast<void*>(a_bf16);
  void* dt_bias_pointer = const_cast<void*>(dt_bias_bf16);
  void* q_pointer = const_cast<void*>(q_bf16);
  void* k_pointer = const_cast<void*>(k_bf16);
  void* v_pointer = const_cast<void*>(v_bf16);
  void* b_pointer = const_cast<void*>(b_bf16);
  void* initial_pointer = const_cast<void*>(initial_state_bf16);
  void* initial_indices_pointer = const_cast<void*>(initial_state_indices_i32);
  void* intermediate_indices_pointer =
      const_cast<void*>(intermediate_state_indices_i32);

  void* precompute_arguments[] = {
      &A_log_pointer, &a_pointer, &dt_bias_pointer, &q_pointer, &k_pointer,
      &b_pointer, &q_normalized_f32, &k_normalized_f32, &decay_f32,
      &beta_f32, &stride_q, &stride_k, &stride_a, &stride_b,
  };
  hipError_t error = hipModuleLaunchKernel(
      precompute_function, batch_size * block_tokens * 16, 1, 1, 64, 1, 1, 0, stream,
      precompute_arguments, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(precompute)", error);

  void* core_arguments[] = {
      &q_normalized_f32, &k_normalized_f32, &v_pointer, &decay_f32,
      &beta_f32, &output_bf16, &initial_pointer, &intermediate_state_bf16,
      &initial_indices_pointer, &intermediate_indices_pointer, &stride_v,
      &state_capacity,
  };
  error = hipModuleLaunchKernel(
      core_function, batch_size * 384, 1, 1, 64, 1, 1, 0, stream,
      core_arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel(core)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_verify_m12_batched_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  hipError_t first_error = hipSuccess;
  if (qkvz_conv_t8_module != nullptr) {
    const hipError_t error = hipModuleUnload(qkvz_conv_t8_module);
    if (first_error == hipSuccess) first_error = error;
  }
  if (state_replay_module != nullptr) {
    const hipError_t error = hipModuleUnload(state_replay_module);
    if (first_error == hipSuccess) first_error = error;
  }
  if (core_module != nullptr) {
    const hipError_t error = hipModuleUnload(core_module);
    if (first_error == hipSuccess) first_error = error;
  }
  if (precompute_module != nullptr) {
    const hipError_t error = hipModuleUnload(precompute_module);
    if (first_error == hipSuccess) first_error = error;
  }
  core_module = nullptr;
  precompute_module = nullptr;
  core_function = nullptr;
  precompute_function = nullptr;
  qkvz_conv_t8_module = nullptr;
  qkvz_conv_t8_function = nullptr;
  loaded_qkvz_conv_t8_path.clear();
  state_replay_module = nullptr;
  state_replay_function = nullptr;
  loaded_state_replay_path.clear();
  loaded_core_path.clear();
  loaded_precompute_path.clear();
  if (first_error != hipSuccess) return fail("hipModuleUnload", first_error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_verify_m12_batched_set_block_tokens(
    uint32_t tokens) {
  if (tokens != 8 && tokens != 12)
    return fail_message("verification block tokens must be 8 or 12");
  std::lock_guard<std::mutex> guard(module_mutex);
  block_tokens = tokens;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_verify_m12_batched_load_state_replay(
    const char* state_replay_hsaco_path) {
  if (state_replay_hsaco_path == nullptr || state_replay_hsaco_path[0] == '\0')
    return fail_message("state replay hsaco path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (state_replay_module != nullptr) {
    if (loaded_state_replay_path == state_replay_hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different Qwen3.6-27B state replay module is already loaded");
  }
  if (validate_device() != 0) return -1;
  hipError_t error = hipModuleLoad(&state_replay_module, state_replay_hsaco_path);
  if (error != hipSuccess) return fail("hipModuleLoad(state replay)", error);
  error = get_function_with_legacy_fallback(
      &state_replay_function, state_replay_module,
      "netra_gdn_state_replay_t8_bv16_hv48_bf16_state_gfx950",
      "qwen36_27b_gdn_state_replay_m12_fp32_gfx950");
  if (error != hipSuccess) {
    (void)hipModuleUnload(state_replay_module);
    state_replay_module = nullptr;
    state_replay_function = nullptr;
    return fail("hipModuleGetFunction(state replay)", error);
  }
  loaded_state_replay_path = state_replay_hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_verify_m12_batched_launch_state_replay(
    const void* k_normalized_f32,
    const void* v_bf16,
    const void* decay_f32,
    const void* beta_f32,
    void* state_pool,
    const void* accept_lengths_i32,
    const void* initial_state_indices_i32,
    const void* output_state_indices_i32,
    uint32_t stride_v,
    uint32_t batch_size,
    uint32_t state_capacity,
    hipStream_t stream) {
  if (state_replay_function == nullptr)
    return fail_message("Qwen3.6-27B GDN state replay module is not loaded");
  const std::array<const void*, 8> pointers = {
      k_normalized_f32, v_bf16, decay_f32, beta_f32, state_pool,
      accept_lengths_i32, initial_state_indices_i32, output_state_indices_i32,
  };
  if (std::any_of(pointers.begin(), pointers.end(),
                  [](const void* pointer) { return pointer == nullptr; }))
    return fail_message("state replay launch pointers must be nonnull");
  if (stride_v < 6144 || batch_size == 0 || batch_size > 256 ||
      state_capacity == 0)
    return fail_message("invalid Qwen3.6-27B GDN state replay shape");

  // The replay kernel keeps the verification kernarg layout: slot 0 (unused
  // Q), slot 5 output SSM pool, slot 7 accepted lengths, slot 9 destination
  // state indices. The exact-contract state pool serves as both source and
  // destination.
  void* q_pointer = const_cast<void*>(k_normalized_f32);
  void* k_pointer = const_cast<void*>(k_normalized_f32);
  void* v_pointer = const_cast<void*>(v_bf16);
  void* decay_pointer = const_cast<void*>(decay_f32);
  void* beta_pointer = const_cast<void*>(beta_f32);
  void* initial_pointer = state_pool;
  void* lengths_pointer = const_cast<void*>(accept_lengths_i32);
  void* initial_indices_pointer = const_cast<void*>(initial_state_indices_i32);
  void* output_indices_pointer = const_cast<void*>(output_state_indices_i32);
  void* replay_arguments[] = {
      &q_pointer, &k_pointer, &v_pointer, &decay_pointer, &beta_pointer,
      &state_pool, &initial_pointer, &lengths_pointer,
      &initial_indices_pointer, &output_indices_pointer, &stride_v,
      &state_capacity,
  };
  hipError_t error = hipModuleLaunchKernel(
      state_replay_function, batch_size * 384, 1, 1, 64, 1, 1, 0, stream,
      replay_arguments, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(state replay)", error);
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_gdn_verify_m12_batched_last_error(void) {
  return last_error.c_str();
}
