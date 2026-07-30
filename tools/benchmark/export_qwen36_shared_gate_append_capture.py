#!/usr/bin/env python3
"""Export a real Qwen M=1 shared-gate/append boundary for raw kernels."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import torch
from safetensors import safe_open


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--aiter-call", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--layer-id", type=int, default=0)
    parser.add_argument("--output-dir", type=Path, required=True)
    return parser.parse_args()


def raw_bytes(tensor: torch.Tensor) -> bytes:
    return tensor.detach().cpu().contiguous().view(torch.uint8).numpy().tobytes()


def sha256(tensor: torch.Tensor) -> str:
    return hashlib.sha256(raw_bytes(tensor)).hexdigest()


def load_checkpoint_tensor(
    model_dir: Path, key: str
) -> tuple[torch.Tensor, str]:
    index_path = model_dir / "model.safetensors.index.json"
    index = json.loads(index_path.read_text(encoding="utf-8"))
    shard_name = index["weight_map"][key]
    with safe_open(
        model_dir / shard_name, framework="pt", device="cpu"
    ) as source:
        tensor = source.get_tensor(key)
    return tensor.contiguous(), shard_name


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
            f"{key}: got shape={tuple(tensor.shape)} dtype={tensor.dtype}"
        )
    return tensor.contiguous()


def main() -> None:
    args = parse_args()
    if args.output_dir.exists():
        raise FileExistsError(f"refusing to overwrite {args.output_dir}")

    payload = torch.load(
        args.aiter_call, map_location="cpu", weights_only=False
    )
    hidden = require_tensor(
        payload, "hidden_states_bf16", (1, 2048), torch.bfloat16
    )
    expected_ids = require_tensor(
        payload, "topk_ids_i32", (1, 9), torch.int32
    )
    expected_weights = require_tensor(
        payload, "topk_weights_fp32", (1, 9), torch.float32
    )
    routed_ids = expected_ids[:, :8].clone()
    routed_weights = expected_weights[:, :8].clone()

    weight_key = (
        f"model.language_model.layers.{args.layer_id}."
        "mlp.shared_expert_gate.weight"
    )
    shared_gate_weight, shard_name = load_checkpoint_tensor(
        args.model_dir, weight_key
    )
    if (
        tuple(shared_gate_weight.shape) != (1, 2048)
        or shared_gate_weight.dtype != torch.bfloat16
    ):
        raise ValueError(
            f"{weight_key}: got shape={tuple(shared_gate_weight.shape)} "
            f"dtype={shared_gate_weight.dtype}"
        )

    shared_logit = torch.nn.functional.linear(hidden, shared_gate_weight)
    shared_weight = torch.sigmoid(shared_logit)
    if expected_ids[0, 8].item() != 256:
        raise ValueError(f"unexpected shared expert ID: {expected_ids[0, 8]}")
    expected_shared_weight = expected_weights[0, 8]
    if shared_weight[0, 0].float().item() != expected_shared_weight.item():
        raise ValueError(
            "checkpoint/capture shared weight mismatch: "
            f"computed={shared_weight[0, 0].float().item()} "
            f"captured={expected_shared_weight.item()}"
        )

    tensors = {
        "hidden_bf16": hidden,
        "shared_gate_weight_bf16": shared_gate_weight,
        "routed_ids_i32": routed_ids,
        "routed_weights_f32": routed_weights,
        "expected_ids_i32": expected_ids,
        "expected_weights_f32": expected_weights,
    }
    args.output_dir.mkdir(parents=True)
    for name, tensor in tensors.items():
        (args.output_dir / f"{name}.bin").write_bytes(raw_bytes(tensor))

    manifest = {
        "source_aiter_call": str(args.aiter_call),
        "source_checkpoint": str(args.model_dir),
        "source_checkpoint_shard": shard_name,
        "checkpoint_key": weight_key,
        "layer_id": args.layer_id,
        "shape": {
            "m": 1,
            "hidden_size": 2048,
            "routed_topk": 8,
            "fused_topk": 9,
            "shared_expert_id": 256,
        },
        "semantics": (
            "copy routed IDs/FP32 weights; "
            "shared_logit=bf16(linear(hidden_bf16,weight_bf16)); "
            "shared_weight=bf16(sigmoid(shared_logit)); append ID 256 and "
            "the BF16 shared weight expanded exactly to FP32"
        ),
        "shared_logit_bf16_bits": int(
            shared_logit.view(torch.uint16)[0, 0].item()
        ),
        "shared_weight_bf16_bits": int(
            shared_weight.view(torch.uint16)[0, 0].item()
        ),
        "shared_weight_fp32": expected_shared_weight.item(),
        "tensors": {
            name: {
                "shape": list(tensor.shape),
                "dtype": str(tensor.dtype),
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
