// SPDX-License-Identifier: MIT
#include "../../../runtime/gfx950/engine/netra_engine.h"

#include <iostream>

int main(int argc, char** argv) {
  if (argc != 2) {
    std::cerr << "usage: " << argv[0] << " ENGINE_DIR\n";
    return 2;
  }
  netra_engine_options_t options{sizeof(options), 0, 0};
  netra_engine_t* engine = nullptr;
  netra_status_t status = netra_engine_create(argv[1], &options, &engine);
  if (status != NETRA_STATUS_OK) {
    std::cerr << "create failed: " << static_cast<int>(status) << "\n";
    return 1;
  }
  if (netra_engine_profile_count(engine) != 1) return 1;
  netra_profile_info_t profile{};
  profile.struct_size = sizeof(profile);
  if (netra_engine_query_profile(engine, 0, &profile) != NETRA_STATUS_OK)
    return 1;
  const uint32_t unsupported_m =
      profile.max_m == UINT32_MAX ? profile.min_m - 1 : profile.max_m + 1;
  netra_launch_shape_t unsupported{unsupported_m, profile.min_batch,
                                   profile.min_sequence,
                                   profile.tensor_parallel};
  status = netra_engine_launch(engine, 0, &unsupported, nullptr);
  if (status != NETRA_STATUS_UNSUPPORTED_PROFILE) return 1;
  if (profile.requires_fallback) {
    netra_launch_shape_t supported{profile.min_m, profile.min_batch,
                                   profile.min_sequence,
                                   profile.tensor_parallel};
    status = netra_engine_launch(engine, 0, &supported, nullptr);
    if (status != NETRA_STATUS_FALLBACK_REQUIRED) return 1;
  }
  if (netra_engine_destroy(engine) != NETRA_STATUS_OK) return 1;
  std::cout << "gfx950 engine load/profile/guard smoke passed; fallback="
            << profile.requires_fallback << "; m=" << profile.min_m << ".."
            << profile.max_m << "\n";
  return 0;
}
