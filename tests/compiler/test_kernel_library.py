from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from netra_compiler.engine import compile_engine, semantic_file_hashes
from netra_compiler.validation import validate_engine_directory


ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/compiler/fixtures/llama-moe-gate-up-exact.json"


class KernelLibraryTest(unittest.TestCase):
    def test_compiler_package_is_relocatable_with_explicit_library_root(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            relocated = Path(directory)
            package_root = relocated / "installed"
            package_root.mkdir()
            shutil.copytree(ROOT / "compiler/netra_compiler", package_root / "netra_compiler")
            output = relocated / "engine"
            environment = dict(os.environ)
            environment["PYTHONPATH"] = str(package_root)
            result = subprocess.run(
                [
                    sys.executable,
                    "-m",
                    "netra_compiler.cli",
                    "compile",
                    "--model",
                    str(FIXTURE),
                    "--target",
                    "gfx950",
                    "--profile",
                    "decode_m1",
                    "--output",
                    str(output),
                    "--library-root",
                    str(ROOT),
                ],
                cwd=relocated,
                env=environment,
                check=False,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((output / "engine.json").is_file())

    def test_shared_gdn_core_compiles_as_a_fixed_non_model_engine(self) -> None:
        fixture = ROOT / "tests/compiler/fixtures/generic-gdn-state-replay-exact.json"
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            compile_engine(fixture, "gfx950", "verify_m12_b1", output)
            engine = json.loads((output / "engine.json").read_text())
            operation = engine["operations"][0]
            self.assertEqual(operation["tactic"], "gfx950.gdn_state_replay_m12_fused_exact")
            self.assertEqual(operation["launch"]["grid"], [256, 1, 1])
            self.assertEqual(operation["launch"]["block"], [64, 1, 1])
            self.assertEqual(operation["kernarg_size"], 88)
            generated = next((output / "generated").glob("netra_gdn_state_replay_*.s"))
            self.assertNotIn("qwen", generated.read_text().lower())

    def test_explicit_model_selects_current_best_tactic_end_to_end(self) -> None:
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            a, b = Path(first), Path(second)
            compile_engine(FIXTURE, "gfx950", "decode_m1", a)
            compile_engine(FIXTURE, "gfx950", "decode_m1", b)
            self.assertEqual(semantic_file_hashes(a), semantic_file_hashes(b))
            result = validate_engine_directory(a)
            self.assertEqual(result["kernel_operations"], 1)
            self.assertEqual(result["fallback_operations"], 0)
            engine = json.loads((a / "engine.json").read_text())
            operation = engine["operations"][0]
            self.assertEqual(operation["tactic"], "gfx950.moe_gate_up_decode_m1")
            self.assertEqual(operation["artifact_kind"], "raw_assembly_template")
            self.assertEqual(operation["launch"]["grid"], [576, 1, 1])
            self.assertEqual(operation["launch"]["block"], [64, 1, 1])
            generated = next((a / "generated").glob("*.s"))
            source = generated.read_text()
            self.assertNotIn("llama", source.lower())
            self.assertNotIn("qwen", source.lower())
            self.assertIn(".set NETRA_HIDDEN_SIZE, 2048", source)
            self.assertIn("NETRA_MOE_GATE_UP_MFMA netra_moe_gate_up_", source)

    def test_same_dimensions_with_different_semantics_fall_back(self) -> None:
        model = json.loads(FIXTURE.read_text())
        attributes = model["graph"]["operations"][0]["attributes"]
        attributes["semantics"]["layouts"] = "checkpoint_row_major.v1"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            model_path = root / "model.json"
            output = root / "engine"
            model_path.write_text(json.dumps(model))
            compile_engine(model_path, "gfx950", "decode_m1", output)
            result = validate_engine_directory(output)
            self.assertEqual(result["kernel_operations"], 0)
            self.assertEqual(result["fallback_operations"], 1)
            explanation = json.loads((output / "explain.json").read_text())
            selected = explanation["operations"][0]
            self.assertIsNone(selected["selected"])
            self.assertTrue(any(
                "layouts semantic mismatch" in reason
                for candidate in selected["candidates"]
                for reason in candidate["reasons"]
            ))


if __name__ == "__main__":
    unittest.main()
