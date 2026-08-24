from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any

from ...errors import BuildUnavailable, ValidationError
from ...types import write_json
from .metadata import validate_readobj_metadata


def _tool(rocm: Path, relative: str, fallback: str) -> str:
    candidate = rocm / relative
    found = str(candidate) if candidate.is_file() else shutil.which(fallback)
    if not found:
        raise BuildUnavailable(f"ROCm tool not found: {candidate} (or {fallback} in PATH)")
    return found


def _normalize_tool_output(text: str, *, artifact: Path) -> str:
    """Remove the invocation directory from otherwise semantic tool output."""
    stable = f"hsaco/{artifact.name}"
    spellings = {str(artifact), str(artifact.absolute())}
    try:
        spellings.add(str(artifact.resolve()))
    except OSError:
        pass
    for spelling in sorted(spellings, key=len, reverse=True):
        text = text.replace(spelling, stable)
    return text


def build_sources(engine_dir: Path, *, rocm_dir: Path | None = None) -> list[dict[str, Any]]:
    rocm = rocm_dir or Path(os.environ.get("ROCM_DIR", "/opt/rocm"))
    clang = _tool(rocm, "llvm/bin/clang", "clang")
    linker = _tool(rocm, "llvm/bin/ld.lld", "ld.lld")
    objdump = _tool(rocm, "llvm/bin/llvm-objdump", "llvm-objdump")
    readobj = _tool(rocm, "llvm/bin/llvm-readobj", "llvm-readobj")
    objcopy = _tool(rocm, "llvm/bin/llvm-objcopy", "llvm-objcopy")
    validation_plan = json.loads((engine_dir / "validation_plan.json").read_text())
    metadata_by_source = {Path(c["source"]).name: c for c in validation_plan["candidates"]}
    engine = json.loads((engine_dir / "engine.json").read_text())
    hsaco_dir, metadata_dir = engine_dir / "hsaco", engine_dir / "metadata"
    hsaco_dir.mkdir(exist_ok=True); metadata_dir.mkdir(exist_ok=True)
    records = []
    for source in sorted((engine_dir / "generated").glob("*.s")):
        info = metadata_by_source.get(source.name)
        if info is None:
            raise ValidationError(f"generated source lacks candidate metadata: {source.name}")
        stem = source.stem; obj = hsaco_dir / f"{stem}.o"; hsaco = hsaco_dir / f"{stem}.hsaco"
        dis = metadata_dir / f"{stem}.dis"; meta = metadata_dir / f"{stem}.metadata.txt"
        text_section = metadata_dir / f"{stem}.text"
        include_root = engine_dir / "generated" / "includes"
        subprocess.run([
            clang, "-target", "amdgcn-amd-amdhsa", "-mcpu=gfx950",
            "-x", "assembler", "-I", str(include_root), "-c", str(source),
            "-o", str(obj),
        ], check=True)
        subprocess.run([linker, "-shared", str(obj), "-o", str(hsaco)], check=True)
        dis.write_text(_normalize_tool_output(
            subprocess.run([objdump, "--disassemble", "--mcpu=gfx950", str(hsaco)],
                           check=True, text=True, stdout=subprocess.PIPE).stdout,
            artifact=hsaco,
        ))
        meta.write_text(_normalize_tool_output(
            subprocess.run([readobj, "--notes", str(hsaco)], check=True, text=True,
                           stdout=subprocess.PIPE).stdout,
            artifact=hsaco,
        ))
        subprocess.run([
            objcopy, "--dump-section", f".text={text_section}", str(hsaco)
        ], check=True)
        launch = info["launch"]
        resources = validate_readobj_metadata(meta, symbol=info["symbol"],
                                             kernarg_size=int(info["kernarg_size"]),
                                             threads=launch["block"][0], lds_bytes=launch["lds_bytes"])
        record = {"source": f"generated/{source.name}", "hsaco": f"hsaco/{hsaco.name}",
                  "sha256": hashlib.sha256(hsaco.read_bytes()).hexdigest(),
                  "text_sha256": hashlib.sha256(text_section.read_bytes()).hexdigest(),
                  "resources": resources}
        golden_relative = info.get("golden_source_artifact")
        if golden_relative:
            golden_source = engine_dir / golden_relative
            if not golden_source.is_file():
                raise ValidationError(
                    f"preserved golden source is missing: {golden_relative}"
                )
            golden_stem = f"{stem}.golden"
            golden_obj = hsaco_dir / f"{golden_stem}.o"
            golden_hsaco = metadata_dir / f"{golden_stem}.hsaco"
            golden_dis = metadata_dir / f"{golden_stem}.dis"
            golden_meta = metadata_dir / f"{golden_stem}.metadata.txt"
            golden_text = metadata_dir / f"{golden_stem}.text"
            subprocess.run([
                clang, "-target", "amdgcn-amd-amdhsa", "-mcpu=gfx950",
                "-x", "assembler", "-c", str(golden_source), "-o", str(golden_obj),
            ], check=True)
            subprocess.run([
                linker, "-shared", str(golden_obj), "-o", str(golden_hsaco)
            ], check=True)
            golden_dis.write_text(_normalize_tool_output(
                subprocess.run([
                    objdump, "--disassemble", "--mcpu=gfx950", str(golden_hsaco)
                ], check=True, text=True, stdout=subprocess.PIPE).stdout,
                artifact=golden_hsaco,
            ))
            golden_meta.write_text(_normalize_tool_output(
                subprocess.run([
                    readobj, "--notes", str(golden_hsaco)
                ], check=True, text=True, stdout=subprocess.PIPE).stdout,
                artifact=golden_hsaco,
            ))
            subprocess.run([
                objcopy, "--dump-section", f".text={golden_text}", str(golden_hsaco)
            ], check=True)
            golden_resources = validate_readobj_metadata(
                golden_meta,
                symbol=info["compatibility_symbol"],
                kernarg_size=40,
                threads=launch["block"][0],
                lds_bytes=launch["lds_bytes"],
            )
            text_identical = text_section.read_bytes() == golden_text.read_bytes()
            resources_identical = resources == golden_resources
            equivalence = {
                "format": "netra-assembly-equivalence-1",
                "generated_symbol": info["symbol"],
                "golden_symbol": info["compatibility_symbol"],
                "text_byte_identical": text_identical,
                "generated_text_sha256": hashlib.sha256(
                    text_section.read_bytes()
                ).hexdigest(),
                "golden_text_sha256": hashlib.sha256(
                    golden_text.read_bytes()
                ).hexdigest(),
                "normalized_instructions_identical": text_identical,
                "metadata_resources_identical": resources_identical,
                "kernarg_identical": (
                    resources.get("kernarg_size") == golden_resources.get("kernarg_size")
                ),
                "launch_contract_identical": True,
                "generated_resources": resources,
                "golden_resources": golden_resources,
                "full_hsaco_byte_identical": (
                    hsaco.read_bytes() == golden_hsaco.read_bytes()
                ),
                "symbol_difference_only": (
                    text_identical
                    and resources_identical
                    and info["symbol"] != info["compatibility_symbol"]
                ),
                "maturity": info["maturity"],
                "promotion_eligible": False,
            }
            equivalence_path = metadata_dir / f"{stem}.equivalence.json"
            write_json(equivalence_path, equivalence)
            record["equivalence"] = f"metadata/{equivalence_path.name}"
            if not text_identical or not resources_identical:
                raise ValidationError(
                    f"generated assembly is not equivalent to preserved golden: {stem}"
                )
            golden_obj.unlink()
            golden_hsaco.unlink()
        write_json(metadata_dir / f"{stem}.json", record); records.append(record)
        obj.unlink()
    seen_golden: set[str] = set()
    for operation in engine["operations"]:
        if operation.get("artifact_kind") != "golden_external_hsaco":
            continue
        relative = operation.get("hsaco")
        if not relative or relative in seen_golden:
            continue
        seen_golden.add(relative)
        hsaco = engine_dir / relative
        if not hsaco.is_file():
            raise ValidationError(
                f"golden HSACO was not materialized: {relative}; compile with "
                "--golden-artifact-root"
            )
        expected = operation["hsaco_sha256"]
        actual = hashlib.sha256(hsaco.read_bytes()).hexdigest()
        if actual != expected:
            raise ValidationError(f"golden HSACO hash mismatch: {relative}")
        stem = hsaco.stem
        dis = metadata_dir / f"{stem}.dis"
        meta = metadata_dir / f"{stem}.metadata.txt"
        dis.write_text(_normalize_tool_output(subprocess.run(
            [objdump, "--disassemble", "--mcpu=gfx950", str(hsaco)],
            check=True, text=True, stdout=subprocess.PIPE,
        ).stdout, artifact=hsaco))
        meta.write_text(_normalize_tool_output(subprocess.run(
            [readobj, "--notes", str(hsaco)], check=True, text=True,
            stdout=subprocess.PIPE,
        ).stdout, artifact=hsaco))
        launch = operation["launch"]
        threads = launch["block"][0] * launch["block"][1] * launch["block"][2]
        resources = validate_readobj_metadata(
            meta, symbol=operation["kernel_symbol"],
            kernarg_size=operation["kernarg_size"], threads=threads,
            lds_bytes=launch["lds_bytes"],
        )
        record = {
            "hsaco": relative,
            "sha256": actual,
            "symbol": operation["kernel_symbol"],
            "resources": resources,
            "artifact_kind": "golden_external_hsaco",
        }
        write_json(metadata_dir / f"{stem}.json", record)
        records.append(record)
    built_by_source = {
        record.get("source"): record for record in records if record.get("source")
    }
    for candidate in validation_plan.get("candidates", []):
        built = built_by_source.get(candidate.get("source"))
        if built and built.get("equivalence"):
            candidate["equivalence_status"] = "text_byte_identical"
            candidate["equivalence_report"] = built["equivalence"]
    validation_plan["cross_assembly"] = (
        "passed" if validation_plan.get("candidates") else "not_applicable"
    )
    write_json(engine_dir / "validation_plan.json", validation_plan)
    return records
