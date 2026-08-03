// SPDX-License-Identifier: MIT
//
// Module loading and caller-stream dispatch only.  Both compute stages are raw
// gfx950 AMDGCN under kernels/gfx950/linear_attention/verify/.
#include "qwen36_gdn_state_replay_m12_bridge.h"

#include <hip/hip_runtime.h>

#include <algorithm>
#include <array>
#include <mutex>
#include <string>

namespace {

std::mutex module_mutex;
hipModule_t precompute_module = nullptr;
std::array<hipModule_t, 3> core_modules = {nullptr, nullptr, nullptr};
hipFunction_t precompute_function = nullptr;
std::array<hipFunction_t, 3> core_functions = {nullptr, nullptr, nullptr};
std::array<hipModule_t, 3> dual_core_modules = {nullptr, nullptr, nullptr};
std::array<hipFunction_t, 3> dual_core_functions = {
    nullptr, nullptr, nullptr};
thread_local std::string last_error;

int fail(const char* operation, hipError_t error) {
  last_error = std::string(operation) + ": " + hipGetErrorString(error);
  return static_cast<int>(error);
}

int fail_message(const std::string& message) {
  last_error = message;
  return -1;
}

void clear_dual_modules() {
  for (hipModule_t& module : dual_core_modules) {
    if (module != nullptr) (void)hipModuleUnload(module);
    module = nullptr;
  }
  dual_core_functions = {nullptr, nullptr, nullptr};
}

void clear_modules() {
  clear_dual_modules();
  for (hipModule_t& module : core_modules) {
    if (module != nullptr) (void)hipModuleUnload(module);
    module = nullptr;
  }
  if (precompute_module != nullptr) (void)hipModuleUnload(precompute_module);
  precompute_module = nullptr;
  precompute_function = nullptr;
  core_functions = {nullptr, nullptr, nullptr};
}

int load_core(size_t index, const char* path) {
  hipError_t error = hipModuleLoad(&core_modules[index], path);
  if (error != hipSuccess) return fail("hipModuleLoad(core)", error);
  error = hipModuleGetFunction(
      &core_functions[index], core_modules[index],
      "qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950");
  if (error != hipSuccess) return fail("hipModuleGetFunction(core)", error);
  return 0;
}

int load_dual_core(size_t index, const char* path) {
  hipError_t error = hipModuleLoad(&dual_core_modules[index], path);
  if (error != hipSuccess) return fail("hipModuleLoad(dual core)", error);
  error = hipModuleGetFunction(
      &dual_core_functions[index], dual_core_modules[index],
      "qwen36_gdn_state_replay_m12_dual_precomputed_bv16_gfx950");
  if (error != hipSuccess)
    return fail("hipModuleGetFunction(dual core)", error);
  return 0;
}

}  // namespace

