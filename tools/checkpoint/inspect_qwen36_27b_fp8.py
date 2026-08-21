#!/usr/bin/env python3
"""Validate the pinned Qwen3.6-27B-FP8 checkpoint without loading tensors."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
from pathlib import Path
from typing import Any


REVISION = "e89b16ebf1988b3d6befa7de50abc2d76f26eb09"
REPOSITORY = "Qwen/Qwen3.6-27B-FP8"


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _header(path: Path) -> dict[str, Any]:
    with path.open("rb") as stream:
        size_bytes = stream.read(8)
        if len(size_bytes) != 8:
            raise ValueError(f"{path}: truncated safetensors header size")
        size = struct.unpack("<Q", size_bytes)[0]
        if size <= 0 or size > 16 * 1024 * 1024:
            raise ValueError(f"{path}: invalid safetensors header size {size}")
        payload = stream.read(size)
    if len(payload) != size:
        raise ValueError(f"{path}: truncated safetensors header")
    root = json.loads(payload)
    return {name: value for name, value in root.items() if name != "__metadata__"}


def _expect(
    tensors: dict[str, Any],
    name: str,
    dtype: str,
    shape: list[int],
    *,
    source: Path,
) -> None:
    actual = tensors.get(name)
    if actual is None:
        raise ValueError(f"{source}: missing tensor {name}")
    if actual.get("dtype") != dtype or actual.get("shape") != shape:
        raise ValueError(
            f"{source}: {name} expected {dtype} {shape}, got "
            f"{actual.get('dtype')} {actual.get('shape')}"
        )


def inspect(checkpoint: Path) -> dict[str, Any]:
    config_path = checkpoint / "config.json"
    index_path = checkpoint / "model.safetensors.index.json"
    tree_path = checkpoint / ".cache/huggingface/trees" / f"{REVISION}.json"
    config = json.loads(config_path.read_text(encoding="utf-8"))
    text = config["text_config"]
    tree = json.loads(tree_path.read_text(encoding="utf-8"))
    index = json.loads(index_path.read_text(encoding="utf-8"))
    files = tree.get("files")
    if tree.get("format_version") != 1 or not isinstance(files, dict):
        raise ValueError("invalid Hugging Face revision tree")
    for relative, metadata in sorted(files.items()):
        path = checkpoint / relative
        if not path.is_file():
            raise ValueError(f"checkpoint file is missing: {relative}")
        expected_size = metadata.get("size")
        if path.stat().st_size != expected_size:
            raise ValueError(
                f"checkpoint size mismatch: {relative}: "
                f"{path.stat().st_size} != {expected_size}"
            )

    expected_layer_types = [
        "full_attention" if layer % 4 == 3 else "linear_attention"
        for layer in range(64)
    ]
    if text.get("layer_types") != expected_layer_types:
        raise ValueError("layer_types does not match the 3 GDN plus 1 full cadence")
    tensor_count = 0
    for layer, layer_type in enumerate(expected_layer_types):
        shard = checkpoint / f"layers-{layer}.safetensors"
        tensors = _header(shard)
        tensor_count += len(tensors)
        prefix = f"model.language_model.layers.{layer}"
        for projection, shape in (
            ("mlp.gate_proj", [17408, 5120]),
            ("mlp.up_proj", [17408, 5120]),
            ("mlp.down_proj", [5120, 17408]),
        ):
            _expect(tensors, f"{prefix}.{projection}.weight", "F8_E4M3", shape, source=shard)
            _expect(
                tensors,
                f"{prefix}.{projection}.weight_scale_inv",
                "BF16",
                [shape[0] // 128, shape[1] // 128],
                source=shard,
            )
        if layer_type == "linear_attention":
            for projection, shape in (
                ("linear_attn.in_proj_qkv", [10240, 5120]),
                ("linear_attn.in_proj_z", [6144, 5120]),
                ("linear_attn.out_proj", [5120, 6144]),
            ):
                _expect(tensors, f"{prefix}.{projection}.weight", "F8_E4M3", shape, source=shard)
                _expect(
                    tensors,
                    f"{prefix}.{projection}.weight_scale_inv",
                    "BF16",
                    [shape[0] // 128, shape[1] // 128],
                    source=shard,
                )
            _expect(
                tensors,
                f"{prefix}.linear_attn.conv1d.weight",
                "BF16",
                [10240, 1, 4],
                source=shard,
            )
        else:
            for projection, shape in (
                ("self_attn.q_proj", [12288, 5120]),
                ("self_attn.k_proj", [1024, 5120]),
                ("self_attn.v_proj", [1024, 5120]),
                ("self_attn.o_proj", [5120, 6144]),
            ):
                _expect(tensors, f"{prefix}.{projection}.weight", "F8_E4M3", shape, source=shard)
                _expect(
                    tensors,
                    f"{prefix}.{projection}.weight_scale_inv",
                    "BF16",
                    [shape[0] // 128, shape[1] // 128],
                    source=shard,
                )
        for name in tensors:
            if index["weight_map"].get(name) != shard.name:
                raise ValueError(f"weight-map shard mismatch for {name}")

    observed_config = {
        "architecture": config["architectures"][0],
        "model_type": text["model_type"],
        "hidden_size": text["hidden_size"],
        "intermediate_size": text["intermediate_size"],
        "layers": text["num_hidden_layers"],
        "full_attention_layers": expected_layer_types.count("full_attention"),
        "linear_attention_layers": expected_layer_types.count("linear_attention"),
        "num_attention_heads": text["num_attention_heads"],
        "num_key_value_heads": text["num_key_value_heads"],
        "head_dim": text["head_dim"],
        "linear_num_key_heads": text["linear_num_key_heads"],
        "linear_key_head_dim": text["linear_key_head_dim"],
        "linear_num_value_heads": text["linear_num_value_heads"],
        "linear_value_head_dim": text["linear_value_head_dim"],
        "linear_conv_kernel_dim": text["linear_conv_kernel_dim"],
        "max_position_embeddings": text["max_position_embeddings"],
        "vocab_size": text["vocab_size"],
        "attention_output_gate": text["attn_output_gate"],
        "mtp_layers": text["mtp_num_hidden_layers"],
    }
    quantization = config["quantization_config"]
    return {
        "format": "netra-qwen36-27b-checkpoint-inspection-1",
        "status": "passed",
        "checkpoint": str(checkpoint.resolve()),
        "repository": REPOSITORY,
        "revision": REVISION,
        "revision_tree_sha256": _sha256(tree_path),
        "config_sha256": _sha256(config_path),
        "file_count": len(files),
        "total_bytes": sum(metadata["size"] for metadata in files.values()),
        "indexed_tensor_count": len(index["weight_map"]),
        "validated_layer_tensor_count": tensor_count,
        "configuration": observed_config,
        "quantization": {
            "method": quantization["quant_method"],
            "format": quantization["fmt"],
            "activation_scheme": quantization["activation_scheme"],
            "weight_block_size": quantization["weight_block_size"],
            "checkpoint_scale_dtype": "BF16",
        },
        "runtime_projection_shapes": {
            "gdn_qkvz": [16384, 5120],
            "full_attention_qkv": [14336, 5120],
            "attention_output": [5120, 6144],
            "mlp_gate_up": [34816, 5120],
            "mlp_down": [5120, 17408],
        },
        "layout_recipe": {
            "checkpoint_weight": "row_major_fp8_block128",
            "packed_projections": "concatenate_output_shards_axis0",
            "runtime_weight": "aiter_shuffle_16x16_fp8_block128",
            "checkpoint_scale": "row_major_nblock_kblock_bf16",
            "runtime_weight_scale": "row_major_nblock_kblock_fp32",
            "runtime_activation_scale": "transposed_kblock_major_fp32",
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkpoint", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        result = inspect(args.checkpoint)
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
        raise SystemExit(f"checkpoint inspection failed: {exc}") from exc
    payload = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(payload, encoding="utf-8")
    print(payload, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
