from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from netra_compiler.errors import ValidationError
from netra_compiler.frontends.model_json import load_model
from netra_compiler.schema_validation import validate_json_schema

ROOT = Path(__file__).resolve().parents[2]


class SchemaTest(unittest.TestCase):
    def test_schema_and_manifest_json_parse(self) -> None:
        paths = list((ROOT / "schemas").glob("*.json")) + list((ROOT / "manifests/gfx950").rglob("*.json")) + list((ROOT / "tests/compiler/fixtures").glob("*.json"))
        for path in paths:
            with self.subTest(path=path):
                value = json.loads(path.read_text())
                self.assertIsInstance(value, dict)
        self.assertEqual(json.loads((ROOT / "schemas/netra-engine.schema.json").read_text())["properties"]["target"]["const"], "gfx950")

    def test_model_and_profile_manifests_validate_structurally(self) -> None:
        model_schema = json.loads((ROOT / "schemas/netra-model.schema.json").read_text())
        profile_schema = json.loads((ROOT / "schemas/netra-profile.schema.json").read_text())
        models = list((ROOT / "manifests/gfx950/models").glob("*.json"))
        models += list((ROOT / "tests/compiler/fixtures").glob("*.json"))
        for path in models:
            with self.subTest(path=path):
                document = json.loads(path.read_text())
                if document.get("format") == "netra-model-1":
                    validate_json_schema(document, model_schema, label=str(path))
        for path in (ROOT / "manifests/gfx950/profiles").glob("*.json"):
            with self.subTest(path=path):
                validate_json_schema(json.loads(path.read_text()), profile_schema, label=str(path))

    def test_invalid_model_is_rejected_before_frontend_dispatch(self) -> None:
        invalid = {
            "format": "netra-model-1",
            "name": "",
            "family": "llama",
            "configuration": {},
        }
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "invalid.json"
            path.write_text(json.dumps(invalid), encoding="utf-8")
            with self.assertRaisesRegex(ValidationError, "schema validation failed"):
                load_model(path)

    def test_gemma_requires_explicit_quantization_layout_activation_and_tp(self) -> None:
        model = json.loads(
            (ROOT / "tests/compiler/fixtures/gemma-dense-synthetic.json").read_text()
        )
        for field in (
            "tensor_parallel",
            "activation",
            "activation_quantization",
            "weight_quantization",
            "activation_layout",
            "kernel_weight_layout",
        ):
            with self.subTest(field=field), tempfile.TemporaryDirectory() as root:
                broken = json.loads(json.dumps(model))
                del broken["configuration"][field]
                path = Path(root) / "gemma.json"
                path.write_text(json.dumps(broken), encoding="utf-8")
                with self.assertRaisesRegex(ValidationError, "explicit fields"):
                    load_model(path, library=None)


if __name__ == "__main__": unittest.main()
