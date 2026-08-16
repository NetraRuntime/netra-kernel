#!/usr/bin/env python3
"""Export a retained Qwen3.6 GDN merged-projection FP8 operand capture."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import torch


PREFIX = "gdn_stage.layer.0.dense_m1_n12288_k2048."
EXPECTED = {
    "input_bf16": ((1, 2048), torch.bfloat16),
    "q_input": ((1, 2048), torch.float8_e4m3fn),
    "x_scale": ((1, 16), torch.float32),
    "weight": ((12288, 2048), torch.float8_e4m3fn),
    "weight_scale": ((96, 16), torch.float32),
    "output_bf16": ((1, 12288), torch.bfloat16),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-pass", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    return parser.parse_args()


def tensor_bytes(tensor: torch.Tensor) -> bytes:
    return tensor.detach().contiguous().view(torch.uint8).numpy().tobytes()


def write_tensor(
    output_dir: Path,
    name: str,
    tensor: torch.Tensor,
) -> dict[str, object]:
    payload = tensor_bytes(tensor)
    path = output_dir / f"{name}.bin"
    if path.exists():
        raise FileExistsError(f"refusing to overwrite {path}")
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
    n, k = weight.shape
    return (
        weight.view(n // 16, k // 32, 2, 16, 16)
        .permute(0, 3, 1, 2, 4)
        .contiguous()
        .view(n, k)
    )


def main() -> None:
    args = parse_args()
    if not args.state_pass.is_file():
        raise FileNotFoundError(args.state_pass)
    if args.output_dir.exists() and any(args.output_dir.iterdir()):
        raise FileExistsError(
            f"refusing nonempty output directory {args.output_dir}"
        )
    args.output_dir.mkdir(parents=True, exist_ok=True)

    state = torch.load(
        args.state_pass,
        map_location="cpu",
        weights_only=False,
    )
    tensors: dict[str, torch.Tensor] = {}
    for name, (shape, dtype) in EXPECTED.items():
        key = PREFIX + name
        tensor = state.get(key)
        if not isinstance(tensor, torch.Tensor):
            raise KeyError(f"missing tensor {key}")
        if tuple(tensor.shape) != shape or tensor.dtype != dtype:
            raise ValueError(
                f"{key}: got shape={tuple(tensor.shape)} dtype={tensor.dtype}; "
                f"expected shape={shape} dtype={dtype}"
            )
        tensors[name] = tensor.contiguous()

    q_input = tensors["q_input"]
    x_scale = tensors["x_scale"]
    weight = unshuffle_aiter_16x16(tensors["weight"])
    weight_scale = tensors["weight_scale"]
    reference = torch.zeros((1, 12288), dtype=torch.float32)
    for k_block in range(16):
        k_start = k_block * 128
        k_end = k_start + 128
        activation = q_input[:, k_start:k_end].float() * x_scale[:, k_block]
        weight_block = weight[:, k_start:k_end].float()
        weight_block = weight_block * weight_scale[
            :, k_block
        ].repeat_interleave(128)[:, None]
        reference.add_(activation @ weight_block.T)

    deployed = tensors["output_bf16"]
    reference_bf16 = reference.to(torch.bfloat16)
    delta = deployed.float() - reference
    tensors["reference_output_f32"] = reference
    tensors["reference_output_bf16"] = reference_bf16
    tensors["weight_logical"] = weight
    manifest = {
        "schema_version": 1,
        "source_state_pass": str(args.state_pass),
        "quantization": "FP8 E4M3, 128x128 blocks",
        "shape": {"m": 1, "n": 12288, "k": 2048},
        "deployed_vs_reference": {
            "bf16_mismatches": int(
                torch.ne(deployed, reference_bf16).sum().item()
            ),
            "max_abs_f32": float(delta.abs().max().item()),
            "mean_abs_f32": float(delta.abs().mean().item()),
            "cosine_f32": float(
                torch.nn.functional.cosine_similarity(
                    deployed.float(), reference
                ).item()
            ),
        },
        "tensors": {
            name: write_tensor(args.output_dir, name, tensor)
            for name, tensor in tensors.items()
        },
    }
    manifest_path = args.output_dir / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(manifest, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
