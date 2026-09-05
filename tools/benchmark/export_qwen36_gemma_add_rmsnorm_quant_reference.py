#!/usr/bin/env python3
"""Export deployed group-FP8 quant bytes for a retained Gemma norm output."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import torch
from aiter import add_rmsnorm_quant
from sglang.srt.layers.quantization.fp8_kernel import per_token_group_quant_fp8


def load_bf16(path: Path, shape: tuple[int, ...]) -> torch.Tensor:
    payload = bytearray(path.read_bytes())
    return (
        torch.frombuffer(payload, dtype=torch.uint8)
        .clone()
        .view(torch.bfloat16)
        .reshape(shape)
        .cuda()
    )


def payload(tensor: torch.Tensor) -> bytes:
    return (
        tensor.detach()
        .contiguous()
        .cpu()
        .view(torch.uint8)
        .numpy()
        .tobytes()
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    if args.output_dir.exists():
        raise FileExistsError(f"refusing to overwrite {args.output_dir}")
    props = torch.cuda.get_device_properties(0)
    if not props.gcnArchName.startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {props.gcnArchName}")

    capture = args.capture_dir
    norm_output = load_bf16(capture / "output_bf16.bin", (1, 2048))
    inp = load_bf16(capture / "input_bf16.bin", (1, 2048))
    residual = load_bf16(capture / "residual_bf16.bin", (1, 2048))
    weight = load_bf16(capture / "weight_bf16.bin", (2048,))
    residual_expected = load_bf16(
        capture / "residual_out_bf16.bin", (1, 2048)
    )

    quantized, scales = per_token_group_quant_fp8(norm_output, 128)
    fused_quantized = torch.empty_like(quantized)
    fused_scales = torch.empty_like(scales)
    fused_residual = torch.empty_like(residual)
    add_rmsnorm_quant(
        fused_quantized,
        inp,
        residual,
        fused_residual,
        fused_scales,
        weight,
        1.0e-6,
        128,
        False,
        False,
    )
    torch.cuda.synchronize()

    args.output_dir.mkdir(parents=True)
    quantized_payload = payload(quantized)
    scale_payload = payload(scales)
    (args.output_dir / "output_fp8.bin").write_bytes(quantized_payload)
    (args.output_dir / "output_scale_f32.bin").write_bytes(scale_payload)
    report = {
        "architecture": props.gcnArchName,
        "source_capture": str(capture.resolve()),
        "shape": {"m": 1, "n": 2048, "group_size": 128},
        "quantized_dtype": str(quantized.dtype),
        "scale_shape": list(scales.shape),
        "quantized_sha256": hashlib.sha256(quantized_payload).hexdigest(),
        "scale_sha256": hashlib.sha256(scale_payload).hexdigest(),
        "aiter_fused_negative": {
            "quantized_byte_mismatches": int(
                torch.ne(
                    fused_quantized.view(torch.uint8),
                    quantized.view(torch.uint8),
                )
                .sum()
                .item()
            ),
            "scale_mismatches": int(torch.ne(fused_scales, scales).sum().item()),
            "maximum_scale_error": float(
                torch.max(torch.abs(fused_scales - scales)).item()
            ),
            "residual_bf16_mismatches": int(
                torch.ne(fused_residual, residual_expected).sum().item()
            ),
        },
    }
    (args.output_dir / "manifest.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
