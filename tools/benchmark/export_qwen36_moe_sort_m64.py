#!/usr/bin/env python3
"""Re-sort a retained real Qwen3.6 MoE call with AITER's M64 ABI."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import torch
from aiter.fused_moe import moe_sorting


def write_tensor(root: Path, name: str, tensor: torch.Tensor) -> dict[str, object]:
    value = tensor.detach().contiguous().cpu()
    payload = value.view(torch.uint8).numpy().tobytes()
    (root / f"{name}.bin").write_bytes(payload)
    return {
        "file": f"{name}.bin",
        "shape": list(value.shape),
        "dtype": str(value.dtype),
        "bytes": len(payload),
        "sha256": hashlib.sha256(payload).hexdigest(),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    call = torch.load(
        args.capture_dir / "aiter_moe_call_000.pt",
        map_location="cpu",
        weights_only=True,
    )
    selected = call["selected_expert_ids_i32"].to(torch.int64).contiguous()
    topk_global = call["topk_ids_i32"].to(torch.int64).contiguous()
    weights = call["topk_weights_fp32"].contiguous()
    compact = torch.empty_like(topk_global, dtype=torch.int32)
    for compact_id, global_id in enumerate(selected.tolist()):
        compact[topk_global == int(global_id)] = compact_id
    if not torch.equal(selected[compact.to(torch.int64)], topk_global):
        raise RuntimeError("failed to compact all expert IDs")

    device = torch.device("cuda")
    props = torch.cuda.get_device_properties(device)
    arch = str(getattr(props, "gcnArchName", ""))
    if not arch.startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {arch}")
    sorted_ids, sorted_weights, sorted_experts, num_valid, _ = moe_sorting(
        compact.to(device),
        weights.to(device),
        selected.numel(),
        2048,
        torch.bfloat16,
        block_size=64,
    )
    torch.cuda.synchronize()
    valid = int(num_valid.cpu().view(-1)[0].item())
    if valid % 64:
        raise RuntimeError(f"M64 sorting produced unaligned count {valid}")
    blocks = valid // 64
    tensors = {
        "sorted_token_ids_m64_i32": sorted_ids.to(torch.int32),
        "sorted_weights_m64_f32": sorted_weights.to(torch.float32),
        "compact_sorted_expert_ids_m64_i32": sorted_experts[:blocks].to(torch.int32),
        "num_valid_ids_m64_i32": num_valid.to(torch.int32),
    }
    manifest = {
        "schema_version": 1,
        "architecture": arch,
        "source": str(args.capture_dir),
        "block_m": 64,
        "rows": int(topk_global.shape[0]),
        "topk": int(topk_global.shape[1]),
        "active_experts": int(selected.numel()),
        "valid_sorted_ids": valid,
        "valid_blocks": blocks,
        "sorted_token_encoding": "(topk_slot << 24) | token_row; slot 9 is padding",
        "tensors": {
            name: write_tensor(args.output_dir, name, tensor)
            for name, tensor in tensors.items()
        },
    }
    (args.output_dir / "m64_sort_manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(manifest, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
