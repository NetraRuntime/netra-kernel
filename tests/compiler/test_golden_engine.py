from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from netra_compiler.engine import compile_engine, semantic_file_hashes
from netra_compiler.errors import ValidationError
from netra_compiler.validation import validate_engine_directory


ROOT = Path(__file__).resolve().parents[2]


class GoldenEngineTest(unittest.TestCase):
    def _fixture(self, directory: Path) -> tuple[Path, Path]:
        model = json.loads(
            (ROOT / "manifests/gfx950/models/qwen36-moe-m1-golden.json").read_text()
        )
        artifacts = directory / "accepted"
        artifacts.mkdir()
        for operation in model["golden_operations"]:
            artifact = operation["golden_artifact"]
            payload = (artifact["symbol"] + "\n").encode()
            (artifacts / artifact["hsaco_name"]).write_bytes(payload)
            artifact["hsaco_sha256"] = hashlib.sha256(payload).hexdigest()
        manifest = directory / "model.json"
        manifest.write_text(json.dumps(model))
        return manifest, artifacts

    def test_golden_hsacos_are_hash_checked_copied_and_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as root:
            root_path = Path(root)
            model, artifacts = self._fixture(root_path)
            first, second = root_path / "first", root_path / "second"
            compile_engine(model, "gfx950", "decode_m1", first,
                           golden_artifact_root=artifacts)
            compile_engine(model, "gfx950", "decode_m1", second,
                           golden_artifact_root=artifacts)
            self.assertEqual(semantic_file_hashes(first), semantic_file_hashes(second))
            engine = json.loads((first / "engine.json").read_text())
            self.assertEqual(len(engine["operations"]), 11)
            self.assertTrue(
                all(op["execution"] == "kernel" for op in engine["operations"][:3])
            )
            self.assertTrue(
                all(
                    op["execution"] == "fallback" and "external_contract" in op
                    for op in engine["operations"][3:]
                )
            )
            self.assertTrue(all(item["materialized"] for item in engine["golden_artifacts"]))
            self.assertEqual(engine["workspace_bytes"], 0)
            self.assertEqual(engine["operations"][2]["launch"]["lds_bytes"], 1024)
            self.assertEqual(
                engine["operations"][2]["launch"]["dynamic_lds_bytes"], 0
            )
            self.assertTrue(
                all(
                    argument.get("source") == "binding"
                    for operation in engine["operations"][:3]
                    for argument in operation["arguments"]
                    if argument["kind"] == "pointer"
                )
            )
            result = validate_engine_directory(first)
            self.assertEqual(result["kernel_operations"], 3)
            self.assertEqual(result["fallback_operations"], 8)

    def test_hash_mismatch_refuses_artifact(self) -> None:
        with tempfile.TemporaryDirectory() as root:
            root_path = Path(root)
            model, artifacts = self._fixture(root_path)
            first = next(artifacts.iterdir())
            first.write_bytes(b"changed")
            with self.assertRaisesRegex(ValidationError, "hash mismatch"):
                compile_engine(model, "gfx950", "decode_m1", root_path / "engine",
                               golden_artifact_root=artifacts)


if __name__ == "__main__":
    unittest.main()
