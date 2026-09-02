#!/usr/bin/env python3
"""Compose AMD DeepSeek-V4 MXFP4 payloads with the native DSpARK extension.

The AMD Quark checkpoint and the native DeepSeek checkpoint use the same
packed tensor geometry, but Quark names scales ``weight_scale`` and declares
packed expert bytes as U8.  The proven SGLang DSpARK path expects ``scale``
and I8.  This tool rewrites only safetensors headers (payload offsets stay
fixed), extracts the additive DSpARK tensors into one new shard, and writes a
native DSpARK config/index.  Original AMD headers/config/index are retained so
the operation is auditable and reversible.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import struct
from pathlib import Path
from typing import Any, BinaryIO


INDEX_NAME = "model.safetensors.index.json"
EXTENSION_NAME = "model-dspark-extension-v2.safetensors"
MANIFEST_NAME = "mxfp4-dspark-compose.json"


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def write_json_atomic(path: Path, value: Any) -> None:
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")
    os.replace(temporary, path)


def native_key(name: str) -> str:
    suffix = ".weight_scale"
    if name.endswith(suffix):
        return name[: -len(suffix)] + ".scale"
    return name


def read_safetensors_header(path: Path) -> tuple[int, dict[str, Any], bytes]:
    with path.open("rb") as stream:
        raw_length = stream.read(8)
        if len(raw_length) != 8:
            raise ValueError(f"{path}: truncated safetensors length")
        header_length = struct.unpack("<Q", raw_length)[0]
        raw_header = stream.read(header_length)
    if len(raw_header) != header_length:
        raise ValueError(f"{path}: truncated safetensors header")
    return header_length, json.loads(raw_header), raw_length + raw_header


def encoded_padded_header(header: dict[str, Any], target_length: int) -> bytes:
    encoded = json.dumps(header, separators=(",", ":")).encode()
    if len(encoded) > target_length:
        raise ValueError(
            f"converted header grew from {target_length} to {len(encoded)} bytes"
        )
    return encoded + b" " * (target_length - len(encoded))


def patch_amd_header(path: Path, backup_dir: Path) -> dict[str, int]:
    header_length, header, original = read_safetensors_header(path)
    converted: dict[str, Any] = {}
    renamed = 0
    u8_weight_to_i8 = 0
    u8_scale_to_e8m0 = 0

    for name, metadata in header.items():
        if name == "__metadata__":
            converted[name] = metadata
            continue
        new_name = native_key(name)
        if new_name in converted:
            raise ValueError(f"{path}: key collision while converting {new_name}")
        new_metadata = dict(metadata)
        if new_metadata.get("dtype") == "U8":
            if name.endswith(".weight_scale"):
                new_metadata["dtype"] = "F8_E8M0"
                u8_scale_to_e8m0 += 1
            elif (
                (".experts." in name or ".shared_experts." in name)
                and name.endswith(".weight")
            ):
                new_metadata["dtype"] = "I8"
                u8_weight_to_i8 += 1
            else:
                raise ValueError(f"{path}: unexpected U8 tensor {name}")
        converted[new_name] = new_metadata
        renamed += new_name != name

    already_native = (
        renamed == 0 and u8_weight_to_i8 == 0 and u8_scale_to_e8m0 == 0
    )
    if already_native:
        return {
            "renamed": 0,
            "u8_weight_to_i8": 0,
            "u8_scale_to_e8m0": 0,
            "already_native": 1,
        }

    backup_dir.mkdir(parents=True, exist_ok=True)
    backup = backup_dir / f"{path.name}.header"
    if backup.exists():
        if backup.read_bytes() != original:
            # A prior run may have saved the original while this shard is now
            # partially converted.  Never replace the known-good backup.
            raise ValueError(f"{backup}: existing header backup differs")
    else:
        backup.write_bytes(original)

    replacement = encoded_padded_header(converted, header_length)
    with path.open("r+b") as stream:
        stream.seek(8)
        stream.write(replacement)
        stream.flush()
        os.fsync(stream.fileno())
    return {
        "renamed": renamed,
        "u8_weight_to_i8": u8_weight_to_i8,
        "u8_scale_to_e8m0": u8_scale_to_e8m0,
        "already_native": 0,
    }


def tensor_schema(
    root: Path, weight_map: dict[str, str]
) -> dict[str, tuple[str, tuple[int, ...]]]:
    by_shard: dict[str, list[str]] = {}
    for key, shard in weight_map.items():
        by_shard.setdefault(shard, []).append(key)
    result: dict[str, tuple[str, tuple[int, ...]]] = {}
    for shard, keys in by_shard.items():
        path = root / shard
        header_length, header, _ = read_safetensors_header(path)
        expected_keys = set(keys)
        actual_keys = set(header) - {"__metadata__"}
        if actual_keys != expected_keys:
            missing = sorted(expected_keys - actual_keys)
            unexpected = sorted(actual_keys - expected_keys)
            raise ValueError(
                f"{path}: index/header key mismatch; "
                f"missing={missing[:5]}, unexpected={unexpected[:5]}"
            )
        payload_size = max(
            (int(header[key]["data_offsets"][1]) for key in actual_keys),
            default=0,
        )
        expected_size = 8 + header_length + payload_size
        actual_size = path.stat().st_size
        if actual_size != expected_size:
            raise ValueError(
                f"{path}: size {actual_size} does not match safetensors "
                f"header size {expected_size}"
            )
        for key in keys:
            metadata = header.get(key)
            if metadata is None:
                raise ValueError(f"{path}: index key {key} is absent from header")
            result[key] = (metadata["dtype"], tuple(metadata["shape"]))
    return result


def indexed_payload_size(root: Path, weight_map: dict[str, str]) -> int:
    headers: dict[str, dict[str, Any]] = {}
    total = 0
    for key, shard in weight_map.items():
        if shard not in headers:
            _, header, _ = read_safetensors_header(root / shard)
            headers[shard] = header
        begin, end = map(int, headers[shard][key]["data_offsets"])
        total += end - begin
    return total


def copy_exact(source: BinaryIO, destination: BinaryIO, count: int) -> None:
    remaining = count
    while remaining:
        chunk = source.read(min(16 * 1024 * 1024, remaining))
        if not chunk:
            raise EOFError(f"source ended with {remaining} bytes left to copy")
        destination.write(chunk)
        remaining -= len(chunk)


def extension_entries(
    source_groups: list[tuple[Path, dict[str, str], list[str]]],
) -> tuple[list[dict[str, Any]], int]:
    headers: dict[tuple[Path, str], tuple[int, dict[str, Any]]] = {}
    entries: list[dict[str, Any]] = []
    output_offset = 0
    for source_dir, weight_map, keys in source_groups:
        for key in keys:
            shard_name = weight_map[key]
            header_key = (source_dir, shard_name)
            if header_key not in headers:
                length, header, _ = read_safetensors_header(
                    source_dir / shard_name
                )
                headers[header_key] = (length, header)
            header_length, header = headers[header_key]
            metadata = header[key]
            begin, end = map(int, metadata["data_offsets"])
            size = end - begin
            output_metadata = dict(metadata)
            output_metadata["data_offsets"] = [
                output_offset,
                output_offset + size,
            ]
            entries.append(
                {
                    "key": key,
                    "source": source_dir / shard_name,
                    "source_offset": 8 + header_length + begin,
                    "size": size,
                    "metadata": output_metadata,
                }
            )
            output_offset += size
    return entries, output_offset


def write_extension_shard(
    output: Path, entries: list[dict[str, Any]], payload_size: int
) -> str:
    header = {entry["key"]: entry["metadata"] for entry in entries}
    encoded = json.dumps(header, separators=(",", ":")).encode()
    header_length = (len(encoded) + 7) // 8 * 8
    padded = encoded + b" " * (header_length - len(encoded))
    expected_size = 8 + header_length + payload_size

    if output.exists():
        if output.stat().st_size != expected_size:
            raise ValueError(
                f"{output}: existing extension size {output.stat().st_size} "
                f"does not match expected {expected_size}"
            )
        _, existing_header, _ = read_safetensors_header(output)
        if existing_header != header:
            raise ValueError(f"{output}: existing extension header differs")
        return sha256_file(output)

    temporary = output.with_name(output.name + ".tmp")
    with temporary.open("wb") as destination:
        destination.write(struct.pack("<Q", header_length))
        destination.write(padded)
        for entry in entries:
            with entry["source"].open("rb") as source:
                source.seek(entry["source_offset"])
                copy_exact(source, destination, entry["size"])
        destination.flush()
        os.fsync(destination.fileno())
    if temporary.stat().st_size != expected_size:
        raise ValueError(
            f"{temporary}: wrote {temporary.stat().st_size}, expected {expected_size}"
        )
    os.replace(temporary, output)
    return sha256_file(output)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while chunk := stream.read(16 * 1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def compose(
    amd_dir: Path, reference_base_dir: Path, dspark_dir: Path
) -> dict[str, Any]:
    amd_index_path = amd_dir / INDEX_NAME
    saved_index_path = amd_dir / "model.safetensors.index.amd-quark.json"
    saved_config_path = amd_dir / "config.amd-quark.json"
    if not saved_index_path.exists():
        shutil.copy2(amd_index_path, saved_index_path)
    if not saved_config_path.exists():
        shutil.copy2(amd_dir / "config.json", saved_config_path)

    amd_index = read_json(saved_index_path)
    base_index = read_json(reference_base_dir / INDEX_NAME)
    dspark_index = read_json(dspark_dir / INDEX_NAME)
    amd_map = amd_index["weight_map"]
    native_amd_map = {native_key(key): shard for key, shard in amd_map.items()}
    if len(native_amd_map) != len(amd_map):
        raise ValueError("AMD key normalization produced collisions")
    base_keys = set(base_index["weight_map"])
    if set(native_amd_map) != base_keys:
        raise ValueError(
            "normalized AMD tensor set differs from the reference base: "
            f"missing={len(base_keys - set(native_amd_map))} "
            f"unexpected={len(set(native_amd_map) - base_keys)}"
        )

    missing_shards = sorted(
        shard for shard in set(amd_map.values()) if not (amd_dir / shard).is_file()
    )
    if missing_shards:
        raise FileNotFoundError(
            f"AMD checkpoint is incomplete; missing {len(missing_shards)} shards: "
            + ", ".join(missing_shards[:5])
        )

    backup_dir = amd_dir / ".amd-quark-headers"
    patch_stats = {
        "renamed": 0,
        "u8_weight_to_i8": 0,
        "u8_scale_to_e8m0": 0,
        "already_native": 0,
    }
    for shard_name in sorted(set(amd_map.values())):
        stats = patch_amd_header(amd_dir / shard_name, backup_dir)
        for key, value in stats.items():
            patch_stats[key] += value

    converted_schema = tensor_schema(amd_dir, native_amd_map)
    reference_schema = tensor_schema(reference_base_dir, base_index["weight_map"])
    schema_mismatches = {
        key: {"converted": converted_schema[key], "reference": reference_schema[key]}
        for key in converted_schema
        if converted_schema[key] != reference_schema[key]
    }
    fused_shared_schema = {}
    invalid_schema = {}
    for key, mismatch in schema_mismatches.items():
        if ".ffn.shared_experts." in key:
            routed_key = key.replace(".ffn.shared_experts.", ".ffn.experts.0.")
            if converted_schema.get(key) == converted_schema.get(routed_key):
                fused_shared_schema[key] = mismatch
                continue
        invalid_schema[key] = mismatch
    if invalid_schema:
        sample = list(invalid_schema.items())[:5]
        raise ValueError(
            f"converted AMD schema has {len(invalid_schema)} unsupported "
            "dtype/shape mismatches: "
            f"{sample}"
        )

    dspark_map = dspark_index["weight_map"]
    amd_keys = set(native_amd_map)
    dspark_keys = set(dspark_map)
    replaced_base_keys = sorted(amd_keys - dspark_keys)
    if any(not key.startswith("mtp.0.") for key in replaced_base_keys):
        raise ValueError(
            "DSpARK unexpectedly omits non-MTP base tensors: "
            f"{replaced_base_keys[:5]}"
        )
    extension_keys = sorted(dspark_keys - amd_keys)
    reference_override_keys = sorted(fused_shared_schema)
    retained_amd_map = {
        key: shard
        for key, shard in native_amd_map.items()
        if key in dspark_keys and key not in fused_shared_schema
    }
    dspark_schema = tensor_schema(dspark_dir, dspark_map)
    dspark_common_mismatches = {
        key: {
            "converted": converted_schema[key],
            "dspark": dspark_schema[key],
        }
        for key in retained_amd_map
        if converted_schema[key] != dspark_schema[key]
    }
    if dspark_common_mismatches:
        sample = list(dspark_common_mismatches.items())[:5]
        raise ValueError(
            f"converted AMD schema has {len(dspark_common_mismatches)} "
            f"mismatches against DSpARK: {sample}"
        )
    entries, extension_payload_size = extension_entries(
        [
            (
                reference_base_dir,
                base_index["weight_map"],
                reference_override_keys,
            ),
            (dspark_dir, dspark_map, extension_keys),
        ]
    )
    extension_path = amd_dir / EXTENSION_NAME
    extension_sha256 = write_extension_shard(
        extension_path, entries, extension_payload_size
    )

    combined_map = dict(retained_amd_map)
    combined_map.update(
        {key: EXTENSION_NAME for key in reference_override_keys}
    )
    combined_map.update({key: EXTENSION_NAME for key in extension_keys})
    if set(combined_map) != dspark_keys:
        raise AssertionError("composed tensor set does not exactly match DSpARK")
    retained_amd_payload_size = indexed_payload_size(amd_dir, retained_amd_map)
    final_index = {
        "metadata": {
            "total_size": retained_amd_payload_size + extension_payload_size,
            "mxfp4_source": "amd/DeepSeek-V4-Flash-MXFP4",
            "shared_expert_source": str(reference_base_dir),
            "dspark_extension_source": str(dspark_dir),
        },
        "weight_map": combined_map,
    }
    write_json_atomic(amd_index_path, final_index)

    final_config = read_json(dspark_dir / "config.json")
    final_config["mxfp4_source_model"] = "amd/DeepSeek-V4-Flash-MXFP4"
    amd_config = read_json(saved_config_path)
    if "_commit_hash" in amd_config:
        final_config["mxfp4_source_revision"] = amd_config["_commit_hash"]
    write_json_atomic(amd_dir / "config.json", final_config)

    manifest = {
        "format": "netra-dsv4-mxfp4-dspark-v2",
        "amd_base_tensor_count": len(native_amd_map),
        "retained_amd_tensor_count": len(retained_amd_map),
        "replaced_base_tensor_count": len(replaced_base_keys),
        "replaced_base_tensors": replaced_base_keys,
        "reference_override_tensor_count": len(reference_override_keys),
        "reference_override_tensors": reference_override_keys,
        "dspark_extension_tensor_count": len(extension_keys),
        "combined_tensor_count": len(combined_map),
        "extension_payload_size": extension_payload_size,
        "extension_sha256": extension_sha256,
        "patched_shards": len(set(amd_map.values())),
        "schema_match": True,
        "dspark_common_schema_match": True,
        "replaced_prepacked_shared_tensor_count": len(fused_shared_schema),
        "patch_stats": patch_stats,
        "source_total_size": int(amd_index.get("metadata", {}).get("total_size", 0)),
        "combined_total_size": final_index["metadata"]["total_size"],
    }
    write_json_atomic(amd_dir / MANIFEST_NAME, manifest)
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--amd-dir", required=True, type=Path)
    parser.add_argument("--reference-base-dir", required=True, type=Path)
    parser.add_argument("--dspark-dir", required=True, type=Path)
    args = parser.parse_args()
    manifest = compose(
        args.amd_dir.resolve(),
        args.reference_base_dir.resolve(),
        args.dspark_dir.resolve(),
    )
    print(json.dumps(manifest, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
