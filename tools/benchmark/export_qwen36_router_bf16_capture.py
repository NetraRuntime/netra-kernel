#!/usr/bin/env python3
"""Export a real Qwen M=1 router GEMV boundary for raw gfx950 kernels."""

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


def main() -> None:
    args = parse_args()
    if args.output_dir.exists():
        raise FileExistsError(f"refusing to overwrite {args.output_dir}")

    payload = torch.load(
        args.aiter_call, map_location="cpu", weights_only=False
    )
    hidden = payload.get("hidden_states_bf16")
    if (
        not isinstance(hidden, torch.Tensor)
        or tuple(hidden.shape) != (1, 2048)
        or hidden.dtype != torch.bfloat16
    ):
        raise ValueError(
            "hidden_states_bf16 must be BF16 [1,2048]; "
            f"got {type(hidden)} {getattr(hidden, 'shape', None)} "
            f"{getattr(hidden, 'dtype', None)}"
        )
    hidden = hidden.contiguous()

    weight_key = f"model.language_model.layers.{args.layer_id}.mlp.gate.weight"
    router_weight, shard_name = load_checkpoint_tensor(
        args.model_dir, weight_key
    )
    if (
        tuple(router_weight.shape) != (256, 2048)
        or router_weight.dtype != torch.bfloat16
    ):
        raise ValueError(
            f"{weight_key}: got shape={tuple(router_weight.shape)} "
            f"dtype={router_weight.dtype}"
        )
    expected_logits = torch.nn.functional.linear(hidden, router_weight)
    if expected_logits.dtype != torch.bfloat16:
        raise ValueError(
            f"expected BF16 router logits, got {expected_logits.dtype}"
        )

    tensors = {
        "hidden_bf16": hidden,
        "router_weight_bf16": router_weight,
        "expected_logits_bf16": expected_logits.contiguous(),
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
            "num_experts": 256,
        },
        "semantics": (
            "BF16 router_logits = linear(BF16 hidden, BF16 router weight); "
            "M16 harness repeats independent real-checkpoint rows"
        ),
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
