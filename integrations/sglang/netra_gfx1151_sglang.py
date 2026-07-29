"""SGLang bridge for Netra's raw AMDGCN MXFP4 kernels on gfx1151."""

from __future__ import annotations

import ctypes
from typing import List, Optional

import torch
from sglang.srt.layers.parameter import ModelWeightParameter
from sglang.srt.layers.quantization.base_config import LinearMethodBase
from sglang.srt.utils.custom_op import register_custom_op
from torch.nn.parameter import Parameter


_LIB_PATH = (
    "/root/netra-mxfp4-gfx1151/build/sglang/libnetra_mxfp4_sgl.so"
)


def _ptr(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


class _Runtime:
    def __init__(self) -> None:
        self.lib = ctypes.CDLL(_LIB_PATH)
        self.lib.netra_mxfp4_sgl_init.restype = ctypes.c_int
        self.lib.netra_mxfp4_sgl_error.restype = ctypes.c_char_p
        self.lib.netra_mxfp4_sgl_decode.argtypes = [ctypes.c_void_p] * 15
        self.lib.netra_mxfp4_sgl_decode.restype = ctypes.c_int
        self.lib.netra_mxfp4_sgl_prefill_repack.argtypes = [ctypes.c_void_p] * 3
        self.lib.netra_mxfp4_sgl_prefill_repack.restype = ctypes.c_int
        self.lib.netra_mxfp4_sgl_prefill_gate_up.argtypes = (
            [ctypes.c_void_p] * 9
            + [ctypes.c_uint, ctypes.c_void_p]
        )
        self.lib.netra_mxfp4_sgl_prefill_gate_up.restype = ctypes.c_int
        self.lib.netra_mxfp4_sgl_prefill_down.argtypes = (
            [ctypes.c_void_p] * 5
            + [ctypes.c_uint, ctypes.c_void_p]
        )
        self.lib.netra_mxfp4_sgl_prefill_down.restype = ctypes.c_int
        self.lib.netra_mxfp4_sgl_linear.argtypes = (
            [ctypes.c_void_p] * 4
            + [ctypes.c_uint] * 3
            + [ctypes.c_void_p]
        )
        self.lib.netra_mxfp4_sgl_linear.restype = ctypes.c_int
        self.lib.netra_mxfp4_sgl_linear_prefill.argtypes = (
            [ctypes.c_void_p] * 4
            + [ctypes.c_uint] * 3
            + [ctypes.c_void_p]
        )
        self.lib.netra_mxfp4_sgl_linear_prefill.restype = ctypes.c_int
        self.lib.netra_mxfp4_sgl_linear_prefill_repack.argtypes = (
            [ctypes.c_void_p] * 2
            + [ctypes.c_uint] * 2
            + [ctypes.c_void_p]
        )
        self.lib.netra_mxfp4_sgl_linear_prefill_repack.restype = ctypes.c_int
        self.lib.netra_qkvzba_split_copy.argtypes = (
            [ctypes.c_void_p] * 6
            + [ctypes.c_uint, ctypes.c_void_p]
        )
        self.lib.netra_qkvzba_split_copy.restype = ctypes.c_int
        self.lib.netra_extend_attention.argtypes = (
            [ctypes.c_void_p] * 8
            + [ctypes.c_uint, ctypes.c_float, ctypes.c_void_p]
        )
        self.lib.netra_extend_attention.restype = ctypes.c_int
        self.lib.netra_gdn_chunk_o.argtypes = (
            [ctypes.c_void_p] * 8
            + [ctypes.c_float, ctypes.c_uint, ctypes.c_void_p]
        )
        self.lib.netra_gdn_chunk_o.restype = ctypes.c_int
        self.lib.netra_gdn_recompute_w_u.argtypes = (
            [ctypes.c_void_p] * 7
            + [ctypes.c_uint, ctypes.c_void_p]
        )
        self.lib.netra_gdn_recompute_w_u.restype = ctypes.c_int
        self.lib.netra_expert_activation_pack.argtypes = (
            [ctypes.c_void_p] * 4
            + [ctypes.c_uint] * 2
            + [ctypes.c_void_p]
        )
        self.lib.netra_expert_activation_pack.restype = ctypes.c_int
        status = self.lib.netra_mxfp4_sgl_init()
        if status:
            raise RuntimeError(self.lib.netra_mxfp4_sgl_error().decode())

    @staticmethod
    def stream() -> ctypes.c_void_p:
        return ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)

    @staticmethod
    def check(status: int, operation: str) -> None:
        if status:
            raise RuntimeError(f"{operation} failed with HIP status {status}")


