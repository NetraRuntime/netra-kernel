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
            self.assertTrue(validation["candidates"])
            for candidate in validation["candidates"]:
                generated = a / candidate["source"]
                golden = a / candidate["golden_source_artifact"]
                self.assertTrue(candidate["generated_from_template"])
                self.assertEqual(candidate["maturity"], "rejected")
                self.assertEqual(
                    candidate["golden_source_revision"],
                    "052c539e0794aedb71761bbffe816930817ac5b3",
                )
                self.assertNotEqual(generated.read_bytes(), golden.read_bytes())
                self.assertEqual(
                    candidate["golden_source_sha256"],
                    hashlib.sha256(golden.read_bytes()).hexdigest(),
                )
                for relative, digest in candidate["template_files"].items():
                    include = a / relative
                    self.assertTrue(include.is_file())
                    self.assertEqual(
                        digest,
                        hashlib.sha256(include.read_bytes()).hexdigest(),
                    )

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
            self.assertIn("matched serving wall/generation regressed", explanation)
            self.assertIn("maturity is rejected", explanation)


if __name__ == "__main__": unittest.main()
