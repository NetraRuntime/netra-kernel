#!/usr/bin/env python3
"""Real-checkpoint correctness/timing gate for the gfx950 Qwen GDN h kernel."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-pass", type=Path, required=True)
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--hsaco", type=Path)
    parser.add_argument(
        "--kernel-name",
        default="qwen36_gdn_h_m8192_bv16_gfx950",
    )
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def compare(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    mismatch = actual != expected
    delta = (actual.float() - expected.float()).abs()
    return {
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int(mismatch.sum().item()),
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "mean_abs": float(delta.mean().item()),
    }


def distribution(values: list[float]) -> dict[str, float | int]:
    ordered = sorted(values)
    return {
        "count": len(ordered),
        "mean_us": statistics.mean(ordered),
        "median_us": statistics.median(ordered),
        "p90_us": ordered[min(len(ordered) - 1, (9 * len(ordered) + 9) // 10 - 1)],
        "minimum_us": ordered[0],
        "maximum_us": ordered[-1],
    }


def main() -> None:
    args = parse_args()
    if args.iterations <= 0:
        raise ValueError("--iterations must be positive")
    if args.output.exists():
        raise FileExistsError(args.output)
    device = torch.device("cuda", 0)
    architecture = torch.cuda.get_device_properties(device).gcnArchName
    if not str(architecture).startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    payload = torch.load(args.state_pass, map_location="cpu", weights_only=True)
    expected_shapes = {
        "k_normalized": (1, 8192, 16, 128),
        "w": (1, 8192, 32, 128),
        "u": (1, 8192, 32, 128),
        "g_cumsum": (1, 8192, 32),
        "initial_state": (1, 32, 128, 128),
        "cu_seqlens": (2,),
        "chunk_indices": (128, 2),
        "h": (1, 128, 32, 128, 128),
        "v_new": (1, 8192, 32, 128),
        "final_state": (1, 32, 128, 128),
    }
    for key, shape in expected_shapes.items():
        value = payload.get(key)
        if not isinstance(value, torch.Tensor) or tuple(value.shape) != shape:
            raise ValueError(f"unexpected {key}: {getattr(value, 'shape', None)}")

    def gpu(key: str) -> torch.Tensor:
        return payload[key].contiguous().to(device=device)

    k = gpu("k_normalized")
    v = gpu("u")
    w = gpu("w")
    g = gpu("g_cumsum")
    initial_state = gpu("initial_state")
    initial_indices = gpu("initial_state_indices")
    cu_seqlens = gpu("cu_seqlens")
    # FLA passes the contiguous [batch_id, chunk_id] int32 pairs as the
    # kernel's packed int64 chunk-offset view.
    chunk_offsets = gpu("chunk_indices").view(torch.int64)
    expected_h = gpu("h")
    expected_v_new = gpu("v_new")
    expected_state = gpu("final_state")
    del payload

    actual_h = torch.empty_like(expected_h)
    actual_v_new = torch.empty_like(expected_v_new)
    actual_state = initial_state.clone()

    bridge_path = args.build_dir / "libqwen36_gdn_h_m8192_bv16_bridge.so"
    bridge = ctypes.CDLL(str(bridge_path))
    bridge.netra_qwen36_gdn_h_m8192_bv16_load.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
    ]
    bridge.netra_qwen36_gdn_h_m8192_bv16_load.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_h_m8192_bv16_launch.argtypes = [
        *([ctypes.c_void_p] * 10),
        ctypes.c_void_p,
    ]
    bridge.netra_qwen36_gdn_h_m8192_bv16_launch.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_h_m8192_bv16_last_error.restype = ctypes.c_char_p

    hsaco = args.hsaco
    if hsaco is None:
        matches = sorted(args.build_dir.glob("*.hsaco"))
        if len(matches) != 1:
            raise ValueError(f"expected one hsaco in {args.build_dir}, got {matches}")
        hsaco = matches[0]
    status = bridge.netra_qwen36_gdn_h_m8192_bv16_load(
        str(hsaco).encode(), args.kernel_name.encode()
    )
    if status:
        raise RuntimeError(
            bridge.netra_qwen36_gdn_h_m8192_bv16_last_error().decode()
        )

    def run() -> None:
        stream = torch.cuda.current_stream(device)
        status = bridge.netra_qwen36_gdn_h_m8192_bv16_launch(
            pointer(k),
            pointer(v),
            pointer(w),
            pointer(actual_v_new),
            pointer(g),
            pointer(actual_h),
            pointer(actual_state),
            pointer(initial_indices),
            pointer(cu_seqlens),
            pointer(chunk_offsets),
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_h_m8192_bv16_last_error().decode()
            )

    actual_state.copy_(initial_state)
    run()
    torch.cuda.synchronize(device)
    correctness = {
        "h": compare(actual_h, expected_h),
        "v_new": compare(actual_v_new, expected_v_new),
        "final_state": compare(actual_state, expected_state),
    }
    bit_exact = all(bool(value["bit_exact"]) for value in correctness.values())

    for _ in range(10):
        actual_state.copy_(initial_state)
        run()
    torch.cuda.synchronize(device)
    elapsed: list[float] = []
    for _ in range(args.iterations):
        actual_state.copy_(initial_state)
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        run()
        end.record()
        end.synchronize()
        elapsed.append(float(start.elapsed_time(end) * 1000.0))

    result = {
        "target": str(architecture),
        "shape": {
            "B": 1,
            "T": 8192,
            "H": 32,
            "Hg": 16,
            "K": 128,
            "V": 128,
            "BT": 64,
            "BV": 16,
        },
        "grid": [8, 32, 1],
        "block": [256, 1, 1],
        "dynamic_lds_bytes": 103296,
        "kernel_name": args.kernel_name,
        "hsaco": str(hsaco),
        "correctness": correctness,
        "bit_exact": bit_exact,
        "timing": distribution(elapsed),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    if not bit_exact:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
