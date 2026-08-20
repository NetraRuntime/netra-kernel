// SPDX-License-Identifier: MIT
#pragma once

#include "netra_engine.h"

#include <array>
#include <atomic>
#include <string>
#include <vector>

struct netra_operation_record {
  bool fallback = true;
  hipModule_t module = nullptr;
  hipFunction_t function = nullptr;
  std::array<unsigned int, 3> grid{1, 1, 1};
  std::array<unsigned int, 3> block{1, 1, 1};
  // Fixed LDS is declared by the code object and retained as resource
  // metadata. Only dynamic_lds_bytes is passed to hipModuleLaunchKernel.
  unsigned int lds_bytes = 0;
  unsigned int dynamic_lds_bytes = 0;
  std::array<void*, 32> argument_values{};
  std::array<uint32_t, 32> scalar_u32{};
  std::array<void*, 32> argument_addresses{};
  std::array<bool, 32> argument_bindable{};
  std::array<bool, 32> argument_is_u32{};
  uint32_t argument_count = 0;
};

struct netra_profile_record {
  netra_profile_info_t info{};
  std::vector<netra_operation_record> operations;
  hipGraph_t graph = nullptr;
  hipGraphExec_t graph_exec = nullptr;
  bool graph_prepared = false;
};

struct netra_engine {
  int device_id = -1;
  bool graph_enabled = false;
  std::string directory;
  std::vector<netra_profile_record> profiles;
  void* workspace = nullptr;
  uint64_t workspace_bytes = 0;
  std::atomic<bool> bindings_finalized{false};
  std::atomic<uint32_t> in_flight{0};
  std::array<char, 512> last_error{};
};
