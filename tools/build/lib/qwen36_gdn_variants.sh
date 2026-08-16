#!/usr/bin/env bash

# Canonical assembler IDs for the Qwen3.6 GDN verification kernels. These IDs
# are part of the generated-code contract and must stay aligned with the
# `.if NETRA_GDN_*_VARIANT` blocks in the gfx950 assembly sources.

netra_qwen36_gdn_core_variant_id() {
  local variant=$1
  local contract=$2
  local variant_id

  case "$variant" in
    original) variant_id=0 ;;
    triton) variant_id=1 ;;
    forward-xor) variant_id=2 ;;
    reverse-scan) variant_id=3 ;;
    balanced-xor) variant_id=4 ;;
    forward-k-forward-q-fma) variant_id=5 ;;
    forward-k-reverse-q-fma) variant_id=6 ;;
    forward-k-reverse-q-add) variant_id=7 ;;
    forward-k-balanced-q-add) variant_id=8 ;;
    forward-k-q-fma-10234567) variant_id=9 ;;
    forward-k-q-fma-10325476) variant_id=10 ;;
    forward-k-q-fma-76452301) variant_id=11 ;;
    forward-k-q-fma-76543210) variant_id=12 ;;
    fused-exact | fused-packed-exact) variant_id=13 ;;
    fused-packed-decode-state) variant_id=14 ;;
    fused-packed-decode-sequence) variant_id=15 ;;
    packed-pair-chains) variant_id=16 ;;
    packed-pair-interleaved) variant_id=17 ;;
    packed-pair-decay-dot-interleaved) variant_id=18 ;;
    *)
      echo "Unsupported NETRA_GDN_CORE_VARIANT: $variant" >&2
      return 2
      ;;
  esac

  case "$contract" in
    m16)
      if (( variant_id > 15 )); then
        echo "NETRA_GDN_CORE_VARIANT $variant is not valid for M16" >&2
        return 2
      fi
      ;;
    m12) ;;
    *)
      echo "Unknown GDN core contract: $contract" >&2
      return 2
      ;;
  esac

  printf '%s\n' "$variant_id"
}

netra_qwen36_gdn_precompute_variant_id() {
  local variant=$1

  case "$variant" in
    original) printf '0\n' ;;
    triton-reduce-rcp) printf '1\n' ;;
    triton-div) printf '2\n' ;;
    original-reduce-div) printf '3\n' ;;
    triton-div-no-fixup) printf '4\n' ;;
    triton-contiguous-exact) printf '5\n' ;;
    triton-contiguous-exact-gates) printf '6\n' ;;
    triton-exact) printf '7\n' ;;
    packed-decode-beta) printf '8\n' ;;
    *)
      echo "Unsupported NETRA_GDN_PRECOMPUTE_VARIANT: $variant" >&2
      return 2
      ;;
  esac
}
