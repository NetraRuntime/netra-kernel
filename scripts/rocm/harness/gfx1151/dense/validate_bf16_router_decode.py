#!/usr/bin/env python3
"""Validate and HIP-event time the raw gfx1151 BF16-to-FP32 router kernel."""
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
from netra_gfx1151_sglang import netra_bf16_router_with_output  # noqa: E402


def tensor_hash(tensor: torch.Tensor) -> str:
    return hashlib.sha256(tensor.cpu().view(torch.uint8).numpy().tobytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--checkpoint", type=Path, default=Path("/root/models/qwen36-sgl-mxfp4"))
    parser.add_argument("--warmups", type=int, default=5)
    parser.add_argument("--iterations", type=int, default=20)
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
    for layer in range(40):
        key = f"model.language_model.layers.{layer}.mlp.gate.weight"
        with safe_open(args.checkpoint / index[key], framework="pt", device="cpu") as handle:
            weight_cpu = handle.get_tensor(key).contiguous()
        generator = torch.Generator(device="cpu").manual_seed(args.seed + layer)
        activation_cpu = torch.randn((1, 2048), generator=generator, dtype=torch.bfloat16)
        reference = activation_cpu.double().mm(weight_cpu.double().t()).float()
        weight = weight_cpu.cuda().contiguous()
        activation = activation_cpu.cuda().contiguous()
        output = torch.empty((1, 256), device="cuda", dtype=torch.float32)
        netra_bf16_router_with_output(weight, activation, output)
        torch.cuda.synchronize()
        output_cpu = output.cpu()
        delta = (reference - output_cpu).abs()
        correctness.append({
            "layer": layer,
            "max_abs_vs_fp64": float(delta.max()),
            "mean_abs_vs_fp64": float(delta.mean()),
            "top8_set_equal": set(reference.topk(8).indices[0].tolist())
            == set(output_cpu.topk(8).indices[0].tolist()),
            "candidate_sha256": tensor_hash(output),
        })
        items.append((weight, activation, output))

    def candidate_pass() -> None:
        for weight, activation, output in items:
            netra_bf16_router_with_output(weight, activation, output)

    for _ in range(args.warmups):
        candidate_pass()
    torch.cuda.synchronize()
    samples = []
    for _ in range(args.iterations):
        begin = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        begin.record()
        candidate_pass()
        end.record()
        end.synchronize()
        samples.append(begin.elapsed_time(end))

    result = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "reference": "CPU FP64 using the real checkpoint BF16 values",
        "shape": {"m": 1, "n": 256, "k": 2048, "layers": 40},
        "correctness": {
            "max_abs_vs_fp64": max(row["max_abs_vs_fp64"] for row in correctness),
            "all_top8_sets_equal": all(row["top8_set_equal"] for row in correctness),
            "layers": correctness,
        },
        "hip_event_ms_per_40_layers": {
            "samples": samples,
            "median": statistics.median(samples),
            "p90": sorted(samples)[max(0, int(0.9 * len(samples)) - 1)],
        },
    }
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
    print(rendered, end="")


if __name__ == "__main__":
    main()
