#!/usr/bin/env python3
"""One-time Qwen3.6 LM-head repack to OCP MXFP4, without dequantized storage."""

import argparse
import json
import math
import struct
from pathlib import Path

import numpy as np
import torch


LEVELS = torch.tensor([0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0])
THRESHOLDS = torch.tensor([0.25, 0.75, 1.25, 1.75, 2.5, 3.5, 5.0])


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("model", type=Path)
    ap.add_argument("output", type=Path)
    ap.add_argument("--chunk-rows", type=int, default=2048)
    args = ap.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    index = json.loads((args.model / "model.safetensors.index.json").read_text())
    shard = args.model / index["weight_map"]["lm_head.weight"]
    with shard.open("rb") as f:
        header_len = struct.unpack("<Q", f.read(8))[0]
        header = json.loads(f.read(header_len))
    tensor_meta = header["lm_head.weight"]
    begin, end = tensor_meta["data_offsets"]
    payload_begin = 8 + header_len + begin
    mapped = torch.from_file(
        str(shard), shared=False, size=shard.stat().st_size, dtype=torch.uint8
    )
    weight = mapped[payload_begin : payload_begin + end - begin].view(
        torch.bfloat16
    ).reshape(tensor_meta["shape"])
    if weight.dtype != torch.bfloat16 or weight.ndim != 2:
        raise RuntimeError(f"expected BF16 [N,K] lm_head, got {weight.dtype} {weight.shape}")
    n, k = map(int, weight.shape)
    if k % 32:
        raise RuntimeError("K must be divisible by the MXFP4 block size")

    packed_path = args.output / "lm_head_packed_kmajor.bin"
    scales_path = args.output / "lm_head_scales_kmajor.bin"
    packed_out = np.memmap(packed_path, dtype=np.uint8, mode="w+", shape=(k // 2, n))
    scales_out = np.memmap(scales_path, dtype=np.uint8, mode="w+", shape=(k // 32, n))
    levels = LEVELS.cuda()
    thresholds = THRESHOLDS.cuda()
    scale_min, scale_max = 255, 0
    squared_error = 0.0
    squared_reference = 0.0

    for begin in range(0, n, args.chunk_rows):
        end = min(begin + args.chunk_rows, n)
        x = weight[begin:end].to("cuda", dtype=torch.float32).reshape(end - begin, k // 32, 32)
        max_abs = x.abs().amax(dim=2)
        exponent = torch.ceil(torch.log2(torch.clamp(max_abs / 6.0, min=2.0**-126))).to(torch.int32)
        scale_byte = torch.clamp(exponent + 127, 1, 254).to(torch.uint8)
        scale = torch.exp2(exponent.to(torch.float32))
        normalized = x.abs() / scale.unsqueeze(2)
        magnitude = torch.bucketize(normalized, thresholds).to(torch.uint8)
        sign = torch.signbit(x).to(torch.uint8) << 3
        code = magnitude | sign
        packed = code[..., 0::2] | (code[..., 1::2] << 4)

        # Check the quantizer while values are resident. This error is quantization
        # error versus the original BF16 checkpoint, not kernel arithmetic error.
        reconstructed = levels[magnitude.long()] * scale.unsqueeze(2)
        reconstructed = torch.where(torch.signbit(x), -reconstructed, reconstructed)
        squared_error += torch.sum((reconstructed - x) ** 2, dtype=torch.float64).item()
        squared_reference += torch.sum(x**2, dtype=torch.float64).item()

        packed_out[:, begin:end] = packed.reshape(end - begin, k // 2).cpu().numpy().T
        scales_out[:, begin:end] = scale_byte.cpu().numpy().T
        scale_min = min(scale_min, int(scale_byte.min().item()))
        scale_max = max(scale_max, int(scale_byte.max().item()))
        print(f"quantized rows {begin}:{end} / {n}", flush=True)

    packed_out.flush()
    scales_out.flush()
    metadata = {
        "source": str(shard),
        "tensor": "lm_head.weight",
        "shape_nk": [n, k],
        "packed_shape": [k // 2, n],
        "scale_shape": [k // 32, n],
        "scale_range": [scale_min, scale_max],
        "quantization_normalized_l2": math.sqrt(squared_error / squared_reference),
        "format": "OCP E2M1 values with one E8M0 power-of-two scale per K=32 block",
    }
    (args.output / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
