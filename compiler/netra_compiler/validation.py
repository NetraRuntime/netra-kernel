from __future__ import annotations

import json
import hashlib
import re
from pathlib import Path
from typing import Any

from .errors import ValidationError
from .library import KernelLibrary
from .schema_validation import validate_json_schema


REQUIRED_ENGINE_KEYS = {
    "format_version", "engine_id", "target", "wave_size", "required_rocm",
    "model_configuration_hash", "deployment_guards", "tensor_parallel", "profiles", "operations",
    "selected_tactics", "kernel_symbols", "workspace_bytes", "fallbacks",
    "layout_plan", "graph_recipe", "memory_plan", "validation_status", "compiler", "artifact_files",
}


def validate_engine_directory(
    engine_dir: Path, *, library_root: Path | None = None
) -> dict[str, Any]:
    errors: list[str] = []
    engine_file = engine_dir / "engine.json"
    try:
        engine = json.loads(engine_file.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"invalid engine.json: {exc}") from exc
    library = KernelLibrary.discover(library_root, anchors=(engine_dir,))
    schema_path = library.schema("netra-engine.schema.json")
    try:
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"invalid engine schema: {exc}") from exc
    validate_json_schema(engine, schema, label=str(engine_file))
    contract_file = engine_dir / "contracts.json"
    try:
        contract_set = json.loads(contract_file.read_text(encoding="utf-8"))
        contract_schema = json.loads(
            (schema_path.parent / "netra-kernel-contract.schema.json").read_text(
                encoding="utf-8"
            )
        )
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"invalid contract artifact/schema: {exc}") from exc
    for index, contract in enumerate(contract_set.get("contracts", [])):
        validate_json_schema(
            contract, contract_schema, label=f"{contract_file}:contracts[{index}]"
        )
    missing = REQUIRED_ENGINE_KEYS - set(engine)
    if missing:
        errors.append("missing engine fields: " + ", ".join(sorted(missing)))
    if engine.get("format_version") != "netra-engine-1": errors.append("unsupported engine format")
    if engine.get("target") != "gfx950": errors.append("engine target is not gfx950")
    if engine.get("wave_size") != 64: errors.append("engine wave size is not 64")
    for relative in engine.get("artifact_files", []):
        if not (engine_dir / relative).is_file(): errors.append(f"missing artifact: {relative}")
    symbols = json.loads((engine_dir / "symbols.json").read_text(encoding="utf-8"))
    all_symbols = symbols.get("selected", []) + symbols.get("candidates", [])
    if len(all_symbols) != len(set(all_symbols)): errors.append("duplicate kernel symbol")
    validation = json.loads((engine_dir / "validation_plan.json").read_text(encoding="utf-8"))
    for candidate in validation.get("candidates", []):
        path = engine_dir / candidate["source"]
        if not path.is_file(): errors.append(f"missing generated source: {candidate['source']}")
        elif candidate["symbol"].encode() not in path.read_bytes(): errors.append(f"symbol missing from source: {candidate['symbol']}")
        for relative, expected in candidate.get("template_files", {}).items():
            include = engine_dir / relative
            if not include.is_file():
                errors.append(f"missing generated include: {relative}")
            elif hashlib.sha256(include.read_bytes()).hexdigest() != expected:
                errors.append(f"generated include hash mismatch: {relative}")
        golden_artifact = candidate.get("golden_source_artifact")
        if golden_artifact:
            golden_path = engine_dir / golden_artifact
            if not golden_path.is_file():
                errors.append(f"missing preserved golden source: {golden_artifact}")
            elif hashlib.sha256(golden_path.read_bytes()).hexdigest() != candidate.get(
                "golden_source_sha256"
            ):
                errors.append(f"preserved golden source hash mismatch: {golden_artifact}")
        if path.is_file():
            include_root = engine_dir / "generated" / "includes"
            pending = [path]
            visited: set[Path] = set()
            while pending:
                current = pending.pop()
                if current in visited:
                    continue
                visited.add(current)
                for name in re.findall(
                    r'^\s*\.include\s+"([^"]+)"',
                    current.read_text(encoding="utf-8"),
                    flags=re.MULTILINE,
                ):
                    include = include_root / name
                    if not include.is_file():
                        errors.append(f"unresolved generated include: {name}")
                    else:
                        pending.append(include)
    for artifact in engine.get("golden_artifacts", []):
        path = engine_dir / artifact["path"]
        if artifact.get("materialized"):
            if not path.is_file():
                errors.append(f"missing materialized golden artifact: {artifact['path']}")
            elif hashlib.sha256(path.read_bytes()).hexdigest() != artifact["sha256"]:
                errors.append(f"golden artifact hash mismatch: {artifact['path']}")
    for operation in engine.get("operations", []):
        if operation.get("execution") == "kernel":
            arguments = operation.get("arguments")
            if not isinstance(arguments, list) or not arguments:
                errors.append(f"selected kernel lacks typed arguments: {operation.get('name')}")
            elif len(arguments) > 32:
                errors.append(f"selected kernel exceeds 32 kernargs: {operation.get('name')}")
            else:
                if all(isinstance(argument.get("offset"), int) for argument in arguments):
                    spans = []
                    for argument in arguments:
                        size = 8 if argument.get("kind") == "pointer" else 4
                        offset = int(argument["offset"])
                        if offset < 0 or offset % min(size, 8):
                            errors.append(
                                f"selected kernel kernarg offset is invalid: {operation.get('name')}"
                            )
                        spans.append((offset, offset + size))
                    ordered = sorted(spans)
                    if any(left[1] > right[0] for left, right in zip(ordered, ordered[1:])):
                        errors.append(
                            f"selected kernel kernarg offsets overlap: {operation.get('name')}"
                        )
                    packed_size = max((end for _, end in spans), default=0)
                else:
                    packed_size = sum(8 if argument.get("kind") == "pointer" else 4
                                      for argument in arguments)
                typed_size = (packed_size + 7) & -8
                if typed_size != operation.get("kernarg_size"):
                    errors.append(f"selected kernel kernarg size mismatch: {operation.get('name')}")
    if errors:
        raise ValidationError("; ".join(errors))
    return {"valid": True, "target": "gfx950", "wave_size": 64,
            "operations": len(engine["operations"]),
            "kernel_operations": sum(op["execution"] == "kernel" for op in engine["operations"]),
            "fallback_operations": sum(op["execution"] != "kernel" for op in engine["operations"])}
