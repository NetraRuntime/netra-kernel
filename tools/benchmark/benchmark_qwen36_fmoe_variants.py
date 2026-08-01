#!/usr/bin/env python3
"""Benchmark AITER's complete Qwen3.6 FP8 fused-MoE gfx950 variants.

This is an isolated tile-selection oracle for a retained real-checkpoint call.
It times only the complete one-stage expert kernel (gate/up, SiLU, down,
routing weight, and output accumulation).  Sorting and input quantization are
prepared once and are intentionally excluded from the kernel timing.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path

import torch

import aiter
from aiter import ActivationType, QuantType
from aiter.fused_moe import moe_sorting


@dataclass(frozen=True)
class Variant:
    kernel_name: str
    block_m: int


VARIANTS = (
    Variant("_ZN5aiter50fmoe_bf16_blockscaleFp8_g1u1_vs_silu_1tg_ps_32x256E", 32),
    Variant("_ZN5aiter52fmoe_bf16_blockscaleFp8_g1u1_novs_silu_1tg_ps_32x256E", 32),
    Variant("_ZN5aiter47fmoe_bf16_blockscaleFp8_g1u1_vs_ps_silu_32x128E", 32),
    Variant("_ZN5aiter49fmoe_bf16_blockscaleFp8_g1u1_novs_silu_1tg_32x256E", 32),
    Variant("_ZN5aiter47fmoe_bf16_blockscaleFp8_g1u1_vs_silu_1tg_32x256E", 32),
    Variant("_ZN5aiter46fmoe_bf16_blockscaleFp8_g1u1_vs_ps_silu_64x256E", 64),
    Variant("_ZN5aiter46fmoe_bf16_blockscaleFp8_g1u1_vs_ps_silu_64x128E", 64),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--warmup", type=int, default=10)
    parser.add_argument("--repeats", type=int, default=50)
    parser.add_argument("--device", default="cuda")
    parser.add_argument(
        "--kernel-name",
        action="append",
        help="exact mangled symbol to run; repeat for multiple variants",
    )
    return parser.parse_args()


def load_capture(capture_dir: Path) -> dict[str, torch.Tensor]:
    load = lambda name: torch.load(  # noqa: E731
        capture_dir / name, map_location="cpu", weights_only=True
    )
    call = load("aiter_moe_call_000.pt")
    input_quant = load("aiter_moe_input_quant_000.pt")
    stage2 = load("aiter_moe_stage2_000.pt")

    selected = call["selected_expert_ids_i32"].to(torch.int64).contiguous()
    resident = stage2["resident_expert_ids_i32"].to(torch.int64).contiguous()
    if not torch.equal(selected, resident):
        raise ValueError("captured gate/up and down expert sets or ordering disagree")
    compact_by_global = {int(value): index for index, value in enumerate(selected)}
    topk_global = call["topk_ids_i32"].to(torch.int64)
    compact_topk = torch.empty_like(topk_global, dtype=torch.int32)
    for global_expert, compact_expert in compact_by_global.items():
        compact_topk[topk_global == global_expert] = compact_expert
    if not torch.equal(
        selected[compact_topk.to(torch.int64)].reshape_as(topk_global), topk_global
    ):
        raise ValueError("failed to remap all routed experts to compact IDs")

    # The capture hook sees the original FP32 [E,16,4] down-scale bytes
    # through AITER's E8M0 [E,16,16] view. Recover the FP32 view expected by
    # the block-scale assembly ABI without changing any quantization format.
    w2_scale = stage2["resident_w2_scale"].contiguous()
    w2_scale_f32 = w2_scale.view(torch.float32).reshape(selected.numel(), 16, 4)
    return {
        "hidden_bf16": input_quant["hidden_states_bf16"].contiguous(),
        "w1_fp8": call["selected_w1_fp8"].contiguous(),
        "w1_scale": call["selected_w1_scale"].contiguous(),
        "w2_fp8": stage2["resident_w2_fp8"].contiguous(),
        "w2_scale": w2_scale_f32.contiguous(),
        "topk_ids": compact_topk.contiguous(),
        "topk_weights": call["topk_weights_fp32"].contiguous(),
        "reference": call["output_bf16"].contiguous(),
        "selected_experts": selected,
    }


def percentiles(samples: list[float]) -> dict[str, float]:
    values = torch.tensor(samples, dtype=torch.float64)
    return {
        "mean_us": float(values.mean()),
        "median_us": float(values.quantile(0.5)),
        "p90_us": float(values.quantile(0.9)),
        "min_us": float(values.min()),
        "max_us": float(values.max()),
    }


def main() -> None:
    args = parse_args()
    if args.warmup < 1 or args.repeats < 2:
        raise ValueError("warmup must be >=1 and repeats must be >=2")
    device = torch.device(args.device)
    props = torch.cuda.get_device_properties(device)
    arch = str(getattr(props, "gcnArchName", ""))
    if not arch.startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {arch}")

    cpu = load_capture(args.capture_dir)
    data = {name: value.to(device) for name, value in cpu.items()}
    rows, hidden = data["hidden_bf16"].shape
    topk = data["topk_ids"].shape[1]
    experts = data["selected_experts"].numel()
    # The retained two-stage capture stores row-major activation scales. The
    # one-stage assembly ABI consumes AITER's transposed scale layout. Recreate
    # that layout once from the identical captured BF16 input; the FP8 payload
    # itself is unchanged.
    quant = aiter.get_hip_quant(QuantType.per_1x128)
    hidden_fp8, hidden_scale = quant(
        data["hidden_bf16"],
        quant_dtype=torch.float8_e4m3fn,
        transpose_scale=True,
    )
    variants = (
        tuple(
            variant
            for variant in VARIANTS
            if variant.kernel_name in set(args.kernel_name)
        )
        if args.kernel_name
        else VARIANTS
    )
    if not variants:
        raise ValueError("--kernel-name did not match a registered safe variant")
    prepared: dict[int, tuple[torch.Tensor, ...]] = {}
    for block_m in sorted({variant.block_m for variant in variants}):
        prepared[block_m] = moe_sorting(
            data["topk_ids"],
            data["topk_weights"],
            experts,
            hidden,
            torch.bfloat16,
            block_size=block_m,
        )
    torch.cuda.synchronize(device)

    results: list[dict[str, object]] = []
    for variant in variants:
        sorted_ids, sorted_weights, sorted_experts, num_valid, output = prepared[
            variant.block_m
        ]

        def invoke() -> None:
            output.zero_()
            aiter.fmoe_fp8_blockscale_g1u1(
                output,
                hidden_fp8,
                data["w1_fp8"],
                data["w2_fp8"],
                sorted_ids,
                sorted_weights,
                sorted_experts,
                num_valid,
                topk,
                hidden_scale,
                data["w1_scale"],
                data["w2_scale"],
                variant.kernel_name,
                fc_scale_blkn=128,
                fc_scale_blkk=128,
                fc2_smooth_scale=None,
                activation=ActivationType.Silu,
                block_size_M=variant.block_m,
            )

        try:
            for _ in range(args.warmup):
                invoke()
            torch.cuda.synchronize(device)
            samples: list[float] = []
            start = torch.cuda.Event(enable_timing=True)
            stop = torch.cuda.Event(enable_timing=True)
            for _ in range(args.repeats):
                output.zero_()
                start.record()
                aiter.fmoe_fp8_blockscale_g1u1(
                    output,
                    hidden_fp8,
                    data["w1_fp8"],
                    data["w2_fp8"],
                    sorted_ids,
                    sorted_weights,
                    sorted_experts,
                    num_valid,
                    topk,
                    hidden_scale,
                    data["w1_scale"],
                    data["w2_scale"],
                    variant.kernel_name,
                    fc_scale_blkn=128,
                    fc_scale_blkk=128,
                    fc2_smooth_scale=None,
                    activation=ActivationType.Silu,
                    block_size_M=variant.block_m,
                )
                stop.record()
                stop.synchronize()
                samples.append(start.elapsed_time(stop) * 1000.0)

            delta = output.float() - data["reference"].float()
            cosine = torch.nn.functional.cosine_similarity(
                output.float().reshape(1, -1),
                data["reference"].float().reshape(1, -1),
            )
            result: dict[str, object] = {
                "kernel_name": variant.kernel_name,
                "block_m": variant.block_m,
                "status": "ok",
                **percentiles(samples),
                "correctness": {
                    "bf16_mismatches": int(
                        torch.ne(output, data["reference"]).sum().item()
                    ),
                    "max_abs": float(delta.abs().max().item()),
                    "mean_abs": float(delta.abs().mean().item()),
                    "cosine": float(cosine.item()),
                    "finite": bool(torch.isfinite(output).all().item()),
                },
            }
        except Exception as error:  # retain rejected/unsupported variants
            torch.cuda.synchronize(device)
            result = {
                "kernel_name": variant.kernel_name,
                "block_m": variant.block_m,
                "status": "error",
                "error": f"{type(error).__name__}: {error}",
            }
        results.append(result)
        print(json.dumps(result, sort_keys=True), flush=True)

    report = {
        "schema_version": 1,
        "device": props.name,
        "arch": arch,
        "quantization": "FP8 E4M3, 128x128 blocks",
        "shape": {
            "rows": rows,
            "topk": topk,
            "hidden": hidden,
            "intermediate": data["w2_fp8"].shape[-1],
            "active_experts": experts,
        },
        "timing_scope": "complete fused MoE assembly only; excludes zero, sort, and input quant",
        "reference": "captured complete AITER output_bf16 from the same real-checkpoint call",
        "results": results,
    }
    payload = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(payload, encoding="utf-8")
    print(payload)


if __name__ == "__main__":
    main()
