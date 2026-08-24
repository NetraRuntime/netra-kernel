"""Typed gfx1151 C ABI binding with no torch or inference-engine dependency."""

from __future__ import annotations

import ctypes
from collections.abc import Callable

from netra_kernel.native import load_native_library


P = ctypes.c_void_p
U = ctypes.c_uint
F = ctypes.c_float


def _pointers(count: int, *suffix: type[ctypes._SimpleCData]) -> list[type]:
    return [P] * count + list(suffix)


_SIGNATURES = {
    "netra_mxfp4_sgl_decode": _pointers(15),
    "netra_mxfp4_sgl_decode_block64": _pointers(16),
    "netra_mxfp4_sgl_prefill_repack": _pointers(3),
    "netra_mxfp4_sgl_prefill_gate_up": _pointers(9, U, P),
    "netra_mxfp4_sgl_prefill_down": _pointers(5, U, P),
    "netra_mxfp4_sgl_m12_gate_up": _pointers(9, U, P),
    "netra_mxfp4_sgl_m12_down": _pointers(5, U, P),
    "netra_mxfp4_sgl_linear": _pointers(4, U, U, U, P),
    "netra_mxfp4_linear_n2048_k4096_block128": _pointers(6),
    "netra_mxfp4_linear_n12800_k2048_block64": _pointers(6),
    "netra_bf16_qkv_decode": _pointers(4),
    "netra_bf16_attention_output_decode": _pointers(4),
    "netra_bf16_router_decode": _pointers(4),
    "netra_bf16_shared_gate_up_silu_decode": _pointers(4),
    "netra_bf16_shared_down_decode": _pointers(4),
    "netra_bf16_lm_head_decode": _pointers(4),
    "netra_qwen36_rmsnorm_decode": _pointers(3, F, P),
    "netra_qwen36_fused_add_rmsnorm_decode": _pointers(3, F, P),
    "netra_mxfp4_sgl_linear_prefill": _pointers(4, U, U, U, P),
    "netra_mxfp4_sgl_linear_prefill_repack": _pointers(2, U, U, P),
    "netra_qkvzba_split_copy": _pointers(6, U, P),
    "netra_extend_attention": _pointers(8, U, F, P),
    "netra_qk_norm_mrope_gate_kv_store": _pointers(11, U, U, P),
    "netra_gdn_chunk_o": _pointers(8, F, U, P),
    "netra_gdn_recompute_w_u": _pointers(7, U, P),
    "netra_causal_conv1d": _pointers(7),
    "netra_expert_activation_pack": _pointers(4, U, U, P),
    "netra_expert_weighted_reduce_fp64": _pointers(4, U, P),
}


class Gfx1151Runtime:
    """Load, type, and initialize the raw gfx1151 runtime once."""

    def __init__(self, stream_provider: Callable[[], int]) -> None:
        self.lib = load_native_library()
        self._stream_provider = stream_provider
        self.lib.netra_mxfp4_sgl_init.argtypes = []
        self.lib.netra_mxfp4_sgl_init.restype = ctypes.c_int
        self.lib.netra_mxfp4_sgl_error.argtypes = []
        self.lib.netra_mxfp4_sgl_error.restype = ctypes.c_char_p
        for name, arguments in _SIGNATURES.items():
            function = getattr(self.lib, name)
            function.argtypes = arguments
            function.restype = ctypes.c_int
        status = self.lib.netra_mxfp4_sgl_init()
        if status:
            detail = self.lib.netra_mxfp4_sgl_error()
            raise RuntimeError(detail.decode(errors="replace") if detail else status)

    def stream(self) -> ctypes.c_void_p:
        return ctypes.c_void_p(self._stream_provider())

    @staticmethod
    def check(status: int, operation: str) -> None:
        if status:
            raise RuntimeError(f"{operation} failed with HIP status {status}")
