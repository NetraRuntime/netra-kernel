#!/usr/bin/env python3
"""Repack eight real checkpoint experts for the raw gfx1151 harness."""

import argparse
import json
import struct
from pathlib import Path

import torch


def tensor_bytes(model: Path, key: str) -> tuple[bytearray, list[int]]:
    index = json.loads((model / "model.safetensors.index.json").read_text())
    shard = model / index["weight_map"][key]
    with shard.open("rb") as f:
        header_len = struct.unpack("<Q", f.read(8))[0]
        header = json.loads(f.read(header_len))
        meta = header[key]
        begin, end = meta["data_offsets"]
        f.seek(8 + header_len + begin)
        return bytearray(f.read(end - begin)), meta["shape"]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("model", type=Path)
    ap.add_argument("output", type=Path)
    ap.add_argument("--layer", type=int, default=0)
    ap.add_argument("--expert-count", type=int, default=8)
    ap.add_argument(
        "--projection", choices=("gate", "up", "down"), default="gate"
    )
    args = ap.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    packed, scales = [], []
    if args.projection == "down":
        packed_shape, scale_shape = [2048, 256], [2048, 16]
    else:
        packed_shape, scale_shape = [512, 1024], [512, 64]
    root = f"model.language_model.layers.{args.layer}.mlp.experts"
    for expert in range(args.expert_count):
        raw, shape = tensor_bytes(
            args.model, f"{root}.{expert}.{args.projection}_proj.weight_packed"
        )
        assert shape == packed_shape
        packed.append(
            torch.frombuffer(raw, dtype=torch.uint8)
            .reshape(*packed_shape)
            .t()
            .contiguous()
        )
        raw, shape = tensor_bytes(
            args.model, f"{root}.{expert}.{args.projection}_proj.weight_scale"
        )
        assert shape == scale_shape
        scales.append(
            torch.frombuffer(raw, dtype=torch.uint8)
            .reshape(*scale_shape)
            .t()
            .contiguous()
        )

    p = torch.stack(packed)
    s = torch.stack(scales)
    stem = f"{args.projection}{args.expert_count}"
    (args.output / f"{stem}_packed_kmajor.bin").write_bytes(p.numpy().tobytes())
    (args.output / f"{stem}_scales_kmajor.bin").write_bytes(s.numpy().tobytes())
    print(
        f"wrote real layer {args.layer} {args.projection} "
        f"for {args.expert_count} experts: "
        f"packed={tuple(p.shape)} "
        f"scales={tuple(s.shape)} scale_range=[{s.min().item()},{s.max().item()}]"
    )


if __name__ == "__main__":
    main()
