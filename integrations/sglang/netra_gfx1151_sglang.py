"""SGLang bridge for Netra's raw AMDGCN MXFP4 kernels on gfx1151."""

from __future__ import annotations

import ctypes
from typing import List, Optional

import torch
from sglang.srt.layers.parameter import ModelWeightParameter
from sglang.srt.layers.quantization.base_config import LinearMethodBase
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
    gate_scale = (
        layer.w13_weight_scale.data[:, :split, :].transpose(1, 2).contiguous()
    )
    up_scale = (
        layer.w13_weight_scale.data[:, split:, :].transpose(1, 2).contiguous()
    )
    down_weight = layer.w2_weight.data.transpose(1, 2).contiguous()
    down_scale = layer.w2_weight_scale.data.transpose(1, 2).contiguous()

    layer.netra_gate_weight = Parameter(gate_weight, requires_grad=False)
    layer.netra_gate_scale = Parameter(gate_scale, requires_grad=False)
    layer.netra_up_weight = Parameter(up_weight, requires_grad=False)
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
        runtime = _get_runtime()
        if flat_x.shape[0] == 1:
            output = torch.empty((1, n), dtype=torch.bfloat16, device=x.device)
            status = runtime.lib.netra_mxfp4_sgl_linear(
                _ptr(layer.netra_linear_weight),
                _ptr(layer.netra_linear_scale),
                _ptr(flat_x),
                _ptr(output),
                1,
                n,
                k,
                runtime.stream(),
            )
            runtime.check(status, "Netra raw-ASM MXFP4 linear decode")
        else:
            group_count = (flat_x.shape[0] + 63) // 64
            activation_groups = torch.zeros(
                (group_count, 64, k), dtype=torch.bfloat16, device=x.device
            )
            activation_groups.view(-1, k)[: flat_x.shape[0]].copy_(flat_x)
            output_groups = torch.empty(
                (group_count, 64, n), dtype=torch.float32, device=x.device
            )
            status = runtime.lib.netra_mxfp4_sgl_linear_prefill(
                _ptr(layer.netra_linear_weight),
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
    runtime = _get_runtime()
    padded_n = qkvz_layer.netra_qkvz_ba_padded_n
    output = qkvz_layer.netra_qkvz_ba_output
    status = runtime.lib.netra_mxfp4_sgl_linear(
        _ptr(qkvz_layer.netra_qkvz_ba_weight),
        _ptr(qkvz_layer.netra_qkvz_ba_scale),
        _ptr(x.contiguous()),
        _ptr(output),
        1,
        padded_n,
        2048,
        runtime.stream(),
    )
    runtime.check(status, "Netra raw-ASM fused QKVZ+BA decode")
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
    sequence = torch.arange(pair_count, device=hidden_states.device)
    new_expert = torch.ones(pair_count, dtype=torch.bool, device=hidden_states.device)
    new_expert[1:] = sorted_ids[1:] != sorted_ids[:-1]
    expert_start = torch.where(new_expert, sequence, 0)
    expert_start = torch.cummax(expert_start, dim=0).values
    rank_in_expert = sequence - expert_start
    new_group = new_expert | ((rank_in_expert & 63) == 0)
    group_index = torch.cumsum(new_group.to(torch.int64), dim=0) - 1
    group_count = int(group_index[-1].item()) + 1
    position = group_index * 64 + (rank_in_expert & 63)
    group_expert_ids = sorted_ids[new_group].to(torch.int32).contiguous()
    pair_tokens = torch.div(order, 8, rounding_mode="floor")

    activation_groups = torch.zeros(
        (group_count, 64, 2048),
        dtype=torch.bfloat16,
        device=hidden_states.device,
    )
    activation_groups.view(-1, 2048).index_copy_(
        0, position, hidden_states.index_select(0, pair_tokens)
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
        _ptr(layer.netra_gate_weight),
        _ptr(layer.netra_gate_scale),
        _ptr(layer.netra_up_weight),
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
