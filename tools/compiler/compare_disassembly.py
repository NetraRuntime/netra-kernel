#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


RESOURCE_KEYS = ("vgpr_count", "sgpr_count", "agpr_count", "group_segment_fixed_size",
                 "private_segment_fixed_size", "kernarg_segment_size", "wavefront_size",
                 "max_flat_workgroup_size")


def _normalized_disassembly(text: str) -> list[str]:
    instructions = []
    for line in text.splitlines():
        if "file format" in line.lower() or line.lower().startswith("disassembly of"):
            continue
        line = re.sub(r"^\s*[0-9a-f]+:\s*(?:[0-9a-f]{2}\s+)+", "", line.lower())
        line = re.sub(r"<[^>]+>", "<symbol>", line)
        line = re.sub(r"\b0x[0-9a-f]+\b", "<address>", line)
        line = line.split("//", 1)[0].strip()
        if line and not line.endswith(":"):
            instructions.append(" ".join(line.split()))
    return instructions


def _metadata(path: Path | None) -> dict[str, int | None]:
    if path is None: return {}
    text = path.read_text(errors="replace")
    result = {}
    for key in RESOURCE_KEYS:
        found = re.findall(rf"\b{key}:\s*(\d+)", text)
        result[key] = int(found[-1]) if found else None
    return result


def _normalized_metadata(path: Path | None) -> str | None:
    if path is None:
        return None
    lines = []
    for line in path.read_text(errors="replace").splitlines():
        if re.match(r"^\s*File:", line):
            continue
        if re.match(r"^\s*\.name:", line):
            line = re.sub(r"(\.name:\s*)\S+", r"\1<symbol>", line)
        if re.match(r"^\s*\.symbol:", line):
            line = re.sub(r"(\.symbol:\s*)\S+", r"\1<symbol>.kd", line)
        lines.append(" ".join(line.split()))
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Classify golden/generated gfx950 differences")
    parser.add_argument("--golden", type=Path, required=True); parser.add_argument("--generated", type=Path, required=True)
    parser.add_argument("--golden-text", type=Path); parser.add_argument("--generated-text", type=Path)
    parser.add_argument("--golden-metadata", type=Path); parser.add_argument("--generated-metadata", type=Path)
    parser.add_argument("--golden-contract", type=Path); parser.add_argument("--generated-contract", type=Path)
    args = parser.parse_args()
    golden, generated = args.golden.read_bytes(), args.generated.read_bytes()
    byte_identical = golden == generated
    normalized_identical = _normalized_disassembly(golden.decode(errors="replace")) == _normalized_disassembly(generated.decode(errors="replace"))
    gm, nm = _metadata(args.golden_metadata), _metadata(args.generated_metadata)
    golden_metadata_bytes = args.golden_metadata.read_bytes() if args.golden_metadata else None
    generated_metadata_bytes = args.generated_metadata.read_bytes() if args.generated_metadata else None
    metadata_byte_identical = (
        golden_metadata_bytes == generated_metadata_bytes
        if golden_metadata_bytes is not None and generated_metadata_bytes is not None
        else None
    )
    metadata_semantic_identical = (
        _normalized_metadata(args.golden_metadata) == _normalized_metadata(args.generated_metadata)
        if args.golden_metadata or args.generated_metadata else None
    )
    resource_keys = {"vgpr_count", "sgpr_count", "agpr_count", "group_segment_fixed_size", "private_segment_fixed_size"}
    resource_identical = all(gm.get(k) == nm.get(k) for k in resource_keys) if gm or nm else None
    kernarg_identical = gm.get("kernarg_segment_size") == nm.get("kernarg_segment_size") if gm or nm else None
    launch_identical = None
    if args.golden_contract and args.generated_contract:
        left, right = json.loads(args.golden_contract.read_text()), json.loads(args.generated_contract.read_text())
        launch_identical = left.get("launch") == right.get("launch")
    text_byte_identical = None
    text_hashes = {"golden": None, "generated": None}
    if args.golden_text or args.generated_text:
        if not args.golden_text or not args.generated_text:
            parser.error("--golden-text and --generated-text must be provided together")
        golden_text = args.golden_text.read_bytes()
        generated_text = args.generated_text.read_bytes()
        text_byte_identical = golden_text == generated_text
        text_hashes = {
            "golden": hashlib.sha256(golden_text).hexdigest(),
            "generated": hashlib.sha256(generated_text).hexdigest(),
        }
    resource_differences = {
        key: {"golden": gm.get(key), "generated": nm.get(key)}
        for key in resource_keys if gm.get(key) != nm.get(key)
    }
    result = {
        "golden_sha256": hashlib.sha256(golden).hexdigest(), "generated_sha256": hashlib.sha256(generated).hexdigest(),
        "byte_identical": byte_identical, "normalized_instructions_identical": normalized_identical,
        "symbol_or_address_only_difference": not byte_identical and normalized_identical,
        "instruction_difference": not normalized_identical,
        "text_byte_identical": text_byte_identical,
        "text_sha256": text_hashes,
        "metadata_byte_identical": metadata_byte_identical,
        "metadata_semantic_identical": metadata_semantic_identical,
        "metadata_difference": metadata_semantic_identical is False,
        "resource_usage_identical": resource_identical,
        "resource_differences": resource_differences,
        "kernarg_identical": kernarg_identical, "launch_contract_identical": launch_identical,
        "kernarg_change": kernarg_identical is False,
        "launch_contract_change": launch_identical is False,
        "golden_resources": gm, "generated_resources": nm,
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    strongest_text_gate = text_byte_identical is True
    fallback_gate = (
        normalized_identical
        and metadata_semantic_identical is not False
        and resource_identical is not False
        and kernarg_identical is not False
        and launch_identical is not False
    )
    return 0 if strongest_text_gate or fallback_gate else 1


if __name__ == "__main__": raise SystemExit(main())
