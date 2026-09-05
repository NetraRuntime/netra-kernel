#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 OUTPUT_DIRECTORY" >&2
  exit 2
fi

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
output_dir=$1
source_file=${repo_dir}/runtime/gfx950/fp8/quantization/dsv4_fp8_m1_bpreshuffle_scale_view_v1.cpp
mkdir -p "${output_dir}/build"

SOURCE_FILE="${source_file}" OUTPUT_DIR="${output_dir}" python3 - <<'PY'
import os
from pathlib import Path

from torch.utils.cpp_extension import load

source = Path(os.environ["SOURCE_FILE"])
output = Path(os.environ["OUTPUT_DIR"])
module = load(
    name="netra_dsv4_fp8_m1_bpreshuffle_scale_view_v1",
    sources=[str(source)],
    extra_cflags=["-O3", "-std=c++17"],
    build_directory=str(output / "build"),
    is_python_module=False,
    verbose=True,
)
print(module)
PY

library=$(find "${output_dir}/build" -maxdepth 1 -type f \
  -name 'netra_dsv4_fp8_m1_bpreshuffle_scale_view_v1*.so' -print -quit)
if [[ -z "${library}" ]]; then
  echo "built layout library was not found" >&2
  exit 1
fi
cp -f "${library}" "${output_dir}/libnetra_dsv4_fp8_m1_bpreshuffle_scale_view_v1.so"
sha256sum "${output_dir}/libnetra_dsv4_fp8_m1_bpreshuffle_scale_view_v1.so"
