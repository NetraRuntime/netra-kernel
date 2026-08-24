// SPDX-License-Identifier: MIT
#pragma once

#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#  if defined(NETRA_ENGINE_BUILDING_LIBRARY)
#    define NETRA_API __declspec(dllexport)
#  else
#    define NETRA_API __declspec(dllimport)
#  endif
#elif defined(__GNUC__) || defined(__clang__)
#  define NETRA_API __attribute__((visibility("default")))
#else
#  define NETRA_API
#endif

#define NETRA_ENGINE_ABI_VERSION 1u
#define NETRA_ENGINE_VERSION_MAJOR 0u
#define NETRA_ENGINE_VERSION_MINOR 3u
#define NETRA_ENGINE_VERSION_PATCH 0u

#ifdef __cplusplus
extern "C" {
#endif

typedef struct netra_engine netra_engine_t;
// Opaque native stream handle. HIP callers pass their hipStream_t unchanged;
// non-HIP framework headers do not need to become a public SDK dependency.
typedef void* netra_stream_t;

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

NETRA_API uint32_t netra_engine_abi_version(void);
NETRA_API const char* netra_engine_version(void);
NETRA_API netra_status_t netra_engine_create(
    const char* engine_directory, const netra_engine_options_t* options,
    netra_engine_t** output);
NETRA_API size_t netra_engine_profile_count(const netra_engine_t* engine);
NETRA_API netra_status_t netra_engine_query_profile(
    const netra_engine_t* engine, uint32_t profile_id,
    netra_profile_info_t* output);
NETRA_API netra_status_t netra_engine_bind(
    netra_engine_t* engine, uint32_t profile_id, uint32_t operation_index,
    uint32_t argument_index, void* pointer);
NETRA_API netra_status_t netra_engine_finalize_bindings(netra_engine_t* engine);
NETRA_API netra_status_t netra_engine_prepare_profile(
    netra_engine_t* engine, uint32_t profile_id, netra_stream_t stream);
NETRA_API netra_status_t netra_engine_launch(
    netra_engine_t* engine, uint32_t profile_id,
    const netra_launch_shape_t* shape, netra_stream_t caller_stream);
NETRA_API netra_status_t netra_engine_launch_operation(
    netra_engine_t* engine, uint32_t profile_id, uint32_t operation_index,
    const netra_launch_shape_t* shape, netra_stream_t caller_stream);
NETRA_API netra_status_t netra_engine_launch_operation_bound(
    netra_engine_t* engine, uint32_t profile_id, uint32_t operation_index,
    const netra_launch_shape_t* shape,
    const netra_pointer_binding_t* bindings, uint32_t binding_count,
    netra_stream_t caller_stream);
NETRA_API const char* netra_engine_last_error(const netra_engine_t* engine);
NETRA_API netra_status_t netra_engine_destroy(netra_engine_t* engine);

#ifdef __cplusplus
}
#endif
