// SPDX-License-Identifier: MIT
#pragma once

#include <stddef.h>
#include <stdint.h>
#include <hip/hip_runtime_api.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct netra_engine netra_engine_t;

typedef enum netra_status {
  NETRA_STATUS_OK = 0,
  NETRA_STATUS_INVALID_ARGUMENT = 1,
  NETRA_STATUS_IO = 2,
  NETRA_STATUS_MANIFEST = 3,
  NETRA_STATUS_UNSUPPORTED_TARGET = 4,
  NETRA_STATUS_UNSUPPORTED_PROFILE = 5,
  NETRA_STATUS_BINDING = 6,
  NETRA_STATUS_HIP = 7,
  NETRA_STATUS_BUSY = 8,
  NETRA_STATUS_FALLBACK_REQUIRED = 9
} netra_status_t;

typedef struct netra_engine_options {
  uint32_t struct_size;
  int32_t device_id;
  uint32_t enable_graph_capture;
} netra_engine_options_t;

typedef struct netra_profile_info {
  uint32_t struct_size;
  uint32_t profile_id;
  uint32_t min_m;
  uint32_t max_m;
  uint32_t min_batch;
  uint32_t max_batch;
  uint64_t min_sequence;
  uint64_t max_sequence;
  uint32_t tensor_parallel;
  uint64_t workspace_bytes;
  uint32_t requires_fallback;
} netra_profile_info_t;

typedef struct netra_launch_shape {
  uint32_t m;
  uint32_t batch;
  uint64_t sequence;
  uint32_t tensor_parallel;
} netra_launch_shape_t;

typedef struct netra_pointer_binding {
  uint32_t argument_index;
  uint32_t reserved;
  void* pointer;
} netra_pointer_binding_t;

netra_status_t netra_engine_create(const char* engine_directory,
                                   const netra_engine_options_t* options,
                                   netra_engine_t** output);
size_t netra_engine_profile_count(const netra_engine_t* engine);
netra_status_t netra_engine_query_profile(const netra_engine_t* engine,
                                          uint32_t profile_id,
                                          netra_profile_info_t* output);

// Binding slots are numeric indices emitted in graph_recipe.json. Binding is
// an initialization/control-plane operation and is not thread-safe with launch.
netra_status_t netra_engine_bind(netra_engine_t* engine, uint32_t profile_id,
                                 uint32_t operation_index,
                                 uint32_t argument_index, void* pointer);

// Ends the externally serialized binding phase. Direct-launch records are
// immutable after this succeeds and may then be used by concurrent callers.
netra_status_t netra_engine_finalize_bindings(netra_engine_t* engine);

// Captures a graph only after all stable pointers are bound. Direct fixed
// launches remain available if graph preparation is skipped or disabled.
netra_status_t netra_engine_prepare_profile(netra_engine_t* engine,
                                            uint32_t profile_id,
                                            hipStream_t stream);

netra_status_t netra_engine_launch(netra_engine_t* engine,
                                   uint32_t profile_id,
                                   const netra_launch_shape_t* shape,
                                   hipStream_t caller_stream);

// Launch one already-selected fixed operation. This supports compatibility
// migration at existing framework boundaries without doing tactic lookup.
netra_status_t netra_engine_launch_operation(
    netra_engine_t* engine, uint32_t profile_id, uint32_t operation_index,
    const netra_launch_shape_t* shape, hipStream_t caller_stream);

// Applies boundary pointers in caller-local launch storage and submits one
// already-selected operation. Concurrent calls cannot race or mix pointer
// sets; pointed-to GPU storage must outlive submitted stream work.
netra_status_t netra_engine_launch_operation_bound(
    netra_engine_t* engine, uint32_t profile_id, uint32_t operation_index,
    const netra_launch_shape_t* shape,
    const netra_pointer_binding_t* bindings, uint32_t binding_count,
    hipStream_t caller_stream);
const char* netra_engine_last_error(const netra_engine_t* engine);

// Destruction returns BUSY while a launch API call is submitting work. Because
// HIP launch is asynchronous, the caller must externally quiesce every stream,
// graph executable, bind, and prepare call that can reference this engine.
netra_status_t netra_engine_destroy(netra_engine_t* engine);

#ifdef __cplusplus
}
#endif
