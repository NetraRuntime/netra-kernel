#!/usr/bin/env bash

# Shared, behavior-preserving gfx950 assembly build primitives.
#
# Callers own kernel-specific flags, bridge compilation, disassembly assertions,
# manifests, and output contracts. Keeping only the byte-producing boilerplate
# here makes builders consistent without hiding the flags that define a kernel.

netra_gfx950_require_device() {
  local rocminfo_text
  rocminfo_text=$(rocminfo 2>/dev/null)
  if ! grep -q 'Name:[[:space:]]*gfx950' <<<"$rocminfo_text"; then
    echo "gfx950 is not visible; refusing target-specific build" >&2
    return 2
  fi
}

netra_gfx950_build_kernel() {
  local clang_bin=$1
  local linker_bin=$2
  local objdump_bin=$3
  local readobj_bin=$4
  local out_dir=$5
  local source_file=$6
  local stem=$7

  "$clang_bin" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
    -x assembler -c "$source_file" -o "${out_dir}/${stem}.o"
  "$linker_bin" -shared "${out_dir}/${stem}.o" \
    -o "${out_dir}/${stem}.hsaco"
  "$objdump_bin" --disassemble --mcpu=gfx950 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
  "$readobj_bin" --notes "${out_dir}/${stem}.hsaco" \
    > "${out_dir}/${stem}.metadata.txt"

  grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
  grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
}

netra_gfx950_build_wave64_kernel() {
  local rocm_dir=$1
  local out_dir=$2
  local source_file=$3
  local stem=$4
  shift 4

  "${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
    -mwavefrontsize64 -x assembler "$@" -c "$source_file" \
    -o "${out_dir}/${stem}.o"
  "${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${stem}.o" \
    -o "${out_dir}/${stem}.hsaco"
  "${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
  "${rocm_dir}/llvm/bin/llvm-readobj" --notes \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.metadata.txt"

  grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
  grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
  grep -q 'private_segment_fixed_size:[[:space:]]*0' \
    "${out_dir}/${stem}.metadata.txt"
}