extern "C" int netra_qwen36_gdn_state_replay_m12_load(
    const char* precompute_hsaco_path,
    const char* core_waves1_hsaco_path,
    const char* core_waves4_hsaco_path,
    const char* core_waves8_hsaco_path) {
  const std::array<const char*, 4> paths = {
      precompute_hsaco_path, core_waves1_hsaco_path,
      core_waves4_hsaco_path, core_waves8_hsaco_path};
  if (std::any_of(paths.begin(), paths.end(), [](const char* path) {
        return path == nullptr || path[0] == '\0';
      }))
    return fail_message("all state-replay hsaco paths must be nonempty");

  std::lock_guard<std::mutex> guard(module_mutex);
  if (precompute_module != nullptr || core_modules[0] != nullptr)
    return fail_message("GDN state-replay modules are already loaded");

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(
        std::string("Qwen GDN state replay requires gfx950; got ") +
        properties.gcnArchName);

  error = hipModuleLoad(&precompute_module, precompute_hsaco_path);
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleLoad(precompute)", error);
  }
  error = hipModuleGetFunction(
      &precompute_function, precompute_module,
      "qwen36_gdn_verify_m12_batched_precompute_gfx950");
  if (error != hipSuccess || load_core(0, core_waves1_hsaco_path) != 0 ||
      load_core(1, core_waves4_hsaco_path) != 0 ||
      load_core(2, core_waves8_hsaco_path) != 0) {
    if (error != hipSuccess) (void)fail("hipModuleGetFunction(precompute)", error);
    clear_modules();
    return -1;
  }
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_state_replay_m12_load_dual(
    const char* core_waves1_hsaco_path,
    const char* core_waves4_hsaco_path,
    const char* core_waves8_hsaco_path) {
  const std::array<const char*, 3> paths = {
      core_waves1_hsaco_path, core_waves4_hsaco_path,
      core_waves8_hsaco_path};
  if (std::any_of(paths.begin(), paths.end(), [](const char* path) {
        return path == nullptr || path[0] == '\0';
      }))
    return fail_message("all dual state-replay hsaco paths must be nonempty");

  std::lock_guard<std::mutex> guard(module_mutex);
  if (dual_core_modules[0] != nullptr)
    return fail_message("dual GDN state-replay modules are already loaded");

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(
        std::string("Qwen dual GDN state replay requires gfx950; got ") +
        properties.gcnArchName);

  if (load_dual_core(0, core_waves1_hsaco_path) != 0 ||
      load_dual_core(1, core_waves4_hsaco_path) != 0 ||
      load_dual_core(2, core_waves8_hsaco_path) != 0) {
    clear_dual_modules();
    return -1;
  }
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_state_replay_m12_launch(
    const void* A_log_f32,
    const void* a_bf16,
    const void* dt_bias_bf16,
    const void* k_bf16,
    const void* v_bf16,
    const void* b_bf16,
    void* states_bf16,
    const void* initial_state_indices_i32,
    const void* output_state_indices_i32,
    const void* accepted_lengths_i32,
    void* q_dummy_f32,
    void* k_normalized_f32,
    void* decay_f32,
    void* beta_f32,
    uint32_t stride_k,
    uint32_t stride_v,
    uint32_t stride_a,
    uint32_t stride_b,
    uint32_t batch_size,
    uint32_t waves_per_workgroup,
    uint32_t state_capacity,
    hipStream_t stream) {
  if (precompute_function == nullptr || core_functions[0] == nullptr)
    return fail_message("GDN state-replay modules are not loaded");
  const std::array<const void*, 14> pointers = {
      A_log_f32, a_bf16, dt_bias_bf16, k_bf16, v_bf16, b_bf16,
      states_bf16, initial_state_indices_i32, output_state_indices_i32,
      accepted_lengths_i32, q_dummy_f32, k_normalized_f32, decay_f32,
      beta_f32};
  if (std::any_of(pointers.begin(), pointers.end(), [](const void* pointer) {
        return pointer == nullptr;
      }))
    return fail_message("GDN state-replay launch pointers must be nonnull");
  if (stride_k < 2048 || stride_v < 4096 || stride_a < 32 || stride_b < 32)
    return fail_message("GDN state-replay stride is smaller than its row");
  if (batch_size == 0)
    return fail_message("GDN state-replay batch size must be positive");
  if (state_capacity <= batch_size)
    return fail_message("GDN state-replay state capacity must exceed batch size");

  size_t core_index = 0;
  if (waves_per_workgroup == 4) {
    core_index = 1;
  } else if (waves_per_workgroup == 8) {
    core_index = 2;
  } else if (waves_per_workgroup != 1) {
    return fail_message("GDN state replay supports 1, 4, or 8 waves");
  }

  void* A_log_pointer = const_cast<void*>(A_log_f32);
  void* a_pointer = const_cast<void*>(a_bf16);
  void* dt_bias_pointer = const_cast<void*>(dt_bias_bf16);
  void* k_pointer = const_cast<void*>(k_bf16);
  void* v_pointer = const_cast<void*>(v_bf16);
  void* b_pointer = const_cast<void*>(b_bf16);
  void* initial_indices_pointer =
      const_cast<void*>(initial_state_indices_i32);
  void* output_indices_pointer = const_cast<void*>(output_state_indices_i32);
  void* lengths_pointer = const_cast<void*>(accepted_lengths_i32);

  // Reuse the exact K0 precompute ABI.  Passing K as both Q and K deliberately
  // leaves q_dummy unused by the recurrent stage while preserving exact K
  // normalization and gate arithmetic.
  void* precompute_arguments[] = {
      &A_log_pointer,
      &a_pointer,
      &dt_bias_pointer,
      &k_pointer,
      &k_pointer,
      &b_pointer,
      &q_dummy_f32,
      &k_normalized_f32,
      &decay_f32,
      &beta_f32,
      &stride_k,
      &stride_k,
      &stride_a,
      &stride_b,
  };
  hipError_t error = hipModuleLaunchKernel(
      precompute_function, batch_size * 192, 1, 1, 64, 1, 1, 0, stream,
      precompute_arguments, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(precompute)", error);

  void* core_arguments[] = {
      &q_dummy_f32,
      &k_normalized_f32,
      &v_pointer,
      &decay_f32,
      &beta_f32,
      &states_bf16,
      &states_bf16,
      &lengths_pointer,
      &initial_indices_pointer,
      &output_indices_pointer,
      &stride_v,
      &state_capacity,
  };
  error = hipModuleLaunchKernel(
      core_functions[core_index],
      batch_size * (256 / waves_per_workgroup), 1, 1,
      64 * waves_per_workgroup, 1, 1, 0, stream, core_arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel(core)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_state_replay_m12_launch_precomputed(
    const void* k_normalized_f32,
    const void* v_bf16,
    const void* decay_f32,
    const void* beta_f32,
    void* states_bf16,
    const void* initial_state_indices_i32,
    const void* output_state_indices_i32,
    const void* accepted_lengths_i32,
    uint32_t stride_v,
    uint32_t batch_size,
    uint32_t waves_per_workgroup,
    uint32_t state_capacity,
    hipStream_t stream) {
  if (core_functions[0] == nullptr)
    return fail_message("GDN state-replay modules are not loaded");
  const std::array<const void*, 8> pointers = {
      k_normalized_f32, v_bf16, decay_f32, beta_f32, states_bf16,
      initial_state_indices_i32, output_state_indices_i32,
      accepted_lengths_i32};
  if (std::any_of(pointers.begin(), pointers.end(), [](const void* pointer) {
        return pointer == nullptr;
      }))
    return fail_message("precomputed GDN state-replay pointers must be nonnull");
  if (stride_v < 4096)
    return fail_message("GDN state-replay V stride is smaller than its row");
  if (batch_size == 0)
    return fail_message("GDN state-replay batch size must be positive");
  if (state_capacity <= batch_size)
    return fail_message("GDN state-replay state capacity must exceed batch size");

  size_t core_index = 0;
  if (waves_per_workgroup == 4) {
    core_index = 1;
  } else if (waves_per_workgroup == 8) {
    core_index = 2;
  } else if (waves_per_workgroup != 1) {
    return fail_message("GDN state replay supports 1, 4, or 8 waves");
  }

  void* k_normalized_pointer = const_cast<void*>(k_normalized_f32);
  void* v_pointer = const_cast<void*>(v_bf16);
  void* decay_pointer = const_cast<void*>(decay_f32);
  void* beta_pointer = const_cast<void*>(beta_f32);
  void* initial_indices_pointer =
      const_cast<void*>(initial_state_indices_i32);
  void* output_indices_pointer = const_cast<void*>(output_state_indices_i32);
  void* lengths_pointer = const_cast<void*>(accepted_lengths_i32);
  // State-replay code never reads kernarg 0 (Q), so aliasing the normalized-K
  // pointer preserves the proven 88-byte core ABI without another workspace.
  void* core_arguments[] = {
      &k_normalized_pointer,
      &k_normalized_pointer,
      &v_pointer,
      &decay_pointer,
      &beta_pointer,
      &states_bf16,
      &states_bf16,
      &lengths_pointer,
      &initial_indices_pointer,
      &output_indices_pointer,
      &stride_v,
      &state_capacity,
  };
  const hipError_t error = hipModuleLaunchKernel(
      core_functions[core_index],
      batch_size * (256 / waves_per_workgroup), 1, 1,
      64 * waves_per_workgroup, 1, 1, 0, stream, core_arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel(core)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_state_replay_m12_launch_dual_precomputed(
    const void* k_normalized_f32,
    const void* v_bf16,
    const void* decay_f32,
    const void* beta_f32,
    void* states_bf16,
    const void* initial_state_indices_i32,
    const void* main_output_state_indices_i32,
    const void* main_lengths_i32,
    const void* tracking_output_state_indices_i32,
    const void* tracking_lengths_i32,
    uint32_t stride_v,
    uint32_t batch_size,
    uint32_t waves_per_workgroup,
    uint32_t state_capacity,
    hipStream_t stream) {
  if (dual_core_functions[0] == nullptr)
    return fail_message("dual GDN state-replay modules are not loaded");
  const std::array<const void*, 10> pointers = {
      k_normalized_f32, v_bf16, decay_f32, beta_f32, states_bf16,
      initial_state_indices_i32, main_output_state_indices_i32,
      main_lengths_i32, tracking_output_state_indices_i32,
      tracking_lengths_i32};
  if (std::any_of(pointers.begin(), pointers.end(), [](const void* pointer) {
        return pointer == nullptr;
      }))
    return fail_message(
        "dual precomputed GDN state-replay pointers must be nonnull");
  if (stride_v < 4096)
    return fail_message("dual GDN state-replay V stride is smaller than its row");
  if (batch_size == 0)
    return fail_message("dual GDN state-replay batch size must be positive");
  if (state_capacity <= batch_size)
    return fail_message(
        "dual GDN state-replay state capacity must exceed batch size");

  size_t core_index = 0;
  if (waves_per_workgroup == 4) {
    core_index = 1;
  } else if (waves_per_workgroup == 8) {
    core_index = 2;
  } else if (waves_per_workgroup != 1) {
    return fail_message("dual GDN state replay supports 1, 4, or 8 waves");
  }

  void* k_normalized_pointer = const_cast<void*>(k_normalized_f32);
  void* v_pointer = const_cast<void*>(v_bf16);
  void* decay_pointer = const_cast<void*>(decay_f32);
  void* beta_pointer = const_cast<void*>(beta_f32);
  void* initial_indices_pointer =
      const_cast<void*>(initial_state_indices_i32);
  void* main_output_indices_pointer =
      const_cast<void*>(main_output_state_indices_i32);
  void* main_lengths_pointer = const_cast<void*>(main_lengths_i32);
  void* tracking_output_indices_pointer =
      const_cast<void*>(tracking_output_state_indices_i32);
  void* tracking_lengths_pointer = const_cast<void*>(tracking_lengths_i32);
  // Kernarg zero is unused by state replay. Alias normalized K exactly as the
  // established single-destination specialization does.
  void* core_arguments[] = {
      &k_normalized_pointer,
      &k_normalized_pointer,
      &v_pointer,
      &decay_pointer,
      &beta_pointer,
      &states_bf16,
      &states_bf16,
      &main_lengths_pointer,
      &initial_indices_pointer,
      &main_output_indices_pointer,
      &stride_v,
      &state_capacity,
      &tracking_lengths_pointer,
      &tracking_output_indices_pointer,
  };
  const hipError_t error = hipModuleLaunchKernel(
      dual_core_functions[core_index],
      batch_size * (256 / waves_per_workgroup), 1, 1,
      64 * waves_per_workgroup, 1, 1, 0, stream, core_arguments, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(dual core)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_state_replay_m12_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  hipError_t first_error = hipSuccess;
  for (hipModule_t module : core_modules) {
    if (module != nullptr) {
      const hipError_t error = hipModuleUnload(module);
      if (first_error == hipSuccess) first_error = error;
    }
  }
  for (hipModule_t module : dual_core_modules) {
    if (module != nullptr) {
      const hipError_t error = hipModuleUnload(module);
      if (first_error == hipSuccess) first_error = error;
    }
  }
  if (precompute_module != nullptr) {
    const hipError_t error = hipModuleUnload(precompute_module);
    if (first_error == hipSuccess) first_error = error;
  }
  precompute_module = nullptr;
  core_modules = {nullptr, nullptr, nullptr};
  precompute_function = nullptr;
  core_functions = {nullptr, nullptr, nullptr};
  dual_core_modules = {nullptr, nullptr, nullptr};
  dual_core_functions = {nullptr, nullptr, nullptr};
  if (first_error != hipSuccess) return fail("hipModuleUnload", first_error);
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_gdn_state_replay_m12_last_error(void) {
  return last_error.c_str();
}
