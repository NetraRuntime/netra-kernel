#!/usr/bin/env python3
"""Synthetic integrity tests for compose_dsv4_mxfp4_dspark.py."""

from __future__ import annotations

import importlib.util
import json
import struct
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("compose_dsv4_mxfp4_dspark.py")
SPEC = importlib.util.spec_from_file_location("compose_dsv4", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


def write_safetensors(path: Path, tensors: dict[str, tuple[str, bytes]]) -> None:
    offset = 0
    header = {}
    payload = bytearray()
    for name, (dtype, data) in tensors.items():
        header[name] = {
            "dtype": dtype,
            "shape": [len(data)],
            "data_offsets": [offset, offset + len(data)],
        }
        payload.extend(data)
        offset += len(data)
    encoded = json.dumps(header, separators=(",", ":")).encode()
    header_length = (len(encoded) + 7) // 8 * 8
    path.write_bytes(
        struct.pack("<Q", header_length)
        + encoded
        + b" " * (header_length - len(encoded))
        + payload
    )


def write_model(
    root: Path,
    shard_name: str,
    tensors: dict[str, tuple[str, bytes]],
    config: dict,
) -> None:
    root.mkdir()
    write_safetensors(root / shard_name, tensors)
    total = sum(len(data) for _, data in tensors.values())
    (root / MODULE.INDEX_NAME).write_text(
        json.dumps(
            {
                "metadata": {"total_size": total},
                "weight_map": {name: shard_name for name in tensors},
            }
        )
    )
    (root / "config.json").write_text(json.dumps(config))


class ComposeTest(unittest.TestCase):
    def test_metadata_conversion_and_extension(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            amd, base, dspark = root / "amd", root / "base", root / "dspark"
            weight = bytes([0x01, 0x8F, 0xFE, 0x77])
            scale = bytes([120, 127])
            shared_weight = bytes([0x8A, 0x10, 0x24, 0xFF])
            shared_scale = bytes([125, 130])
            extra = bytes([0x42, 0x99, 0x00])
            write_model(
                amd,
                "model-00001.safetensors",
                {
                    "layers.0.ffn.experts.0.w1.weight": ("U8", weight),
                    "layers.0.ffn.experts.0.w1.weight_scale": ("U8", scale),
                    "layers.0.ffn.shared_experts.w1.weight": ("U8", shared_weight),
                    "layers.0.ffn.shared_experts.w1.weight_scale": (
                        "U8",
                        shared_scale,
                    ),
                    "mtp.0.obsolete.weight": ("BF16", extra),
                },
                {"quantization_config": {"quant_method": "quark"}},
            )
            write_model(
                base,
                "model-00001.safetensors",
                {
                    "layers.0.ffn.experts.0.w1.weight": ("I8", weight),
                    "layers.0.ffn.experts.0.w1.scale": ("F8_E8M0", scale),
                    "layers.0.ffn.shared_experts.w1.weight": (
                        "F8_E4M3",
                        shared_weight * 2,
                    ),
                    "layers.0.ffn.shared_experts.w1.scale": (
                        "F8_E8M0",
                        shared_scale[:1],
                    ),
                    "mtp.0.obsolete.weight": ("BF16", extra),
                },
                {"quantization_config": {"quant_method": "fp8"}},
            )
            write_model(
                dspark,
                "model-00001.safetensors",
                {
                    "layers.0.ffn.experts.0.w1.weight": ("I8", weight),
                    "layers.0.ffn.experts.0.w1.scale": ("F8_E8M0", scale),
                    "layers.0.ffn.shared_experts.w1.weight": (
                        "F8_E4M3",
                        shared_weight * 2,
                    ),
                    "layers.0.ffn.shared_experts.w1.scale": (
                        "F8_E8M0",
                        shared_scale[:1],
                    ),
                    "mtp.1.markov_head.markov_w1.weight": ("BF16", extra),
                },
                {
                    "quantization_config": {"quant_method": "fp8"},
                    "dspark_block_size": 5,
                    "dspark_markov_rank": 256,
                },
            )

            manifest = MODULE.compose(amd, base, dspark)
            self.assertEqual(manifest["amd_base_tensor_count"], 5)
            self.assertEqual(manifest["retained_amd_tensor_count"], 2)
            self.assertEqual(manifest["replaced_base_tensor_count"], 1)
            self.assertEqual(manifest["reference_override_tensor_count"], 2)
            self.assertEqual(manifest["dspark_extension_tensor_count"], 1)
            self.assertEqual(manifest["combined_tensor_count"], 5)
            self.assertEqual(
                manifest["replaced_prepacked_shared_tensor_count"], 2
            )
            self.assertTrue(manifest["dspark_common_schema_match"])
            self.assertEqual(
                manifest["extension_payload_size"],
                len(shared_weight * 2) + len(shared_scale[:1]) + len(extra),
            )

            _, converted, _ = MODULE.read_safetensors_header(
                amd / "model-00001.safetensors"
            )
            self.assertNotIn(
                "layers.0.ffn.experts.0.w1.weight_scale", converted
            )
            self.assertEqual(
                converted["layers.0.ffn.experts.0.w1.weight"]["dtype"], "I8"
            )
            self.assertIn("layers.0.ffn.experts.0.w1.scale", converted)
            self.assertEqual(
                converted["layers.0.ffn.experts.0.w1.scale"]["dtype"],
                "F8_E8M0",
            )
            index = json.loads((amd / MODULE.INDEX_NAME).read_text())
            self.assertEqual(len(index["weight_map"]), 5)
            self.assertNotIn("mtp.0.obsolete.weight", index["weight_map"])
            self.assertEqual(
                index["weight_map"]["layers.0.ffn.shared_experts.w1.weight"],
                MODULE.EXTENSION_NAME,
            )
            self.assertEqual(
                index["weight_map"]["mtp.1.markov_head.markov_w1.weight"],
                MODULE.EXTENSION_NAME,
            )
            _, extension_header, _ = MODULE.read_safetensors_header(
                amd / MODULE.EXTENSION_NAME
            )
            self.assertIn("mtp.1.markov_head.markov_w1.weight", extension_header)
            final_config = json.loads((amd / "config.json").read_text())
            self.assertEqual(final_config["dspark_block_size"], 5)
            self.assertEqual(final_config["dspark_markov_rank"], 256)
            _, original_header, _ = MODULE.read_safetensors_header(
                amd / ".amd-quark-headers/model-00001.safetensors.header"
            )
            self.assertIn(
                "layers.0.ffn.experts.0.w1.weight_scale", original_header
            )
            self.assertEqual(
                original_header["layers.0.ffn.experts.0.w1.weight"]["dtype"],
                "U8",
            )

            repeated = MODULE.compose(amd, base, dspark)
            self.assertEqual(repeated["combined_tensor_count"], 5)
            self.assertEqual(repeated["patch_stats"]["already_native"], 1)


if __name__ == "__main__":
    unittest.main()
