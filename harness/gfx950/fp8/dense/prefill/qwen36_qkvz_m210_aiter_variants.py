#!/usr/bin/env python3
"""Validate AITER gfx950 block-FP8 variants on real Qwen projections.

The input is a guarded SGLang correctness StatePass containing exact operands
from the pinned FP8 E4M3 128x128 checkpoint. This is an attribution/oracle
harness; accepted Netra compute kernels still must be raw gfx950 AMDGCN in
this repository.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import statistics
import time
from pathlib import Path
from typing import Callable

import torch

import aiter
from aiter import get_hip_quant
from aiter.ops.gemm_op_a8w8 import (
    gemm_a8w8_blockscale_bpreshuffle,
    gemm_a8w8_blockscale_bpreshuffle_ck,
    gemm_a8w8_blockscale_bpreshuffle_cktile,
)
from aiter.ops.triton.gemm.basic.gemm_a8w8_blockscale import (
    gemm_a8w8_blockscale_preshuffle,
)


M = 210
N = 12288
K = 2048
BLOCK = 128
PROJECTIONS = {
    "gdn_qkvz": {
        "layer_id": 0,
        "input_stage": "input",
        "output_stage": "in_proj_qkvz",
        "n": 12288,
    },
    "attn_qkv": {
        "layer_id": 3,
        "input_stage": "attention.input",
        "output_stage": "attention.qkv_proj",
        "n": 9216,
    },
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=20)
    parser.add_argument("--warmup", type=int, default=3)
    parser.add_argument(
        "--projection",
        choices=tuple(PROJECTIONS),
        default="gdn_qkvz",
    )
    return parser.parse_args()


def tensor_sha256(tensor: torch.Tensor) -> str:
    cpu = tensor.detach().contiguous().cpu()
    return hashlib.sha256(cpu.view(torch.uint8).numpy().tobytes()).hexdigest()


def load_operands(
    path: Path, projection: dict[str, int | str]
) -> dict[str, torch.Tensor]:
    payload = torch.load(path, map_location="cpu", weights_only=False)
    prefix = f"gdn_stage.layer.{projection['layer_id']}."
    input_stage = str(projection["input_stage"])
    output_stage = str(projection["output_stage"])
    operands = {
        "input": payload[f"{prefix}{input_stage}"],
        "weight": payload[f"{prefix}{output_stage}.weight"],
        "weight_scale": payload[f"{prefix}{output_stage}.weight_scale"],
        "deployed_output": payload[f"{prefix}{output_stage}"],
    }
    expected = {
        "input": ((M, K), torch.bfloat16),
        "weight": ((N, K), torch.float8_e4m3fn),
        "weight_scale": ((N // BLOCK, K // BLOCK), torch.float32),
        "deployed_output": ((M, N), torch.bfloat16),
    }
    for name, tensor in operands.items():
        shape, dtype = expected[name]
        if tuple(tensor.shape) != shape or tensor.dtype != dtype:
            raise ValueError(
                f"{name}: expected shape={shape} dtype={dtype}, "
                f"got shape={tuple(tensor.shape)} dtype={tensor.dtype}"
            )
    return operands


def quantize(
    input_tensor: torch.Tensor,
) -> tuple[torch.Tensor, torch.Tensor]:
    quant = get_hip_quant(aiter.QuantType.per_1x128)
    return quant(
        input_tensor,
        quant_dtype=aiter.dtypes.fp8,
        transpose_scale=True,
    )


def default_triton_preshuffle_config() -> dict[str, int | str]:
    return {
        "BLOCK_SIZE_M": 32,
        "BLOCK_SIZE_N": 16,
        "BLOCK_SIZE_K": 128,
        "GROUP_SIZE_M": 1,
        "num_warps": 4,
        "num_stages": 2,
        "waves_per_eu": 8,
        "matrix_instr_nonkdim": 16,
        "cache_modifier": ".cg",
        "NUM_KSPLIT": 1,
        "kpack": 2,
    }


def unshuffle_weight(weight: torch.Tensor) -> torch.Tensor:
    """Invert AITER shuffle_weight(..., (16, 16)) for byte-wide FP8."""
    return (
        weight.view(N // 16, K // 32, 2, 16, 16)
        .permute(0, 3, 1, 2, 4)
        .contiguous()
        .view(N, K)
    )


def fp32_oracle(
    q_input: torch.Tensor,
    x_scale: torch.Tensor,
    weight: torch.Tensor,
    weight_scale: torch.Tensor,
) -> torch.Tensor:
    # AITER transpose_scale=True stores a logical [M, K/128] scale matrix as
    # transpose(...).contiguous().view(M, K/128) for the GEMM kernel.
    logical_x_scale = (
        x_scale.view(K // BLOCK, M).transpose(0, 1).contiguous()
    )
    q_dequant = q_input.float() * logical_x_scale.float().repeat_interleave(
        BLOCK, dim=1
    )
    logical_weight = unshuffle_weight(weight)
    weight_dequant = logical_weight.float() * (
        weight_scale.float()
        .repeat_interleave(BLOCK, dim=0)
        .repeat_interleave(BLOCK, dim=1)
    )
    return torch.mm(q_dequant, weight_dequant.t())


def difference(reference: torch.Tensor, candidate: torch.Tensor) -> dict:
    reference_float = reference.float()
    candidate_float = candidate.float()
    delta = (reference_float - candidate_float).abs()
    dot = torch.sum(reference_float * candidate_float)
    denom = torch.linalg.vector_norm(reference_float) * torch.linalg.vector_norm(
        candidate_float
    )
    return {
        "mismatch_count": int(torch.ne(reference, candidate).sum().item()),
        "maximum_abs_error": float(delta.max().item()),
        "mean_abs_error": float(delta.mean().item()),
        "cosine_similarity": float((dot / denom).item()),
        "candidate_sha256": tensor_sha256(candidate),
        "reference_sha256": tensor_sha256(reference),
    }


def variants(
    weight: torch.Tensor,
    weight_scale: torch.Tensor,
) -> dict[str, Callable[[torch.Tensor, torch.Tensor], torch.Tensor]]:
    def wrapper(q_input: torch.Tensor, x_scale: torch.Tensor) -> torch.Tensor:
        return gemm_a8w8_blockscale_bpreshuffle(
            q_input,
            weight,
            x_scale,
            weight_scale,
            dtype=torch.bfloat16,
        )

    def ck_empty(q_input: torch.Tensor, x_scale: torch.Tensor) -> torch.Tensor:
        out = torch.empty((M, N), dtype=torch.bfloat16, device=q_input.device)
        return gemm_a8w8_blockscale_bpreshuffle_ck(
            q_input, weight, x_scale, weight_scale, out
        )

    def ck_zero(q_input: torch.Tensor, x_scale: torch.Tensor) -> torch.Tensor:
        out = torch.zeros((M, N), dtype=torch.bfloat16, device=q_input.device)
        return gemm_a8w8_blockscale_bpreshuffle_ck(
            q_input, weight, x_scale, weight_scale, out
        )

    def cktile_empty(q_input: torch.Tensor, x_scale: torch.Tensor) -> torch.Tensor:
        out = torch.empty((M, N), dtype=torch.bfloat16, device=q_input.device)
        return gemm_a8w8_blockscale_bpreshuffle_cktile(
            q_input, weight, x_scale, weight_scale, out
        )

    def triton_preshuffle(
        q_input: torch.Tensor, x_scale: torch.Tensor
    ) -> torch.Tensor:
        return gemm_a8w8_blockscale_preshuffle(
            q_input,
            weight.reshape(N // 16, K * 16),
            x_scale,
            weight_scale,
            dtype=torch.bfloat16,
            config=default_triton_preshuffle_config(),
            is_x_scale_tranposed=True,
        )

    return {
        "wrapper": wrapper,
        "ck_empty": ck_empty,
        "ck_zero": ck_zero,
        "cktile_empty": cktile_empty,
        "triton_preshuffle": triton_preshuffle,
    }


def measure_variant(
    name: str,
    fn: Callable[[torch.Tensor, torch.Tensor], torch.Tensor],
    input_tensor: torch.Tensor,
    iterations: int,
    warmup: int,
) -> dict:
    hashes: list[str] = []
    durations_us: list[float] = []
    quant_hashes: list[tuple[str, str]] = []
    reference: torch.Tensor | None = None
    max_abs_from_first = 0.0
    mismatch_from_first = 0

    for iteration in range(warmup + iterations):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        q_input, x_scale = quantize(input_tensor)
        output = fn(q_input, x_scale)
        end.record()
        end.synchronize()
        if iteration < warmup:
            continue

        durations_us.append(float(start.elapsed_time(end)) * 1000.0)
        hashes.append(tensor_sha256(output))
        quant_hashes.append(
            (tensor_sha256(q_input), tensor_sha256(x_scale))
        )
        if reference is None:
            reference = output.detach().clone()
        else:
            mismatch_from_first = max(
                mismatch_from_first,
                int(torch.ne(reference, output).sum().item()),
            )
            max_abs_from_first = max(
                max_abs_from_first,
                float((reference.float() - output.float()).abs().max().item()),
            )

    return {
        "name": name,
        "iterations": iterations,
        "unique_output_hashes": len(set(hashes)),
        "output_hashes": hashes,
        "unique_quantized_input_hashes": len(
            {item[0] for item in quant_hashes}
        ),
        "unique_input_scale_hashes": len({item[1] for item in quant_hashes}),
        "maximum_mismatch_count_from_first": mismatch_from_first,
        "maximum_abs_error_from_first": max_abs_from_first,
        "duration_us": {
            "minimum": min(durations_us),
            "median": statistics.median(durations_us),
            "maximum": max(durations_us),
        },
    }


def main() -> None:
    global N

    args = parse_args()
    if args.iterations <= 0 or args.warmup < 0:
        raise ValueError("iterations must be positive and warmup nonnegative")
    if torch.version.hip is None:
        raise RuntimeError("This harness requires ROCm")
    props = torch.cuda.get_device_properties(0)
    if props.gcnArchName.split(":", 1)[0] != "gfx950":
        raise RuntimeError(f"Expected gfx950, got {props.gcnArchName}")

    projection = PROJECTIONS[args.projection]
    N = int(projection["n"])
    loaded = load_operands(args.capture, projection)
    device_operands = {
        name: tensor.cuda() for name, tensor in loaded.items()
    }
    input_tensor = device_operands["input"]
    weight = device_operands["weight"]
    weight_scale = device_operands["weight_scale"]

    report = {
        "schema_version": 1,
        "measurement_status": "measured",
        "architecture": "gfx950",
        "rocm": torch.version.hip,
        "capture": str(args.capture),
        "capture_sha256": hashlib.sha256(args.capture.read_bytes()).hexdigest(),
        "projection": args.projection,
        "shape": {"M": M, "N": N, "K": K},
        "quantization": "FP8 E4M3, 128x128 blocks",
        "deployed_output_sha256": tensor_sha256(
            device_operands["deployed_output"]
        ),
        "variants": [],
        "started_unix_ns": time.time_ns(),
    }
    for name, fn in variants(weight, weight_scale).items():
        try:
            result = measure_variant(
                name, fn, input_tensor, args.iterations, args.warmup
            )
        except Exception as error:
            result = {
                "name": name,
                "error": f"{type(error).__name__}: {error}",
            }
        report["variants"].append(result)
        print(json.dumps(result, sort_keys=True), flush=True)

    q_input, x_scale = quantize(input_tensor)
    oracle_fp32 = fp32_oracle(q_input, x_scale, weight, weight_scale)
    oracle_bf16 = oracle_fp32.to(torch.bfloat16)
    report["oracle"] = {
        "definition": (
            "FP32 matmul of exact runtime FP8 activation/weight values "
            "dequantized by their 1x128/128x128 scales"
        ),
        "fp32_sha256": tensor_sha256(oracle_fp32),
        "bf16_sha256": tensor_sha256(oracle_bf16),
        "deployed_output_vs_bf16_oracle": difference(
            oracle_bf16, device_operands["deployed_output"]
        ),
        "variant_vs_bf16_oracle": {},
    }
    for name, fn in variants(weight, weight_scale).items():
        try:
            output = fn(q_input, x_scale)
            torch.cuda.synchronize()
            report["oracle"]["variant_vs_bf16_oracle"][name] = difference(
                oracle_bf16, output
            )
        except Exception as error:
            report["oracle"]["variant_vs_bf16_oracle"][name] = {
                "error": f"{type(error).__name__}: {error}"
            }

    report["finished_unix_ns"] = time.time_ns()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
