// SPDX-License-Identifier: MIT
//
// Netra-owned zero-copy layout operation for the DeepSeek-V4 M=1 FP8 scale.
//
// A row-major [1, G] FP32 tensor and the physical column-major [1, G] layout
// consumed by CK bpreshuffle have identical byte order.  Only the public tensor
// strides differ: (G, 1) for the producer and (1, 1) for the consumer.  This
// operator makes that aliasing contract explicit and rejects every shape where
// the M=1 degeneracy does not prove physical-layout equivalence.

#include <ATen/ATen.h>
#include <torch/library.h>

#include <cstdint>
#include <vector>

namespace {

constexpr std::int64_t kAbiVersion = 1;
constexpr std::int64_t kRequiredAlignment = 16;
constexpr std::int64_t kMaximumGroups = 64;

at::Tensor dsv4_fp8_m1_bpreshuffle_scale_view_v1(
    const at::Tensor& scale) {
  TORCH_CHECK(scale.is_cuda(), "scale must be a HIP tensor");
  TORCH_CHECK(scale.scalar_type() == at::kFloat, "scale must be FP32");
  TORCH_CHECK(scale.dim() == 2, "scale must have rank 2");
  TORCH_CHECK(scale.size(0) == 1, "scale must have M=1");
  TORCH_CHECK(scale.size(1) > 0 && scale.size(1) <= kMaximumGroups,
              "scale group count must be in [1, 64]");
  TORCH_CHECK(scale.storage_offset() >= 0, "scale storage offset is invalid");
  TORCH_CHECK(scale.stride(1) == 1,
              "scale groups must be contiguous in row-major order");
  TORCH_CHECK(scale.stride(0) >= scale.size(1),
              "scale row stride cannot overlap group storage");
  TORCH_CHECK(reinterpret_cast<std::uintptr_t>(scale.data_ptr()) %
                      kRequiredAlignment ==
                  0,
              "scale pointer must be 16-byte aligned");

  // No allocation, copy, transpose, device launch, or ownership transfer.
  // For M=1, both logical indices (0, g) map to storage offset g.
  return scale.as_strided(scale.sizes(), {1, 1}, scale.storage_offset());
}

std::int64_t dsv4_fp8_m1_bpreshuffle_scale_view_v1_abi_version() {
  return kAbiVersion;
}

}  // namespace

TORCH_LIBRARY(netra, library) {
  library.def(
      "dsv4_fp8_m1_bpreshuffle_scale_view_v1(Tensor(a) scale) -> Tensor(a)");
  library.impl("dsv4_fp8_m1_bpreshuffle_scale_view_v1",
               c10::DispatchKey::CompositeImplicitAutograd,
               TORCH_FN(dsv4_fp8_m1_bpreshuffle_scale_view_v1));
  library.def("dsv4_fp8_m1_bpreshuffle_scale_view_v1_abi_version() -> int",
              &dsv4_fp8_m1_bpreshuffle_scale_view_v1_abi_version);
}
