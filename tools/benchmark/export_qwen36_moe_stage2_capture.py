#!/usr/bin/env python3
"""Export a retained SGLang/AITER M=1 MoE stage-2 capture as raw binaries."""

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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    return parser.parse_args()


def tensor_bytes(tensor: torch.Tensor) -> bytes:
    return tensor.detach().contiguous().cpu().view(torch.uint8).numpy().tobytes()


def write_tensor(
    output_dir: Path,
    name: str,
    tensor: torch.Tensor,
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


def main() -> None:
    args = parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    activation = torch.load(
        args.capture_dir / "aiter_moe_quant_000.pt",
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
    compact_lookup = {
        int(expert_id): index for index, expert_id in enumerate(selected_ids.tolist())
    }
    compact_topk_ids = torch.tensor(
        [[compact_lookup[int(expert_id)] for expert_id in topk_ids[0].tolist()]],
        dtype=torch.int32,
    )

    activation_fp8 = activation["activation_fp8"].contiguous()
    activation_scale = activation["activation_scale"].contiguous()
    selected_w2 = call["selected_w2_fp8"].contiguous()
    logical_w2 = unshuffle_aiter_fp8_weight(selected_w2)
    selected_w2_scale = call["selected_w2_scale"].contiguous()
    topk_weights = call["topk_weights_fp32"].contiguous()
    aiter_output = call["output_bf16"].contiguous()

    slots, k_dim = activation_fp8.shape[-2:]
    experts, n_dim, weight_k = selected_w2.shape
    if (slots, k_dim, experts, n_dim, weight_k) != (9, 512, 9, 2048, 512):
        raise ValueError(
            "capture is not the Qwen3.6 M=1 stage-2 shape: "
            f"{(slots, k_dim, experts, n_dim, weight_k)}"
        )
    if tuple(activation_scale.shape) != (1, 9, 4):
        raise ValueError(f"unexpected activation scales: {activation_scale.shape}")
    if tuple(selected_w2_scale.shape) != (9, 16, 4):
        raise ValueError(f"unexpected weight scales: {selected_w2_scale.shape}")

    # High-precision structural oracle using the checkpoint's FP8 E4M3 values
    # and 128x128 dequantization scales. The compact weight tensor is sorted by
    # expert ID, so compact_topk_ids maps each routed slot back to its slice.
    activation_f32 = activation_fp8.float().view(slots, k_dim)

    def calculate_reference(
        slot_experts: list[int],
        slot_weights: torch.Tensor,
    ) -> torch.Tensor:
        result = torch.zeros((1, n_dim), dtype=torch.float32)
        for slot, expert in enumerate(slot_experts):
            slot_output = torch.zeros(n_dim, dtype=torch.float32)
            for k_block in range(4):
                k_start = k_block * 128
                k_end = k_start + 128
                a = (
                    activation_f32[slot, k_start:k_end]
                    * activation_scale[0, slot, k_block]
                )
                w = logical_w2[expert, :, k_start:k_end].float()
                w = w * selected_w2_scale[
                    expert, :, k_block
                ].repeat_interleave(128)[:, None]
                slot_output.add_(torch.mv(w, a))
            result.add_(slot_output * slot_weights[slot])
        return result

    topk_order_reference = calculate_reference(
        compact_topk_ids.view(-1).tolist(),
        topk_weights.view(-1),
    )
    # AITER's sorted stage-1 output can be expert-major rather than original
    # top-k-slot-major. Retain both interpretations and choose against the
    # deployed stage-2 output instead of assuming the intermediate layout.
    weight_by_compact_expert = torch.empty(slots, dtype=torch.float32)
    for slot, expert in enumerate(compact_topk_ids.view(-1).tolist()):
        weight_by_compact_expert[expert] = topk_weights.view(-1)[slot]
    sorted_expert_reference = calculate_reference(
        list(range(slots)),
        weight_by_compact_expert,
    )
    aiter_output_f32 = aiter_output.float()

    def comparison(reference: torch.Tensor) -> dict[str, float | int]:
        delta = aiter_output_f32 - reference
        return {
            "bf16_mismatches": int(
                torch.ne(aiter_output, reference.to(torch.bfloat16)).sum().item()
            ),
            "max_abs": float(delta.abs().max().item()),
            "mean_abs": float(delta.abs().mean().item()),
            "cosine": float(
                torch.nn.functional.cosine_similarity(
                    aiter_output_f32.view(1, -1),
                    reference.view(1, -1),
                ).item()
            ),
        }

    layout_comparisons = {
        "topk_slot_order": comparison(topk_order_reference),
        "sorted_expert_order": comparison(sorted_expert_reference),
    }
    # sorted_token_ids in the exact CK stage-2 capture encodes the original
    # top-k slot for each expert block. It proves inter_states stays in top-k
    # slot order. Do not select a layout by closeness to the invalid CK output.
    reference_layout = "topk_slot_order"
    reference_fp32 = topk_order_reference
    stage2_expert_ids = compact_topk_ids
    stage2_weights = topk_weights
    reference_bf16 = reference_fp32.to(torch.bfloat16)

    tensors = {
        "activation_fp8": activation_fp8,
        "activation_scale_f32": activation_scale,
        "selected_w2_fp8": selected_w2,
        "selected_w2_scale_f32": selected_w2_scale,
        "topk_weights_f32": topk_weights,
        "compact_topk_ids_i32": compact_topk_ids,
        "stage2_weights_f32": stage2_weights,
        "stage2_expert_ids_i32": stage2_expert_ids,
        "aiter_output_bf16": aiter_output,
        "reference_output_f32": reference_fp32,
        "reference_output_bf16": reference_bf16,
    }
    manifest = {
        "schema_version": 1,
        "quantization": "FP8 E4M3, 128x128 blocks",
        "weight_layout": {
            "resident": "AITER shuffle_weight layout=(16,16)",
            "oracle": "logical [expert,n,k] after inverse shuffle",
        },
        "shape": {
            "slots": slots,
            "experts": experts,
            "n": n_dim,
            "k": k_dim,
        },
        "selected_expert_ids": selected_ids.tolist(),
        "topk_expert_ids": topk_ids.view(-1).tolist(),
        "compact_topk_ids": compact_topk_ids.view(-1).tolist(),
        "reference_activation_layout": reference_layout,
        "activation_layout_comparisons": layout_comparisons,
        "aiter_vs_reference_bf16_mismatches": int(
            torch.ne(aiter_output, reference_bf16).sum().item()
        ),
        "aiter_vs_reference_max_abs": float(
            (aiter_output.float() - reference_fp32).abs().max().item()
        ),
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
