#!/usr/bin/env python3
"""Export a retained real Qwen3.6 grouped-MoE full expert-compute capture.

The retained AITER sorted IDs use ``(topk_slot << 24) | token_row``. This
exporter preserves that deployed ABI, compacts the active expert weights, and
builds a float32 structural oracle from the checkpoint's FP8 E4M3 values and
128x128 scales. It is an offline correctness tool, never a serving path.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import torch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--device", default="cuda")
    return parser.parse_args()


def tensor_bytes(tensor: torch.Tensor) -> bytes:
    return tensor.detach().contiguous().cpu().view(torch.uint8).numpy().tobytes()


def write_tensor(
    output_dir: Path, name: str, tensor: torch.Tensor
) -> dict[str, object]:
    payload = tensor_bytes(tensor)
    path = output_dir / f"{name}.bin"
    path.write_bytes(payload)
    return {
        "file": path.name,
        "shape": list(tensor.shape),
        "dtype": str(tensor.dtype),
        "bytes": len(payload),
        "sha256": hashlib.sha256(payload).hexdigest(),
    }


def unshuffle_aiter_16x16(weight: torch.Tensor) -> torch.Tensor:
    """Invert AITER shuffle_weight(weight, (16, 16)) for FP8 bytes."""
    experts, n_dim, k_dim = weight.shape
    return (
        weight.view(experts, n_dim // 16, k_dim // 32, 2, 16, 16)
        .permute(0, 1, 4, 2, 3, 5)
        .contiguous()
        .view(experts, n_dim, k_dim)
    )


def main() -> None:
    args = parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    call = torch.load(
        args.capture_dir / "aiter_moe_call_000.pt",
        map_location="cpu",
        weights_only=True,
    )
    stage2 = torch.load(
        args.capture_dir / "aiter_moe_stage2_000.pt",
        map_location="cpu",
        weights_only=True,
    )
    input_quant = torch.load(
        args.capture_dir / "aiter_moe_input_quant_000.pt",
        map_location="cpu",
        weights_only=True,
    )
    quant = torch.load(
        args.capture_dir / "aiter_moe_quant_000.pt",
        map_location="cpu",
        weights_only=True,
    )

    rows, topk, hidden, inter, block_m = 1024, 9, 2048, 512, 16
    activation = stage2["inter_states"].contiguous()
    activation_scale = stage2["a2_scale"].contiguous()
    topk_ids = call["topk_ids_i32"].to(torch.int64).contiguous()
    topk_weights = call["topk_weights_fp32"].contiguous()
    expert_ids = stage2["resident_expert_ids_i32"].to(torch.int64).contiguous()
    selected_expert_ids = call["selected_expert_ids_i32"].to(torch.int64).contiguous()
    hidden_fp8 = input_quant["hidden_states_fp8"].contiguous()
    hidden_scale = input_quant["hidden_states_scale"].contiguous()
    w13 = call["selected_w1_fp8"].contiguous()
    w13_scale = call["selected_w1_scale"].contiguous()
    weights = stage2["resident_w2_fp8"].contiguous()
    # AITER presents the original FP32 [E,16,4] bytes through an E8M0
    # [E,16,16] view at ck_moe_stage2_fwd. Recover the underlying FP32 view.
    resident_scale = stage2["resident_w2_scale"].contiguous()
    weight_scale = resident_scale.view(torch.float32).reshape(-1, 16, 4)
    sorted_tokens = stage2["sorted_token_ids"].to(torch.int32).contiguous()
    sorted_experts = stage2["sorted_expert_ids"].to(torch.int64).contiguous()
    num_valid = int(stage2["num_valid_ids"].view(-1)[0].item())

    expected_shapes = {
        "activation": (rows, topk, inter),
        "activation_scale": (rows, topk, 4),
        "topk_ids": (rows, topk),
        "topk_weights": (rows, topk),
        "hidden_fp8": (rows, hidden),
        "hidden_scale": (rows, 16),
        "w13_tail": (1024, hidden),
        "w13_scale_tail": (8, 16),
        "weights_tail": (hidden, inter),
        "weight_scale_tail": (16, 4),
    }
    actual_shapes = {
        "activation": tuple(activation.shape),
        "activation_scale": tuple(activation_scale.shape),
        "topk_ids": tuple(topk_ids.shape),
        "topk_weights": tuple(topk_weights.shape),
        "hidden_fp8": tuple(hidden_fp8.shape),
        "hidden_scale": tuple(hidden_scale.shape),
        "w13_tail": tuple(w13.shape[1:]),
        "w13_scale_tail": tuple(w13_scale.shape[1:]),
        "weights_tail": tuple(weights.shape[1:]),
        "weight_scale_tail": tuple(weight_scale.shape[1:]),
    }
    if actual_shapes != expected_shapes:
        raise ValueError(f"unexpected grouped capture shapes: {actual_shapes}")
    if expert_ids.numel() != weights.shape[0] or weights.shape[0] != weight_scale.shape[0]:
        raise ValueError("active expert tensors disagree")
    if not torch.equal(expert_ids, selected_expert_ids):
        raise ValueError("captured W13 and W2 expert sets or ordering disagree")
    if w13.shape[0] != expert_ids.numel() or w13_scale.shape[0] != expert_ids.numel():
        raise ValueError("active W13 tensors disagree")
    if num_valid % block_m:
        raise ValueError(f"num_valid={num_valid} is not block-M{block_m} aligned")

    compact_by_global = {int(value): index for index, value in enumerate(expert_ids.tolist())}
    valid_blocks = num_valid // block_m
    compact_sorted_experts = torch.zeros_like(sorted_experts, dtype=torch.int32)
    for block in range(valid_blocks):
        global_expert = int(sorted_experts[block].item())
        try:
            compact_sorted_experts[block] = compact_by_global[global_expert]
        except KeyError as error:
            raise ValueError(f"sorted expert {global_expert} was not retained") from error

    device = torch.device(args.device)
    if device.type == "cuda":
        properties = torch.cuda.get_device_properties(device)
        arch = getattr(properties, "gcnArchName", "")
        if not str(arch).startswith("gfx950"):
            raise RuntimeError(f"refusing structural oracle on non-gfx950 device: {arch}")
    hidden_device = hidden_fp8.to(device).float().reshape(rows, 16, 128)
    hidden_device.mul_(hidden_scale.to(device)[:, :, None])
    topk_ids_device = topk_ids.to(device)
    logical_w13_device = unshuffle_aiter_16x16(w13.to(device))
    w13_scale_device = w13_scale.to(device)
    stage1_reference = torch.zeros(
        (rows, topk, inter * 2), dtype=torch.float32, device=device
    )
    for compact_expert, global_expert in enumerate(expert_ids.tolist()):
        route_positions = torch.nonzero(
            topk_ids_device == int(global_expert), as_tuple=False
        )
        if route_positions.numel() == 0:
            raise ValueError(f"retained expert {global_expert} has no routes")
        token_rows = route_positions[:, 0]
        slots = route_positions[:, 1]
        w13_dequant = logical_w13_device[compact_expert].float().reshape(
            8, 128, 16, 128
        )
        w13_dequant.mul_(w13_scale_device[compact_expert, :, None, :, None])
        stage1_reference[token_rows, slots] = hidden_device[
            token_rows
        ].reshape(-1, hidden) @ w13_dequant.reshape(inter * 2, hidden).T
    stage1_reference_bf16 = stage1_reference.to(torch.bfloat16)
    activation_reference_bf16 = (
        torch.nn.functional.silu(stage1_reference[:, :, :inter])
        * stage1_reference[:, :, inter:]
    ).to(torch.bfloat16)
    captured_activation_bf16 = quant["activation_bf16"].to(device)
    activation_delta = (
        captured_activation_bf16.float() - activation_reference_bf16.float()
    )

    reference = torch.zeros((rows, hidden), dtype=torch.float32, device=device)
    activation_device = activation.to(device)
    activation_scale_device = activation_scale.to(device)
    topk_weights_device = topk_weights.to(device)
    weights_device = weights.to(device)
    logical_weights_device = unshuffle_aiter_16x16(weights_device)
    weight_scale_device = weight_scale.to(device)
    for compact_expert, global_expert in enumerate(expert_ids.tolist()):
        route_positions = torch.nonzero(
            topk_ids_device == int(global_expert), as_tuple=False
        )
        if route_positions.numel() == 0:
            raise ValueError(f"retained expert {global_expert} has no routes")
        token_rows = route_positions[:, 0]
        slots = route_positions[:, 1]
        a = activation_device[token_rows, slots].float().reshape(-1, 4, 128)
        a.mul_(activation_scale_device[token_rows, slots, :, None])
        w = logical_weights_device[compact_expert].float().reshape(
            16, 128, 4, 128
        )
        w.mul_(weight_scale_device[compact_expert, :, None, :, None])
        route_output = a.reshape(-1, inter) @ w.reshape(hidden, inter).T
        route_output.mul_(topk_weights_device[token_rows, slots, None])
        reference.index_add_(0, token_rows, route_output)
    torch.cuda.synchronize(device) if device.type == "cuda" else None
    reference_cpu = reference.cpu()
    aiter_output = stage2["output_bf16"].contiguous()
    delta = aiter_output.float() - reference_cpu

    tensors = {
        "hidden_fp8": hidden_fp8,
        "hidden_scale_f32": hidden_scale,
        "active_w13_fp8": w13,
        "active_w13_scale_f32": w13_scale,
        "activation_fp8": activation,
        "activation_scale_f32": activation_scale,
        "activation_bf16": quant["activation_bf16"].contiguous(),
        "reference_stage1_bf16": stage1_reference_bf16.cpu(),
        "reference_activation_bf16": activation_reference_bf16.cpu(),
        "active_w2_fp8": weights,
        "active_w2_scale_f32": weight_scale,
        "sorted_token_ids_i32": sorted_tokens,
        "compact_sorted_expert_ids_i32": compact_sorted_experts,
        "num_valid_ids_i32": torch.tensor([num_valid], dtype=torch.int32),
        "topk_weights_f32": topk_weights,
        "aiter_output_bf16": aiter_output,
        "reference_output_f32": reference_cpu,
        "reference_output_bf16": reference_cpu.to(torch.bfloat16),
    }
    manifest = {
        "schema_version": 2,
        "quantization": "FP8 E4M3, 128x128 blocks",
        "sorted_token_encoding": "(topk_slot << 24) | token_row; slot 9 is padding",
        "shape": {
            "rows": rows,
            "topk": topk,
            "hidden": hidden,
            "intermediate": inter,
            "block_m": block_m,
            "active_experts": expert_ids.numel(),
            "sorted_capacity": sorted_tokens.numel(),
            "valid_sorted_ids": num_valid,
        },
        "active_global_expert_ids": expert_ids.tolist(),
        "aiter_vs_reference": {
            "bf16_mismatches": int(
                torch.ne(aiter_output, reference_cpu.to(torch.bfloat16)).sum().item()
            ),
            "max_abs": float(delta.abs().max().item()),
            "mean_abs": float(delta.abs().mean().item()),
            "cosine": float(
                torch.nn.functional.cosine_similarity(
                    aiter_output.float().reshape(1, -1),
                    reference_cpu.reshape(1, -1),
                ).item()
            ),
        },
        "aiter_activation_vs_reference": {
            "bf16_mismatches": int(
                torch.ne(
                    captured_activation_bf16, activation_reference_bf16
                ).sum().item()
            ),
            "max_abs": float(activation_delta.abs().max().item()),
            "mean_abs": float(activation_delta.abs().mean().item()),
            "cosine": float(
                torch.nn.functional.cosine_similarity(
                    captured_activation_bf16.float().reshape(1, -1),
                    activation_reference_bf16.float().reshape(1, -1),
                ).item()
            ),
        },
        "tensors": {
            name: write_tensor(args.output_dir, name, tensor)
            for name, tensor in tensors.items()
        },
    }
    (args.output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(manifest, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