_runtime: _Runtime | None = None


def _get_runtime() -> _Runtime:
    global _runtime
    if _runtime is None:
        _runtime = _Runtime()
    return _runtime


def _repack_prefill_weight(source: torch.Tensor) -> torch.Tensor:
    """One-time device-side byte permutation for the raw gfx1151 prefill kernel."""
    if source.shape != (256, 1024, 512) or source.dtype != torch.uint8:
        raise ValueError(
            f"Netra prefill repack expects uint8 [256,1024,512], got "
            f"{source.dtype} {tuple(source.shape)}"
        )
    if not source.is_contiguous():
        raise ValueError("Netra prefill repack requires a contiguous source")
    destination = torch.empty_like(source)
    runtime = _get_runtime()
    status = runtime.lib.netra_mxfp4_sgl_prefill_repack(
        _ptr(source), _ptr(destination), runtime.stream()
    )
    runtime.check(status, "Netra raw-ASM MXFP4 prefill weight repack")
    return destination


def _repack_linear_prefill_weight(
    source: torch.Tensor, n: int, k: int
) -> torch.Tensor:
    """Build the persistent dword layout consumed by dense prefill ASM."""
    if source.dtype != torch.uint8 or tuple(source.shape) != (k // 2, n):
        raise ValueError(
            f"Netra dense-prefill repack expects uint8 [{k // 2},{n}], got "
            f"{source.dtype} {tuple(source.shape)}"
        )
    if not source.is_contiguous():
        raise ValueError("Netra dense-prefill repack requires a contiguous source")
    destination = torch.empty_like(source)
    runtime = _get_runtime()
    status = runtime.lib.netra_mxfp4_sgl_linear_prefill_repack(
        _ptr(source), _ptr(destination), n, k, runtime.stream()
    )
    runtime.check(status, "Netra raw-ASM dense MXFP4 prefill weight repack")
    return destination


@register_custom_op(mutates_args=["output"])
def netra_expert_activation_pack_with_output(
    hidden: torch.Tensor,
    pair_tokens: torch.Tensor,
    position: torch.Tensor,
    output: torch.Tensor,
    pair_count: int,
    total_rows: int,
) -> None:
    """Graph-safe raw gfx1151 routed activation pack."""
    runtime = _get_runtime()
    status = runtime.lib.netra_expert_activation_pack(
        _ptr(hidden),
        _ptr(pair_tokens),
        _ptr(position),
        _ptr(output),
        pair_count,
        total_rows,
        runtime.stream(),
    )
    runtime.check(status, "Netra raw-ASM expert activation pack")


@register_custom_op(mutates_args=["output"])
def netra_mxfp4_linear_with_output(
    packed: torch.Tensor,
    scale: torch.Tensor,
    activation: torch.Tensor,
    output: torch.Tensor,
    m: int,
    n: int,
    k: int,
) -> None:
    """Graph-safe launch boundary for a raw gfx1151 MXFP4 linear."""
    runtime = _get_runtime()
    status = runtime.lib.netra_mxfp4_sgl_linear(
        _ptr(packed),
        _ptr(scale),
        _ptr(activation),
        _ptr(output),
        m,
        n,
        k,
        runtime.stream(),
    )
    runtime.check(status, "Netra raw-ASM MXFP4 linear")


@register_custom_op(mutates_args=["output"])
def netra_mxfp4_linear_prefill_with_output(
    packed: torch.Tensor,
    scale: torch.Tensor,
    activation_groups: torch.Tensor,
    output: torch.Tensor,
    group_count: int,
    n: int,
    k: int,
) -> None:
    """Torch-compile boundary whose compute remains raw gfx1151 AMDGCN."""
    runtime = _get_runtime()
    status = runtime.lib.netra_mxfp4_sgl_linear_prefill(
        _ptr(packed),
        _ptr(scale),
        _ptr(activation_groups),
        _ptr(output),
        group_count,
        n,
        k,
        runtime.stream(),
    )
    runtime.check(status, "Netra raw-ASM MXFP4 linear prefill")


@register_custom_op(mutates_args=["mixed_qkv", "z", "b", "a"])
def netra_qkvzba_split_copy_with_output(
    mixed_qkvz: torch.Tensor,
    mixed_ba: torch.Tensor,
    mixed_qkv: torch.Tensor,
    z: torch.Tensor,
    b: torch.Tensor,
    a: torch.Tensor,
    token_count: int,
) -> None:
    """Torch-compile boundary for the raw gfx1151 split-copy kernel."""
    runtime = _get_runtime()
    status = runtime.lib.netra_qkvzba_split_copy(
        _ptr(mixed_qkvz),
        _ptr(mixed_ba),
        _ptr(mixed_qkv),
        _ptr(z),
        _ptr(b),
        _ptr(a),
        token_count,
        runtime.stream(),
    )
    runtime.check(status, "Netra raw-ASM QKVZ/BA split-copy")


def apply_qkvzba_split_copy(
    mixed_qkvz: torch.Tensor, mixed_ba: torch.Tensor
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor, torch.Tensor]:
    """Allocate graph-visible outputs and launch the gfx1151 raw ASM."""
    if mixed_qkvz.shape[-1] != 12288 or mixed_ba.shape[-1] != 64:
        raise RuntimeError(
            "Netra QKVZ/BA split requires [...,12288] and [...,64] inputs"
        )
    if mixed_qkvz.dtype != torch.bfloat16 or mixed_ba.dtype != torch.bfloat16:
        raise TypeError("Netra QKVZ/BA split requires BF16 inputs")
    if not mixed_qkvz.is_contiguous() or not mixed_ba.is_contiguous():
        raise RuntimeError("Netra QKVZ/BA split requires contiguous inputs")
    token_count = mixed_qkvz.numel() // 12288
    if mixed_ba.numel() != token_count * 64:
        raise RuntimeError("Netra QKVZ and BA token counts must match")
    mixed_qkv = torch.empty(
        (token_count, 8192), dtype=mixed_qkvz.dtype, device=mixed_qkvz.device
    )
    z = torch.empty(
        (token_count, 32, 128),
        dtype=mixed_qkvz.dtype,
        device=mixed_qkvz.device,
    )
    b = torch.empty(
        (token_count, 32), dtype=mixed_ba.dtype, device=mixed_ba.device
    )
    a = torch.empty_like(b)
    netra_qkvzba_split_copy_with_output(
        mixed_qkvz,
        mixed_ba,
        mixed_qkv,
        z,
        b,
        a,
        token_count,
    )
    return mixed_qkv, z, b, a

@register_custom_op(mutates_args=["output"])
def netra_extend_attention_with_output(
    q_extend: torch.Tensor,
    k_extend: torch.Tensor,
    v_extend: torch.Tensor,
    output: torch.Tensor,
    k_buffer: torch.Tensor,
    v_buffer: torch.Tensor,
    kv_indices: torch.Tensor,
    kv_indptr: torch.Tensor,
    token_count: int,
    sm_scale: float,
) -> None:
    """Graph-safe raw gfx1151 M64xN64 extend-attention launch."""
    runtime = _get_runtime()
    status = runtime.lib.netra_extend_attention(
        _ptr(q_extend),
        _ptr(k_extend),
        _ptr(v_extend),
        _ptr(output),
        _ptr(k_buffer),
        _ptr(v_buffer),
        _ptr(kv_indices),
        _ptr(kv_indptr),
        token_count,
        sm_scale,
        runtime.stream(),
    )
    runtime.check(status, "Netra raw-ASM extend attention")



@register_custom_op(mutates_args=["output"])
def netra_gdn_chunk_o_with_output(
    q: torch.Tensor,
    k: torch.Tensor,
    v: torch.Tensor,
    h: torch.Tensor,
    g: torch.Tensor,
    output: torch.Tensor,
    cu_seqlens: torch.Tensor,
    chunk_indices: torch.Tensor,
    scale: float,
    token_count: int,
) -> None:
    """Graph-safe launch for the exact Qwen3.6 8K raw gfx1151 GDN kernel."""
    runtime = _get_runtime()
    status = runtime.lib.netra_gdn_chunk_o(
        _ptr(q),
        _ptr(k),
        _ptr(v),
        _ptr(h),
        _ptr(g),
        _ptr(output),
        _ptr(cu_seqlens),
        _ptr(chunk_indices),
        scale,
        token_count,
        runtime.stream(),
    )
    runtime.check(status, "Netra raw-ASM GDN chunk output")

@register_custom_op(mutates_args=["w", "u"])
def netra_gdn_recompute_w_u_with_output(
    k: torch.Tensor,
    v: torch.Tensor,
    beta: torch.Tensor,
    w: torch.Tensor,
    u: torch.Tensor,
    A: torch.Tensor,
    g: torch.Tensor,
    token_count: int,
) -> None:
    """Graph-safe ordered raw-ASM GDN W/U recompute for Qwen3.6 8K."""
    runtime = _get_runtime()
    status = runtime.lib.netra_gdn_recompute_w_u(
        _ptr(k),
        _ptr(v),
        _ptr(beta),
        _ptr(w),
        _ptr(u),
        _ptr(A),
        _ptr(g),
        token_count,
        runtime.stream(),
    )
    runtime.check(status, "Netra ordered raw-ASM GDN W/U recompute")

def _ensure_decode_workspace(
    layer: torch.nn.Module, device: torch.device
) -> tuple[torch.Tensor, ...]:
    workspace = getattr(layer, "_netra_decode_workspace", None)
    if workspace is None:
        workspace = (
            torch.empty((8, 512), dtype=torch.float32, device=device),
            torch.empty((8, 512), dtype=torch.float32, device=device),
            torch.empty((8, 512), dtype=torch.bfloat16, device=device),
            torch.empty((8, 2048), dtype=torch.float32, device=device),
            torch.empty((1, 2048), dtype=torch.bfloat16, device=device),
        )
        layer._netra_decode_workspace = workspace
    return workspace


def process_weights(layer: torch.nn.Module) -> None:
    """Repack serialized MXFP4 once, retaining four-bit weights in VRAM."""
    split = layer.w13_weight.shape[1] // 2
    gate_weight = layer.w13_weight.data[:, :split, :].transpose(1, 2).contiguous()
    up_weight = layer.w13_weight.data[:, split:, :].transpose(1, 2).contiguous()
    gate_prefill_weight = _repack_prefill_weight(gate_weight)
    up_prefill_weight = _repack_prefill_weight(up_weight)
    gate_scale = (
        layer.w13_weight_scale.data[:, :split, :].transpose(1, 2).contiguous()
    )
    up_scale = (
        layer.w13_weight_scale.data[:, split:, :].transpose(1, 2).contiguous()
    )
    down_weight = layer.w2_weight.data.transpose(1, 2).contiguous()
    down_scale = layer.w2_weight_scale.data.transpose(1, 2).contiguous()

    layer.netra_gate_weight = Parameter(gate_weight, requires_grad=False)
    layer.netra_gate_prefill_weight = Parameter(
        gate_prefill_weight, requires_grad=False
    )
    layer.netra_gate_scale = Parameter(gate_scale, requires_grad=False)
    layer.netra_up_weight = Parameter(up_weight, requires_grad=False)
    layer.netra_up_prefill_weight = Parameter(
        up_prefill_weight, requires_grad=False
    )
    layer.netra_up_scale = Parameter(up_scale, requires_grad=False)
    layer.netra_down_weight = Parameter(down_weight, requires_grad=False)
    layer.netra_down_scale = Parameter(down_scale, requires_grad=False)

    del layer.w13_weight
    del layer.w13_weight_scale
    del layer.w13_weight_bias
    del layer.w2_weight
    del layer.w2_weight_scale
    del layer.w2_weight_bias
    layer._mxfp4_backend = "netra_gfx1151_raw_asm"

    # Graph capture must not perform module loading or persistent allocation.
    # Load every raw gfx1151 code object and allocate stable decode pointers as
    # part of model initialization, before SGLang begins graph capture.
    _get_runtime()
    _ensure_decode_workspace(layer, layer.netra_gate_weight.device)
    torch.cuda.empty_cache()


class NetraMxfp4LinearMethod(LinearMethodBase):
    """Serialized MXFP4 linear using only Netra raw gfx1151 assembly."""

    def create_weights(
        self,
        layer: torch.nn.Module,
        input_size_per_partition: int,
        output_partition_sizes: List[int],
        input_size: int,
        output_size: int,
        params_dtype: torch.dtype,
        **extra_weight_attrs,
    ) -> None:
        del input_size, output_size, params_dtype
        output_size_per_partition = sum(output_partition_sizes)
        weight_loader = extra_weight_attrs.get("weight_loader")
        layer.netra_input_size = input_size_per_partition
        layer.netra_output_size = output_size_per_partition

        packed = ModelWeightParameter(
            data=torch.empty(
                output_size_per_partition,
                input_size_per_partition // 2,
                dtype=torch.uint8,
            ),
            input_dim=1,
            output_dim=0,
            weight_loader=weight_loader,
        )
        layer.register_parameter("weight_packed", packed)

        scale = ModelWeightParameter(
            data=torch.empty(
                output_size_per_partition,
                input_size_per_partition // 32,
                dtype=torch.uint8,
            ),
            input_dim=1,
            output_dim=0,
            weight_loader=weight_loader,
        )
        layer.register_parameter("weight_scale", scale)

    def process_weights_after_loading(self, layer: torch.nn.Module) -> None:
        # The raw kernel walks K-major rows, so transpose the serialized [N,K/x]
        # tensors once at load time. The representation remains packed MXFP4.
        layer.netra_linear_weight = Parameter(
            layer.weight_packed.data.transpose(0, 1).contiguous(),
            requires_grad=False,
        )
        layer.netra_linear_scale = Parameter(
            layer.weight_scale.data.transpose(0, 1).contiguous(),
            requires_grad=False,
        )
        layer.netra_linear_prefill_weight = Parameter(
            _repack_linear_prefill_weight(
                layer.netra_linear_weight,
                layer.netra_output_size,
                layer.netra_input_size,
            ),
            requires_grad=False,
        )
        del layer.weight_packed
        del layer.weight_scale
        layer._mxfp4_backend = "netra_gfx1151_raw_asm_linear"

        # Qwen3.6 GDN marks the paired QKVZ and BA modules with weak peer
        # references. BA is visited second by SGLang's quant post-processing,
        # so both packed raw-ASM layouts are stable at this point.
        if getattr(layer, "_netra_qkvz_ba_role", None) == "ba":
            peer_ref = getattr(layer, "_netra_qkvz_ba_peer", None)
            qkvz_layer = peer_ref() if peer_ref is not None else None
            if qkvz_layer is not None and hasattr(
                qkvz_layer, "netra_linear_weight"
            ):
                _prepare_qkvz_ba_decode_fusion(qkvz_layer, layer)

    def apply(
        self,
        layer: torch.nn.Module,
        x: torch.Tensor,
        bias: Optional[torch.Tensor] = None,
    ) -> torch.Tensor:
        if x.dtype != torch.bfloat16:
            raise TypeError(
                f"Netra MXFP4 linear expects BF16 activation, got {x.dtype}"
            )
        original_shape = x.shape
        k = original_shape[-1]
        n = layer.netra_output_size
        flat_x = x.reshape(-1, k).contiguous()
        if flat_x.shape[0] == 1:
            output = torch.empty((1, n), dtype=torch.bfloat16, device=x.device)
            netra_mxfp4_linear_with_output(
                layer.netra_linear_weight,
                layer.netra_linear_scale,
                flat_x,
                output,
                1,
                n,
                k,
            )
        else:
            group_count = (flat_x.shape[0] + 63) // 64
            activation_groups = torch.zeros(
                (group_count, 64, k), dtype=torch.bfloat16, device=x.device
            )
            activation_groups.view(-1, k)[: flat_x.shape[0]].copy_(flat_x)
            output_groups = torch.empty(
                (group_count, 64, n), dtype=torch.float32, device=x.device
            )
            if torch.compiler.is_compiling():
                netra_mxfp4_linear_prefill_with_output(
                    layer.netra_linear_prefill_weight,
                    layer.netra_linear_scale,
                    activation_groups,
                    output_groups,
                    group_count,
                    n,
                    k,
                )
            else:
                runtime = _get_runtime()
                status = runtime.lib.netra_mxfp4_sgl_linear_prefill(
                    _ptr(layer.netra_linear_prefill_weight),
                    _ptr(layer.netra_linear_scale),
                    _ptr(activation_groups),
                    _ptr(output_groups),
                    group_count,
                    n,
                    k,
                    runtime.stream(),
                )
                runtime.check(status, "Netra raw-ASM MXFP4 linear prefill")
            output = output_groups.view(-1, n)[: flat_x.shape[0]].to(
                torch.bfloat16
            )
        if bias is not None:
            output.add_(bias)
        return output.view(*original_shape[:-1], n)


def _prepare_qkvz_ba_decode_fusion(
    qkvz_layer: torch.nn.Module, ba_layer: torch.nn.Module
) -> None:
    """Build stable load-time pointers for the M=1 QKVZ+BA raw-ASM fusion."""
    if hasattr(qkvz_layer, "netra_qkvz_ba_weight"):
        return
    if (
        qkvz_layer.netra_input_size != 2048
        or qkvz_layer.netra_output_size != 12288
        or ba_layer.netra_input_size != 2048
        or ba_layer.netra_output_size != 64
    ):
        return
    fused_n = 12288 + 64
    padded_n = ((fused_n + 511) // 512) * 512
    pad = padded_n - fused_n
    weight = torch.cat(
        (qkvz_layer.netra_linear_weight, ba_layer.netra_linear_weight), dim=1
    )
    scale = torch.cat(
        (qkvz_layer.netra_linear_scale, ba_layer.netra_linear_scale), dim=1
    )
    qkvz_layer.netra_qkvz_ba_weight = Parameter(
        torch.nn.functional.pad(weight, (0, pad)).contiguous(),
        requires_grad=False,
    )
    qkvz_layer.netra_qkvz_ba_scale = Parameter(
        torch.nn.functional.pad(scale, (0, pad)).contiguous(),
        requires_grad=False,
    )
    qkvz_layer.netra_qkvz_ba_padded_n = padded_n
    qkvz_layer.netra_qkvz_ba_output = torch.empty(
        (1, padded_n), dtype=torch.bfloat16,
        device=qkvz_layer.netra_qkvz_ba_weight.device,
    )


def apply_qkvz_ba_decode_fused(
    qkvz_layer: torch.nn.Module, x: torch.Tensor
) -> tuple[torch.Tensor, torch.Tensor]:
    """One raw gfx1151 dispatch for Qwen3.6 M=1 QKVZ and BA projections."""
    if x.dtype != torch.bfloat16 or x.shape != (1, 2048):
        raise ValueError(f"QKVZ+BA fusion requires BF16 [1,2048], got {x.shape}")
    padded_n = qkvz_layer.netra_qkvz_ba_padded_n
    output = qkvz_layer.netra_qkvz_ba_output
    netra_mxfp4_linear_with_output(
        qkvz_layer.netra_qkvz_ba_weight,
        qkvz_layer.netra_qkvz_ba_scale,
        x.contiguous(),
        output,
        1,
        padded_n,
        2048,
    )
    return output[:, :12288], output[:, 12288:12352]


def _decode(
    layer: torch.nn.Module,
    hidden_states: torch.Tensor,
    topk_weights: torch.Tensor,
    topk_ids: torch.Tensor,
) -> torch.Tensor:
    runtime = _get_runtime()
    ids = topk_ids.reshape(8).to(dtype=torch.int32).contiguous()
    weights = topk_weights.reshape(8).to(dtype=torch.float32).contiguous()
    x = hidden_states.reshape(2048).contiguous()

    gate_tmp, up_tmp, intermediate, expert_output, output = (
        _ensure_decode_workspace(layer, x.device)
    )

    status = runtime.lib.netra_mxfp4_sgl_decode(
        _ptr(layer.netra_gate_weight),
        _ptr(layer.netra_gate_scale),
        _ptr(layer.netra_up_weight),
        _ptr(layer.netra_up_scale),
        _ptr(layer.netra_down_weight),
        _ptr(layer.netra_down_scale),
        _ptr(x),
        _ptr(ids),
        _ptr(weights),
        _ptr(gate_tmp),
        _ptr(up_tmp),
        _ptr(intermediate),
        _ptr(expert_output),
        _ptr(output),
        runtime.stream(),
    )
    runtime.check(status, "Netra raw-ASM decode")
    return output


def _prefill(
    layer: torch.nn.Module,
    hidden_states: torch.Tensor,
    topk_weights: torch.Tensor,
    topk_ids: torch.Tensor,
) -> torch.Tensor:
    runtime = _get_runtime()
    token_count = hidden_states.shape[0]
    flat_ids = topk_ids.reshape(-1)
    flat_weights = topk_weights.reshape(-1).to(torch.float32)
    sorted_ids, order = torch.sort(flat_ids)
    pair_count = sorted_ids.numel()
    expert_count = layer.netra_gate_weight.shape[0]
    group_count = (
        pair_count
        if pair_count <= expert_count
        else expert_count + (pair_count - expert_count) // 64
    )
    sequence = torch.arange(pair_count, device=hidden_states.device)
    new_expert = torch.ones(pair_count, dtype=torch.bool, device=hidden_states.device)
    new_expert[1:] = sorted_ids[1:] != sorted_ids[:-1]
    expert_start = torch.where(new_expert, sequence, 0)
    expert_start = torch.cummax(expert_start, dim=0).values
    rank_in_expert = sequence - expert_start
    new_group = new_expert | ((rank_in_expert & 63) == 0)
    group_index = torch.cumsum(new_group.to(torch.int64), dim=0) - 1
    position = group_index * 64 + (rank_in_expert & 63)
    group_expert_ids = torch.zeros(
        group_count, dtype=torch.int32, device=hidden_states.device
    )
    group_expert_ids.scatter_(0, group_index, sorted_ids.to(torch.int32))
    pair_tokens = torch.div(order, 8, rounding_mode="floor")

    activation_groups = torch.empty(
        (group_count, 64, 2048),
        dtype=torch.bfloat16,
        device=hidden_states.device,
    )
    netra_expert_activation_pack_with_output(
        hidden_states,
        pair_tokens,
        position,
        activation_groups,
        pair_count,
        group_count * 64,
    )
    gate_output = torch.empty(
        (group_count, 64, 512), dtype=torch.float32, device=hidden_states.device
    )
    up_output = torch.empty_like(gate_output)
    intermediate = torch.empty(
        (group_count, 64, 512), dtype=torch.bfloat16, device=hidden_states.device
    )
    expert_output = torch.empty(
        (group_count, 64, 2048), dtype=torch.float32, device=hidden_states.device
    )

    status = runtime.lib.netra_mxfp4_sgl_prefill_gate_up(
        _ptr(layer.netra_gate_prefill_weight),
        _ptr(layer.netra_gate_scale),
        _ptr(layer.netra_up_prefill_weight),
        _ptr(layer.netra_up_scale),
        _ptr(activation_groups),
        _ptr(group_expert_ids),
        _ptr(gate_output),
        _ptr(up_output),
        _ptr(intermediate),
        group_count,
        runtime.stream(),
    )
    runtime.check(status, "Netra raw-ASM grouped gate/up")
    status = runtime.lib.netra_mxfp4_sgl_prefill_down(
        _ptr(layer.netra_down_weight),
        _ptr(layer.netra_down_scale),
        _ptr(intermediate),
        _ptr(expert_output),
        _ptr(group_expert_ids),
        group_count,
        runtime.stream(),
    )
    runtime.check(status, "Netra raw-ASM grouped down")

    sorted_pair_output = expert_output.view(-1, 2048).index_select(0, position)
    sorted_pair_output.mul_(flat_weights.index_select(0, order)[:, None])
    output = torch.zeros(
        (token_count, 2048), dtype=torch.float32, device=hidden_states.device
    )
    output.index_add_(0, pair_tokens, sorted_pair_output)
    return output.to(torch.bfloat16)


def apply(
    layer: torch.nn.Module,
    hidden_states: torch.Tensor,
    topk_weights: torch.Tensor,
    topk_ids: torch.Tensor,
) -> torch.Tensor:
    if hidden_states.dtype != torch.bfloat16:
        raise TypeError(f"Netra MXFP4 expects BF16 activation, got {hidden_states.dtype}")
    if hidden_states.shape[-1] != 2048:
        raise ValueError(f"Netra MXFP4 expects K=2048, got {hidden_states.shape}")
    if topk_ids.shape[-1] != 8:
        raise ValueError(f"Netra MXFP4 expects top-k=8, got {topk_ids.shape}")
    if hidden_states.shape[0] == 1:
        return _decode(layer, hidden_states, topk_weights, topk_ids)
    return _prefill(layer, hidden_states, topk_weights, topk_ids)
