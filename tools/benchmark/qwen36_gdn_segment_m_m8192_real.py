#!/usr/bin/env python3
"""Real-checkpoint correctness and HIP-event gate for GDN segment M."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture", type=Path, required=True)
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=20)
    return parser.parse_args()


def metrics(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    a, e = actual.float(), expected.float()
    delta = (a - e).abs()
    cosine = torch.nn.functional.cosine_similarity(a.flatten(), e.flatten(), dim=0)
    return {
        "max_abs": float(delta.max()),
        "mean_abs": float(delta.mean()),
        "cosine": float(cosine),
        "over_0p125": int((delta > 0.125).sum()),
        "over_0p25": int((delta > 0.25).sum()),
        "bit_exact": bool(torch.equal(actual, expected)),
    }


def main() -> None:
    args = parse_args()
    if args.output.exists():
        raise FileExistsError(args.output)
    if args.iterations <= 0:
        raise ValueError("--iterations must be positive")

    device = torch.device("cuda", 0)
    arch = str(torch.cuda.get_device_properties(device).gcnArchName)
    if not arch.startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {arch}")

    saved = torch.load(args.capture, map_location="cpu", weights_only=True)
    k_grouped = saved["k_normalized"].to(device).contiguous()
    k = k_grouped.repeat_interleave(2, dim=2)[0]
    w = saved["w"].to(device)[0]
    u = saved["u"].to(device)[0]
    g = saved["g_cumsum"].to(device)[0]
    initial = saved["initial_state"].to(device)[0]
    captured_final = saved["final_state"].to(device)[0]
    del saved

    heads = 32
    dim = 128
    identity = torch.eye(dim, device=device).expand(heads, dim, dim)

    def chunk_inputs(chunk: int):
        token_slice = slice(chunk * 64, (chunk + 1) * 64)
        kc = k[token_slice].permute(1, 0, 2).float()
        wc = w[token_slice].permute(1, 0, 2).float()
        uc = u[token_slice].permute(1, 0, 2).float()
        gc = g[token_slice].permute(1, 0).float()
        decay = torch.exp(gc[:, -1])
        reverse_gate = torch.exp(gc[:, -1:] - gc)
        return kc, wc, uc, decay, reverse_gate

    def direct(state: torch.Tensor, start: int, end: int) -> torch.Tensor:
        for chunk in range(start, end):
            kc, wc, uc, decay, reverse_gate = chunk_inputs(chunk)
            v_new = uc - torch.bmm(wc, state.transpose(1, 2))
            state = decay[:, None, None] * state + torch.bmm(
                (reverse_gate[:, :, None] * v_new).transpose(1, 2), kc
            )
        return state

    def summary(start: int, end: int) -> tuple[torch.Tensor, torch.Tensor]:
        affine_h = torch.zeros((heads, dim, dim), device=device)
        transition = identity.clone()
        for chunk in range(start, end):
            kc, wc, uc, decay, reverse_gate = chunk_inputs(chunk)
            weighted_k = reverse_gate[:, :, None] * kc
            chunk_m = decay[:, None, None] * identity - torch.bmm(
                wc.transpose(1, 2), weighted_k
            )
            v_new = uc - torch.bmm(wc, affine_h.transpose(1, 2))
            affine_h = decay[:, None, None] * affine_h + torch.bmm(
                (reverse_gate[:, :, None] * v_new).transpose(1, 2), kc
            )
            transition = torch.bmm(transition, chunk_m)
        return affine_h, transition

    with torch.no_grad():
        direct_full = direct(initial.float(), 0, 128)
        full_h, full_m = summary(0, 128)
        affine_full = full_h + torch.bmm(initial.float(), full_m)
        summaries = [summary(start, start + 32) for start in range(0, 128, 32)]
        segmented = initial.float()
        for affine_h, transition in summaries:
            segmented = affine_h + torch.bmm(segmented, transition)

    stem = "qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950"
    bridge_path = args.build_dir / "libqwen36_gdn_segment_m_m8192_bridge.so"
    hsaco_path = args.build_dir / f"{stem}.hsaco"
    library = ctypes.CDLL(str(bridge_path))
    library.netra_qwen36_gdn_segment_m_m8192_load.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
    ]
    library.netra_qwen36_gdn_segment_m_m8192_load.restype = ctypes.c_int
    library.netra_qwen36_gdn_segment_m_m8192_launch.argtypes = [
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_uint32,
        ctypes.c_void_p,
    ]
    library.netra_qwen36_gdn_segment_m_m8192_launch.restype = ctypes.c_int
    library.netra_qwen36_gdn_segment_m_m8192_last_error.restype = ctypes.c_char_p
    status = library.netra_qwen36_gdn_segment_m_m8192_load(
        str(hsaco_path).encode(), stem.encode()
    )
    if status:
        raise RuntimeError(
            library.netra_qwen36_gdn_segment_m_m8192_last_error().decode()
        )

    raw_m = torch.empty(
        (4, heads, dim, dim), dtype=torch.bfloat16, device=device
    )

    def launch() -> None:
        stream = torch.cuda.current_stream(device)
        status = library.netra_qwen36_gdn_segment_m_m8192_launch(
            ctypes.c_void_p(k_grouped.data_ptr()),
            ctypes.c_void_p(w.data_ptr()),
            ctypes.c_void_p(g.data_ptr()),
            ctypes.c_void_p(raw_m.data_ptr()),
            32,
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                library.netra_qwen36_gdn_segment_m_m8192_last_error().decode()
            )

    launch()
    torch.cuda.synchronize(device)
    raw_m_reference = raw_m.clone()
    deterministic_replays = []
    for _ in range(5):
        launch()
        torch.cuda.synchronize(device)
        deterministic_replays.append(metrics(raw_m, raw_m_reference))
    raw_segmented = initial.float()
    for segment, (affine_h, _) in enumerate(summaries):
        raw_segmented = affine_h + torch.bmm(
            raw_segmented, raw_m_reference[segment].float()
        )

    for _ in range(5):
        launch()
    torch.cuda.synchronize(device)
    timings: list[float] = []
    for _ in range(args.iterations):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        launch()
        end.record()
        end.synchronize()
        timings.append(float(start.elapsed_time(end) * 1000.0))

    result = {
        "target": arch,
        "shape": {
            "B": 1,
            "T": 8192,
            "H": heads,
            "Hg": 16,
            "K": dim,
            "V": dim,
            "BT": 64,
            "segments": 4,
            "chunks_per_segment": 32,
        },
        "direct_vs_single_affine": metrics(direct_full, affine_full),
        "direct_vs_segmented_affine": metrics(direct_full, segmented),
        "raw_m_per_segment": [
            metrics(raw_m_reference[i], summaries[i][1].bfloat16()) for i in range(4)
        ],
        "raw_m_deterministic_replays": deterministic_replays,
        "raw_segmented_vs_direct": metrics(raw_segmented, direct_full),
        "raw_segmented_vs_captured_bf16": metrics(raw_segmented, captured_final),
        "raw_m_timing_us": {
            "count": len(timings),
            "minimum": min(timings),
            "median": statistics.median(timings),
            "mean": statistics.mean(timings),
            "maximum": max(timings),
        },
        "accepted": False,
        "decision": "transition_overhead_exceeds_available_full_path_budget",
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
