#!/usr/bin/env python3
"""Time the deployed AITER dense M=1 FP8 kernel on retained operands."""

from __future__ import annotations

import argparse
import hashlib
import json
import statistics
from pathlib import Path

import torch
from aiter.ops.gemm_op_a8w8 import gemm_a8w8_blockscale_bpreshuffle


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=200)
    parser.add_argument("--warmup", type=int, default=10)
    parser.add_argument("--graph-replays", type=int, default=20)
    return parser.parse_args()


def load_raw(
    path: Path,
    dtype: torch.dtype,
    shape: tuple[int, ...],
) -> torch.Tensor:
    payload = bytearray(path.read_bytes())
    tensor = torch.frombuffer(payload, dtype=torch.uint8).clone()
    return tensor.view(dtype).reshape(shape).cuda()


def tensor_sha256(tensor: torch.Tensor) -> str:
    payload = (
        tensor.detach()
        .contiguous()
        .cpu()
        .view(torch.uint8)
        .numpy()
        .tobytes()
    )
    return hashlib.sha256(payload).hexdigest()


def main() -> None:
    args = parse_args()
    if args.iterations <= 0 or args.warmup < 0 or args.graph_replays < 0:
        raise ValueError("invalid iteration count")
    props = torch.cuda.get_device_properties(0)
    architecture = props.gcnArchName
    if not architecture.startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    q_input = load_raw(
        args.capture_dir / "q_input.bin",
        torch.float8_e4m3fn,
        (1, 4096),
    )
    x_scale = load_raw(
        args.capture_dir / "x_scale.bin", torch.float32, (1, 32)
    )
    weight = load_raw(
        args.capture_dir / "weight.bin",
        torch.float8_e4m3fn,
        (2048, 4096),
    )
    weight_scale = load_raw(
        args.capture_dir / "weight_scale.bin",
        torch.float32,
        (16, 32),
    )
    deployed = load_raw(
        args.capture_dir / "output_bf16.bin",
        torch.bfloat16,
        (1, 2048),
    )

    def launch() -> torch.Tensor:
        return gemm_a8w8_blockscale_bpreshuffle(
            q_input,
            weight,
            x_scale,
            weight_scale,
            dtype=torch.bfloat16,
        )

    for _ in range(args.warmup):
        output = launch()
    torch.cuda.synchronize()
    durations_us: list[float] = []
    hashes: list[str] = []
    maximum_mismatch_count = 0
    for _ in range(args.iterations):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        output = launch()
        end.record()
        end.synchronize()
        durations_us.append(float(start.elapsed_time(end)) * 1000.0)
        maximum_mismatch_count = max(
            maximum_mismatch_count,
            int(torch.ne(output, deployed).sum().item()),
        )
        hashes.append(tensor_sha256(output))

    graph_result = None
    if args.graph_replays:
        graph = torch.cuda.CUDAGraph()
        torch.cuda.synchronize()
        with torch.cuda.graph(graph):
            graph_output = launch()
        torch.cuda.synchronize()
        graph_hashes: list[str] = []
        graph_maximum_mismatch_count = 0
        for _ in range(args.graph_replays):
            graph.replay()
            torch.cuda.synchronize()
            graph_hashes.append(tensor_sha256(graph_output))
            graph_maximum_mismatch_count = max(
                graph_maximum_mismatch_count,
                int(torch.ne(graph_output, deployed).sum().item()),
            )
        graph_result = {
            "replays": args.graph_replays,
            "unique_output_hashes": len(set(graph_hashes)),
            "maximum_mismatch_count": graph_maximum_mismatch_count,
        }

    result = {
        "architecture": architecture,
        "shape": {"m": 1, "n": 2048, "k": 4096},
        "quantization": "FP8 E4M3, 128x128 blocks",
        "iterations": args.iterations,
        "unique_output_hashes": len(set(hashes)),
        "output_sha256": hashes[0],
        "maximum_mismatch_count": maximum_mismatch_count,
        "duration_us": {
            "minimum": min(durations_us),
            "median": statistics.median(durations_us),
            "p90": sorted(durations_us)[
                min(
                    len(durations_us) - 1,
                    int(0.9 * len(durations_us)),
                )
            ],
            "maximum": max(durations_us),
            "mean": statistics.fmean(durations_us),
        },
        "graph": graph_result,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    if args.output.exists():
        raise FileExistsError(f"refusing to overwrite {args.output}")
    args.output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
