from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from netra_compiler.engine import compile_engine, semantic_file_hashes
from netra_compiler.validation import validate_engine_directory


ROOT = Path(__file__).resolve().parents[2]


class EngineManifestTest(unittest.TestCase):
    def test_qwen_layer_templates_preserve_bindings_and_deduplicate_contracts(self) -> None:
        manifest = {
            "format": "netra-model-1",
            "name": "qwen-layer-template-test",
            "family": "qwen3.6",
            "configuration": {
                "layers": 4,
                "layer_types": [
                    "linear_attention",
                    "linear_attention",
                    "linear_attention",
                    "full_attention",
                ],
                "tensor_parallel": 1,
                "checkpoint_layout": "checkpoint_row_major_fp8_block128",
                "kernel_weight_layout": "aiter_shuffle_16x16_fp8_block128",
            },
            "layer_dense_operations": [
                {
                    "name": "model.layers.{layer}.mlp.down_proj",
                    "layers": "all",
                    "n": 5120,
                    "k": 17408,
                    "weight_binding": "model.layers.{layer}.mlp.down_proj.weight",
                    "checkpoint_tensors": [
                        "model.language_model.layers.{layer}.mlp.down_proj.weight"
                    ],
                    "checkpoint_scale_tensors": [
                        "model.language_model.layers.{layer}.mlp.down_proj.weight_scale_inv"
                    ],
                },
                {
                    "name": "model.layers.{layer}.linear_attn.out_proj",
                    "layers": "linear_attention",
                    "n": 5120,
                    "k": 6144,
                },
            ],
        }
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            model = root / "model.json"
            model.write_text(json.dumps(manifest))
            output = root / "engine"
            compile_engine(model, "gfx950", "decode_m1", output)
            engine = json.loads((output / "engine.json").read_text())
            self.assertEqual(len(engine["operations"]), 7)
            contracts = json.loads((output / "contracts.json").read_text())["contracts"]
            self.assertEqual(len(contracts), 2)
            layouts = json.loads((output / "layout_plan.json").read_text())["bindings"]
            down = next(
                item
                for item in layouts
                if item["tensor"] == "model.layers.2.mlp.down_proj.weight"
            )
            self.assertEqual(
                down["checkpoint_tensors"],
                ["model.language_model.layers.2.mlp.down_proj.weight"],
            )
            self.assertEqual(down["scale"]["checkpoint_dtype"], "bf16")
            self.assertEqual(down["scale"]["kernel_dtype"], "fp32")

    def test_qwen_dedup_determinism_and_template_instantiation(self) -> None:
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            a, b = Path(first), Path(second)
            model = ROOT / "manifests/gfx950/models/qwen36-dense.json"
            compile_engine(model, "gfx950", "decode_m1", a)
            compile_engine(model, "gfx950", "decode_m1", b)
            self.assertEqual(semantic_file_hashes(a), semantic_file_hashes(b))
            contracts = json.loads((a / "contracts.json").read_text())["contracts"]
            self.assertEqual(len(contracts), 1)
            engine = json.loads((a / "engine.json").read_text())
            self.assertEqual(len(engine["operations"]), 10)
            self.assertEqual(engine["validation_status"], "static_only_not_promoted")
            result = validate_engine_directory(a)
            self.assertEqual(result["fallback_operations"], 10)
            validation = json.loads((a / "validation_plan.json").read_text())
            self.assertEqual(validation["candidates"], [])

    def test_gemma_compiles_with_explicit_unvalidated_fallbacks(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            compile_engine(ROOT / "tests/compiler/fixtures/gemma-dense-synthetic.json",
                           "gfx950", "decode_m1", output)
            engine = json.loads((output / "engine.json").read_text())
            self.assertEqual(len(engine["operations"]), 5)
            self.assertEqual(
                [op["name"] for op in engine["operations"]],
                [
                    "model.layers.shared.gate_proj",
                    "model.layers.shared.up_proj",
                    "model.layers.shared.gated_silu",
                    "model.layers.shared.gated_silu.quantize",
                    "model.layers.shared.down_proj",
                ],
            )
            recipe = json.loads((output / "graph_recipe.json").read_text())
            self.assertEqual(
                [operation["depends_on"] for operation in recipe["operations"]],
                [[], [], [0, 1], [2], [3]],
            )
            self.assertFalse(json.loads((output / "validation_plan.json").read_text())["promotion_eligible"])

    def test_extensible_qwen_profiles_compile_to_safe_fallback(self) -> None:
        model = ROOT / "manifests/gfx950/models/qwen36-dense.json"
        for profile in ("verify_m16", "small_prefill_m64"):
            with self.subTest(profile=profile), tempfile.TemporaryDirectory() as directory:
                output = Path(directory)
                compile_engine(model, "gfx950", profile, output)
                result = validate_engine_directory(output)
                self.assertEqual(result["fallback_operations"], 10)
                self.assertEqual(result["kernel_operations"], 0)

    def test_explain_is_helpful(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            compile_engine(ROOT / "manifests/gfx950/models/qwen36-dense.json", "gfx950", "decode_m1", output)
            explanation = (output / "explain.json").read_text()
            self.assertIn("gfx950.aiter_blockscale_dense_m1.compat", explanation)
            self.assertNotIn("raw_dense_m1", explanation)


if __name__ == "__main__": unittest.main()
