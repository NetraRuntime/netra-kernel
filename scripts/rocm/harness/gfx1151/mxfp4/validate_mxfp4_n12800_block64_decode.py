#!/usr/bin/env python3
"""Validate fixed gfx1151 N12800 K2048 MXFP4 block-parallel decode."""
from __future__ import annotations

import argparse
import json
import socket
import statistics
import sys
from pathlib import Path

import torch
from safetensors import safe_open

REPO_ROOT = Path(__file__).resolve().parents[5]
sys.path[:0] = [
    "/root/work/sglang-main/python",
    str(REPO_ROOT / "scripts/rocm/integrations/sglang"),
]
from netra_gfx1151_sglang import (  # noqa: E402
    netra_mxfp4_linear_n12800_k2048_block64_with_output,
    netra_mxfp4_linear_with_output,
)

GDN_LAYERS = (0, 1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 14, 16, 17, 18,
              20, 21, 22, 24, 25, 26, 28, 29, 30, 32, 33, 34, 36, 37, 38)
PROJECTIONS = ("in_proj_qkv", "in_proj_z", "in_proj_a", "in_proj_b")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--checkpoint", type=Path, default=Path("/root/models/qwen36-sgl-mxfp4"))
    parser.add_argument("--iterations", type=int, default=8)
    parser.add_argument("--seed", type=int, default=20260731)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if socket.gethostname() != "Netra":
        raise SystemExit("must run inside the Netra LXC")
    arch = torch.cuda.get_device_properties(0).gcnArchName.split(":")[0]
    if arch != "gfx1151":
        raise SystemExit(f"expected gfx1151, got {arch}")
    index = json.loads((args.checkpoint / "model.safetensors.index.json").read_text())["weight_map"]

    def load(key: str) -> torch.Tensor:
        with safe_open(args.checkpoint / index[key], framework="pt", device="cpu") as handle:
            return handle.get_tensor(key)

    items = []
    correctness = []
    for layer in GDN_LAYERS:
        prefix = f"model.language_model.layers.{layer}.linear_attn."
        packed = torch.cat([
            load(prefix + name + ".weight_packed").t().contiguous()
            for name in PROJECTIONS
        ], dim=1)
        scales = torch.cat([
            load(prefix + name + ".weight_scale").t().contiguous()
            for name in PROJECTIONS
        ], dim=1)
        packed = torch.nn.functional.pad(packed, (0, 12800 - packed.shape[1])).contiguous().cuda()
        scales = torch.nn.functional.pad(scales, (0, 12800 - scales.shape[1])).contiguous().cuda()
        torch.manual_seed(args.seed + layer)
        activation = torch.randn((1, 2048), device="cuda", dtype=torch.bfloat16)
        baseline = torch.empty((1, 12800), device="cuda", dtype=torch.bfloat16)
        candidate = torch.empty_like(baseline)
        workspace = torch.empty((64, 12800), device="cuda", dtype=torch.float32)
        netra_mxfp4_linear_with_output(packed, scales, activation, baseline, 1, 12800, 2048)
        netra_mxfp4_linear_n12800_k2048_block64_with_output(
            packed, scales, activation, workspace, candidate
        )
        torch.cuda.synchronize()
        correctness.append({
            "layer": layer,
            "bf16_mismatches": int((baseline != candidate).sum()),
            "max_abs": float((baseline.float() - candidate.float()).abs().max()),
        })
        items.append((packed, scales, activation, baseline, candidate, workspace))

    def baseline_pass() -> None:
        for packed, scales, activation, output, _, _ in items:
            netra_mxfp4_linear_with_output(packed, scales, activation, output, 1, 12800, 2048)

    def candidate_pass() -> None:
        for packed, scales, activation, _, output, workspace in items:
            netra_mxfp4_linear_n12800_k2048_block64_with_output(
                packed, scales, activation, workspace, output
            )

    for _ in range(2):
        baseline_pass(); candidate_pass()
    torch.cuda.synchronize()
    samples = {"baseline": [], "candidate": []}
    for iteration in range(args.iterations):
        order = ("baseline", "candidate") if iteration % 2 == 0 else ("candidate", "baseline")
        for variant in order:
            begin = torch.cuda.Event(enable_timing=True); end = torch.cuda.Event(enable_timing=True)
            begin.record(); baseline_pass() if variant == "baseline" else candidate_pass(); end.record(); end.synchronize()
            samples[variant].append(begin.elapsed_time(end))
    result = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "shape": {"m": 1, "n": 12800, "k": 2048, "layers": 30},
        "correctness": {
            "bit_exact_all_layers": all(row["bf16_mismatches"] == 0 for row in correctness),
            "layers": correctness,
        },
        "hip_event_ms_per_30_layers": {
            key: {"samples": value, "median": statistics.median(value)}
            for key, value in samples.items()
        },
    }
    result["hip_event_ms_per_30_layers"]["median_speedup"] = (
        result["hip_event_ms_per_30_layers"]["baseline"]["median"]
        / result["hip_event_ms_per_30_layers"]["candidate"]["median"]
    )
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True); args.output.write_text(rendered)
    print(rendered, end="")


if __name__ == "__main__":
    main()
