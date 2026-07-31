#!/usr/bin/env python3
"""Export a retained Qwen3.6 M=1 AITER stage-1 capture and FP32 oracle."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import torch


def unshuffle_aiter_fp8_weight(weight: torch.Tensor) -> torch.Tensor:
    """Restore logical [E,N,K] from AITER's physical (16,16) layout."""

    experts, n_dim, k_dim = weight.shape
    if n_dim % 16 or k_dim % 32:
        raise ValueError(f"cannot unshuffle weight shape {tuple(weight.shape)}")
    return (
        weight.view(experts, n_dim // 16, k_dim // 32, 2, 16, 16)
        .permute(0, 1, 4, 2, 3, 5)
        .contiguous()
        .view(experts, n_dim, k_dim)
    )


def tensor_bytes(tensor: torch.Tensor) -> bytes:
    return tensor.detach().contiguous().view(torch.uint8).numpy().tobytes()


def write_tensor(output_dir: Path, name: str, tensor: torch.Tensor) -> dict:
    payload = tensor_bytes(tensor.cpu())
    path = output_dir / f"{name}.bin"
    path.write_bytes(payload)
    return {
        "file": path.name,
        "shape": list(tensor.shape),
        "dtype": str(tensor.dtype),
        "bytes": len(payload),
        "sha256": hashlib.sha256(payload).hexdigest(),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    input_quant = torch.load(
        args.capture_dir / "aiter_moe_input_quant_000.pt",
        map_location="cpu",
        weights_only=True,
    )
    activation = torch.load(
        args.capture_dir / "aiter_moe_activation_000.pt",
        map_location="cpu",
        weights_only=True,
    )
    call = torch.load(
        args.capture_dir / "aiter_moe_call_000.pt",
        map_location="cpu",
        weights_only=True,
    )

    selected_ids = call["selected_expert_ids_i32"].to(torch.int64)
    topk_ids = call["topk_ids_i32"].to(torch.int64)
    lookup = {
        int(expert_id): index for index, expert_id in enumerate(selected_ids.tolist())
    }
    compact_ids = torch.tensor(
        [[lookup[int(expert_id)] for expert_id in topk_ids.view(-1).tolist()]],
        dtype=torch.int32,
    )
    hidden_fp8 = input_quant["hidden_states_fp8"].contiguous()
    hidden_scale = input_quant["hidden_states_scale"].contiguous()
    selected_w1 = call["selected_w1_fp8"].contiguous()
    logical_w1 = unshuffle_aiter_fp8_weight(selected_w1)
    selected_w1_scale = call["selected_w1_scale"].contiguous()
    aiter_stage1 = activation["stage1_fp32"].contiguous()

    if tuple(hidden_fp8.shape) != (1, 2048):
        raise ValueError(f"unexpected hidden FP8 shape: {hidden_fp8.shape}")
    if tuple(hidden_scale.shape) != (1, 16):
        raise ValueError(f"unexpected hidden scale shape: {hidden_scale.shape}")
    if tuple(selected_w1.shape) != (9, 1024, 2048):
        raise ValueError(f"unexpected selected w1 shape: {selected_w1.shape}")
    if tuple(selected_w1_scale.shape) != (9, 8, 16):
        raise ValueError(f"unexpected selected w1 scale: {selected_w1_scale.shape}")
    if tuple(aiter_stage1.shape) != (9, 1024):
        raise ValueError(f"unexpected AITER stage1 output: {aiter_stage1.shape}")

    hidden_f32 = hidden_fp8.float().view(2048)
    reference = torch.empty((9, 1024), dtype=torch.float32)
    for slot, compact_expert in enumerate(compact_ids.view(-1).tolist()):
        slot_output = torch.zeros(1024, dtype=torch.float32)
        for k_block in range(16):
            k_start = k_block * 128
            k_end = k_start + 128
            activation_block = (
                hidden_f32[k_start:k_end] * hidden_scale[0, k_block]
            )
            weight_block = logical_w1[
                compact_expert, :, k_start:k_end
            ].float()
            weight_block *= selected_w1_scale[
                compact_expert, :, k_block
            ].repeat_interleave(128)[:, None]
            slot_output.add_(torch.mv(weight_block, activation_block))
        reference[slot] = slot_output

    delta = aiter_stage1 - reference
    tensors = {
        "hidden_states_fp8": hidden_fp8,
        "hidden_states_scale_f32": hidden_scale,
        "selected_w1_fp8": selected_w1,
        "selected_w1_scale_f32": selected_w1_scale,
        "compact_topk_ids_i32": compact_ids,
        "aiter_stage1_f32": aiter_stage1,
        "reference_stage1_f32": reference,
    }
    manifest = {
        "schema_version": 1,
        "architecture": "gfx950",
        "quantization": "FP8 E4M3, 128x128 blocks",
        "weight_layout": {
            "resident": "AITER shuffle_weight layout=(16,16)",
            "oracle": "logical [expert,n,k] after inverse shuffle",
        },
        "shape": {
            "slots": 9,
            "experts": 9,
            "n": 1024,
            "k": 2048,
        },
        "selected_expert_ids": selected_ids.tolist(),
        "topk_expert_ids": topk_ids.view(-1).tolist(),
        "compact_topk_ids": compact_ids.view(-1).tolist(),
        "aiter_vs_reference": {
            "maximum_absolute_error": float(delta.abs().max().item()),
            "mean_absolute_error": float(delta.abs().mean().item()),
            "cosine": float(
                torch.nn.functional.cosine_similarity(
                    aiter_stage1.view(1, -1),
                    reference.view(1, -1),
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
