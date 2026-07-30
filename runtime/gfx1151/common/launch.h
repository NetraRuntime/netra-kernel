// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime.h>
#include "runtime/gfx1151/common/config.h"

namespace netra::gfx1151 {

template <typename Args>
__attribute__((visibility("hidden"))) hipError_t launch(hipFunction_t function, unsigned gx, unsigned gy,
                         unsigned bx, hipStream_t stream, Args& args) {
  size_t size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER,
      &args,
      HIP_LAUNCH_PARAM_BUFFER_SIZE,
      &size,
      HIP_LAUNCH_PARAM_END,
  };
  return hipModuleLaunchKernel(function, gx, gy, 1, bx, 1, 1, 0, stream,
                               nullptr, config);
}

template <typename Args>
__attribute__((visibility("hidden"))) hipError_t launch_3d(hipFunction_t function, unsigned gx, unsigned gy,
                            unsigned gz, unsigned bx, hipStream_t stream,
                            Args& args) {
  size_t size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER,
      &args,
      HIP_LAUNCH_PARAM_BUFFER_SIZE,
      &size,
      HIP_LAUNCH_PARAM_END,
  };
  return hipModuleLaunchKernel(function, gx, gy, gz, bx, 1, 1, 0, stream,
                               nullptr, config);
}

}  // namespace netra::gfx1151
