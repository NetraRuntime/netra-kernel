#!/usr/bin/env python3
"""Validate and HIP-event time the raw gfx1151 BF16 shared-down kernel."""
from __future__ import annotations

import argparse
import hashlib
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
from netra_gfx1151_sglang import netra_bf16_shared_down_with_output  # noqa: E402


def tensor_hash(tensor: torch.Tensor) -> str:
    return hashlib.sha256(tensor.cpu().view(torch.uint8).numpy().tobytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--checkpoint", type=Path, default=Path("/root/models/qwen36-sgl-mxfp4"))
    parser.add_argument("--warmups", type=int, default=3)
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
    items = []
    correctness = []
    torch.manual_seed(args.seed)
    for layer in range(40):
        key = f"model.language_model.layers.{layer}.mlp.shared_expert.down_proj.weight"
        with safe_open(args.checkpoint / index[key], framework="pt", device="cpu") as handle:
            weight = handle.get_tensor(key).cuda().contiguous()
        activation = torch.randn((1, 512), device="cuda", dtype=torch.bfloat16)
        output = torch.empty((1, 2048), device="cuda", dtype=torch.bfloat16)
        reference = torch.mm(activation, weight.t())
        netra_bf16_shared_down_with_output(weight, activation, output)
        torch.cuda.synchronize()
        delta = (reference.float() - output.float()).abs()
        correctness.append({
            "layer": layer,
            "max_abs": float(delta.max()),
            "mean_abs": float(delta.mean()),
            "bf16_mismatches": int((reference != output).sum()),
            "candidate_sha256": tensor_hash(output),
        })
        items.append((weight, activation, output))

    def baseline_pass() -> None:
        temporary = [torch.mm(x, w.t()) for w, x, _ in items]
        del temporary

    def candidate_pass() -> None:
        for weight, activation, output in items:
            netra_bf16_shared_down_with_output(weight, activation, output)

    for _ in range(args.warmups):
        baseline_pass()
        candidate_pass()
    torch.cuda.synchronize()
    samples = {"rocblas": [], "raw_asm": []}
    for iteration in range(args.iterations):
        order = ("rocblas", "raw_asm") if iteration % 2 == 0 else ("raw_asm", "rocblas")
        for variant in order:
            begin = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            begin.record()
            baseline_pass() if variant == "rocblas" else candidate_pass()
            end.record()
            end.synchronize()
            samples[variant].append(begin.elapsed_time(end))
    result = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "shape": {"m": 1, "n": 2048, "k": 512, "layers": 40},
        "correctness": {
            "max_abs": max(row["max_abs"] for row in correctness),
            "max_bf16_mismatches": max(row["bf16_mismatches"] for row in correctness),
            "layers": correctness,
        },
        "hip_event_ms_per_40_layers": {
            key: {"samples": value, "median": statistics.median(value)}
            for key, value in samples.items()
        },
    }
    result["hip_event_ms_per_40_layers"]["median_speedup"] = (
        result["hip_event_ms_per_40_layers"]["rocblas"]["median"]
        / result["hip_event_ms_per_40_layers"]["raw_asm"]["median"]
    )
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
    print(rendered, end="")


if __name__ == "__main__":
    main()
