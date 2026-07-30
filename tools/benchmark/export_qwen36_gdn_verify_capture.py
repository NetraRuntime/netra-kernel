#!/usr/bin/env python3
"""Export an exact real-checkpoint Qwen GDN M=16 verification boundary."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import torch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-pass", type=Path, required=True)
    parser.add_argument("--layer-id", type=int, default=0)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument(
        "--normalize-cache-index-i32",
        action="store_true",
        help=(
            "Explicitly normalize an older int64 state-dump cache index to "
            "the currently observed int32 serving ABI"
        ),
    )
    return parser.parse_args()


def raw_bytes(tensor: torch.Tensor) -> bytes:
    return tensor.detach().cpu().contiguous().view(torch.uint8).numpy().tobytes()


def sha256(tensor: torch.Tensor) -> str:
    return hashlib.sha256(raw_bytes(tensor)).hexdigest()


def require_tensor(
    payload: dict[str, object],
    key: str,
    shape: tuple[int, ...],
    dtype: torch.dtype,
) -> torch.Tensor:
    tensor = payload.get(key)
    if not isinstance(tensor, torch.Tensor):
        raise KeyError(f"missing tensor: {key}")
    if tuple(tensor.shape) != shape or tensor.dtype != dtype:
        raise ValueError(
            f"{key}: got shape={tuple(tensor.shape)} dtype={tensor.dtype}; "
            f"expected shape={shape} dtype={dtype}"
        )
    return tensor.detach().cpu().contiguous()


def require_cache_index(
    payload: dict[str, object],
    key: str,
    normalize_i32: bool,
) -> tuple[torch.Tensor, torch.dtype, bool]:
    tensor = payload.get(key)
    if not isinstance(tensor, torch.Tensor):
        raise KeyError(f"missing tensor: {key}")
    if tuple(tensor.shape) != (1,):
        raise ValueError(f"{key}: expected shape=(1,), got {tuple(tensor.shape)}")
    source_dtype = tensor.dtype
    normalized = False
    if tensor.dtype == torch.int64:
        if not normalize_i32:
            raise ValueError(
                f"{key}: capture uses int64; pass "
                "--normalize-cache-index-i32 only when pairing this older "
                "capture with evidence that the live serving ABI is int32"
            )
        value = int(tensor.item())
        if value < -(2**31) or value >= 2**31:
            raise ValueError(f"{key}: {value} is outside int32 range")
        tensor = tensor.to(torch.int32)
        normalized = True
    elif tensor.dtype != torch.int32:
        raise ValueError(
            f"{key}: expected int32 serving ABI, got {tensor.dtype}"
        )
    return tensor.detach().cpu().contiguous(), source_dtype, normalized


def main() -> None:
    args = parse_args()
    if args.output_dir.exists():
        raise FileExistsError(f"refusing to overwrite {args.output_dir}")

    payload = torch.load(
        args.state_pass, map_location="cpu", weights_only=False
    )
    if not isinstance(payload, dict):
        raise TypeError(f"state pass must be a dict, got {type(payload)}")
    metadata = payload.get("metadata")
    if not isinstance(metadata, dict):
        raise KeyError("state pass is missing metadata")
    forward_mode = str(metadata.get("forward_mode"))
    if forward_mode not in {"TARGET_VERIFY", "ForwardMode.TARGET_VERIFY"}:
        raise ValueError(
            "capture must be TARGET_VERIFY, got "
            f"{forward_mode!r}"
        )
    if int(metadata.get("batch_size", -1)) != 1:
        raise ValueError(f"capture batch size must be 1, got {metadata}")
    if int(metadata.get("input_token_count", -1)) != 16:
        raise ValueError(f"capture token count must be 16, got {metadata}")

    prefix = f"gdn_stage.layer.{args.layer_id}"
    backend = f"{prefix}.backend"
    cache_indices, cache_indices_source_dtype, cache_indices_normalized = (
        require_cache_index(
            payload,
            f"{backend}.cache_indices",
            args.normalize_cache_index_i32,
        )
    )
    tensors = {
        "q_bf16": require_tensor(
            payload, f"{backend}.verify_q", (1, 16, 16, 128), torch.bfloat16
        ),
        "k_bf16": require_tensor(
            payload, f"{backend}.verify_k", (1, 16, 16, 128), torch.bfloat16
        ),
        "v_bf16": require_tensor(
            payload, f"{backend}.verify_v", (1, 16, 32, 128), torch.bfloat16
        ),
        "a_bf16": require_tensor(
            payload, f"{backend}.verify_a", (16, 32), torch.bfloat16
        ),
        "b_bf16": require_tensor(
            payload, f"{backend}.verify_b", (16, 32), torch.bfloat16
        ),
        "A_log_f32": require_tensor(
            payload, f"{backend}.verify_A_log", (32,), torch.float32
        ),
        "dt_bias_bf16": require_tensor(
            payload, f"{backend}.verify_dt_bias", (32,), torch.bfloat16
        ),
        "initial_ssm_bf16": require_tensor(
            payload,
            f"{backend}.initial_ssm",
            (1, 32, 128, 128),
            torch.bfloat16,
        ),
        "cache_indices_i32": cache_indices,
        "query_start_loc_i32": require_tensor(
            payload, f"{backend}.query_start_loc", (2,), torch.int32
        ),
        "intermediate_state_indices_i32": require_tensor(
            payload,
            f"{backend}.verify_intermediate_state_indices",
            (1,),
            torch.int32,
        ),
        "expected_output_bf16": require_tensor(
            payload, f"{prefix}.core_attn", (1, 16, 32, 128), torch.bfloat16
        ),
        "expected_final_ssm_bf16": require_tensor(
            payload,
            f"{backend}.final_ssm",
            (1, 32, 128, 128),
            torch.bfloat16,
        ),
    }
    if tensors["cache_indices_i32"].item() < 0:
        raise ValueError("capture has an invalid initial-state cache index")
    if tensors["query_start_loc_i32"].tolist() != [0, 16]:
        raise ValueError(
            "capture query_start_loc must be [0,16], got "
            f"{tensors['query_start_loc_i32'].tolist()}"
        )

    args.output_dir.mkdir(parents=True)
    for name, tensor in tensors.items():
        (args.output_dir / f"{name}.bin").write_bytes(raw_bytes(tensor))

    manifest = {
        "source_state_pass": str(args.state_pass),
        "layer_id": args.layer_id,
        "accelerator": "AMD Instinct MI350X",
        "architecture": "gfx950",
        "model": "Qwen3.6-35B-A3B-FP8",
        "weight_quantization": "FP8 E4M3 128x128 blocks",
        "operation": "fused_sigmoid_gating_delta_rule_update",
        "shape": {
            "batch": 1,
            "tokens": 16,
            "q_heads": 16,
            "kv_heads": 32,
            "k": 128,
            "v": 128,
            "triton_grid": [1, 4, 32],
            "triton_block_k": 128,
            "triton_block_v": 32,
        },
        "parameters": {
            "softplus_beta": 1.0,
            "softplus_threshold": 20.0,
            "scale": 128**-0.5,
            "use_qk_l2norm_in_kernel": True,
            "use_initial_state": True,
            "disable_state_update": True,
            "disable_output_calculation": False,
            "cache_intermediate_states": True,
            "has_eagle_tree_custom_attn_mask": False,
            "cache_steps": 16,
        },
        "cache_index_abi": {
            "exported_dtype": str(tensors["cache_indices_i32"].dtype),
            "source_dtype": str(cache_indices_source_dtype),
            "normalized_to_live_int32_abi": cache_indices_normalized,
        },
        "tensors": {
            name: {
                "shape": list(tensor.shape),
                "dtype": str(tensor.dtype),
                "bytes": tensor.numel() * tensor.element_size(),
                "sha256": sha256(tensor),
            }
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
