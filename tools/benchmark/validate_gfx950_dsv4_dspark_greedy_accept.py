#!/usr/bin/env python3
"""Validate and time the raw gfx950 DeepSeek-V4 DSpARK greedy accept epilogue."""

from __future__ import annotations

import argparse
import ctypes
import json
from pathlib import Path

import torch


class Bridge:
    def __init__(self, library: Path, hsaco: Path) -> None:
        self.library = ctypes.CDLL(str(library))
        self.library.netra_dsv4_dspark_greedy_accept_load.argtypes = [ctypes.c_char_p]
        self.library.netra_dsv4_dspark_greedy_accept_load.restype = ctypes.c_int
        self.library.netra_dsv4_dspark_greedy_accept_launch.argtypes = [
            *([ctypes.c_void_p] * 12),
            ctypes.c_uint32,
            ctypes.c_void_p,
        ]
        self.library.netra_dsv4_dspark_greedy_accept_launch.restype = ctypes.c_int
        self.library.netra_dsv4_dspark_greedy_accept_last_error.argtypes = []
        self.library.netra_dsv4_dspark_greedy_accept_last_error.restype = ctypes.c_char_p
        self.check(
            self.library.netra_dsv4_dspark_greedy_accept_load(str(hsaco).encode()),
            "load",
        )

    def check(self, status: int, operation: str) -> None:
        if status == 0:
            return
        raw = self.library.netra_dsv4_dspark_greedy_accept_last_error()
        detail = raw.decode() if raw else f"status={status}"
        raise RuntimeError(f"{operation}: {detail}")

    def launch(self, outputs: tuple[torch.Tensor, ...], inputs: tuple[torch.Tensor, ...]) -> None:
        stream = torch.cuda.current_stream(inputs[0].device)
        self.check(
            self.library.netra_dsv4_dspark_greedy_accept_launch(
                *(ctypes.c_void_p(t.data_ptr()) for t in (*outputs, *inputs)),
                ctypes.c_uint32(inputs[0].shape[0]),
                ctypes.c_void_p(stream.cuda_stream),
            ),
            "launch",
        )


def reference(
    draft: torch.Tensor,
    target: torch.Tensor,
    verify_lens: torch.Tensor,
    prefix_lens: torch.Tensor,
    req_slots: torch.Tensor,
) -> tuple[torch.Tensor, ...]:
    matches = draft == target[:, :5]
    raw_correct = matches.to(torch.int32).cumprod(dim=1).sum(dim=1)
    ell = (verify_lens - 1).to(raw_correct.dtype)
    correct = torch.minimum(raw_correct, ell)
    trim = raw_correct - correct
    bonus = target.gather(1, correct.to(torch.int64)[:, None]).view(-1)
    commit = correct + 1
    new_seq = prefix_lens + commit.to(torch.int64)
    out = torch.empty((draft.shape[0], 6), dtype=torch.int64, device=draft.device)
    out[:, :5].copy_(draft)
    out[:, 5].zero_()
    out.scatter_(1, correct.to(torch.int64)[:, None], bonus[:, None])
    col = torch.arange(6, dtype=torch.int64, device=draft.device).view(1, -1)
    swa_loc = req_slots.view(-1, 1) * 133 + (prefix_lens.view(-1, 1) + col) % 133
    swa_loc = torch.where(
        col < commit.to(torch.int64).view(-1, 1), swa_loc, -1
    ).to(torch.int32)
    return (
        correct.to(torch.int64),
        bonus.to(torch.int64),
        trim.to(torch.int32),
        commit.to(torch.int32),
        new_seq.to(torch.int64),
        out,
        swa_loc,
    )


def allocate_outputs(batch: int, device: torch.device) -> tuple[torch.Tensor, ...]:
    return (
        torch.empty(batch, dtype=torch.int64, device=device),
        torch.empty(batch, dtype=torch.int64, device=device),
        torch.empty(batch, dtype=torch.int32, device=device),
        torch.empty(batch, dtype=torch.int32, device=device),
        torch.empty(batch, dtype=torch.int64, device=device),
        torch.empty((batch, 6), dtype=torch.int64, device=device),
        torch.empty((batch, 6), dtype=torch.int32, device=device),
    )


def make_case(batch: int, seed: int, device: torch.device) -> tuple[torch.Tensor, ...]:
    generator = torch.Generator(device=device).manual_seed(2026082800 + batch * 31 + seed)
    target = torch.randint(0, 129280, (batch, 6), dtype=torch.int64, device=device, generator=generator)
    draft = torch.randint(0, 129280, (batch, 5), dtype=torch.int64, device=device, generator=generator)
    wanted = (torch.arange(batch, device=device) + seed) % 6
    for col in range(5):
        mask = wanted > col
        draft[:, col] = torch.where(mask, target[:, col], draft[:, col])
        # Guarantee the first rejected token is unequal even under a random collision.
        reject = wanted == col
        draft[:, col] = torch.where(reject, (target[:, col] + 1) % 129280, draft[:, col])
    verify_lens = ((torch.arange(batch, device=device) * 5 + seed) % 6 + 1).to(torch.int64)
    prefix_lens = torch.randint(0, 65530, (batch,), dtype=torch.int64, device=device, generator=generator)
    req_slots = torch.randint(0, 257, (batch,), dtype=torch.int64, device=device, generator=generator)
    return draft, target, verify_lens, prefix_lens, req_slots


def elapsed_us(fn, iterations: int) -> float:
    begin = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)
    begin.record()
    for _ in range(iterations):
        fn()
    end.record()
    end.synchronize()
    return begin.elapsed_time(end) * 1000.0 / iterations


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bridge", required=True, type=Path)
    parser.add_argument("--hsaco", required=True, type=Path)
    parser.add_argument("--seeds", type=int, default=16)
    parser.add_argument("--iterations", type=int, default=2000)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    if not torch.cuda.is_available():
        raise SystemExit("HIP device is unavailable")
    target_name = torch.cuda.get_device_properties(0).gcnArchName
    if "gfx950" not in target_name:
        raise SystemExit(f"requires gfx950, got {target_name}")
    device = torch.device("cuda:0")
    bridge = Bridge(args.bridge.resolve(), args.hsaco.resolve())

    failures: list[dict[str, object]] = []
    case_count = 0
    for batch in (1, 2, 5, 16, 32, 64, 128, 256):
        for seed in range(args.seeds):
            inputs = make_case(batch, seed, device)
            outputs = allocate_outputs(batch, device)
            expected = reference(*inputs)
            bridge.launch(outputs, inputs)
            torch.cuda.synchronize()
            mismatched = [i for i, (got, want) in enumerate(zip(outputs, expected)) if not torch.equal(got, want)]
            if mismatched:
                failures.append({"batch": batch, "seed": seed, "outputs": mismatched})
            case_count += 1

    timings = []
    for batch in (1, 16, 32, 64, 128, 256):
        inputs = make_case(batch, 99, device)
        outputs = allocate_outputs(batch, device)

        def baseline() -> None:
            values = reference(*inputs)
            for dst, src in zip(outputs, values):
                dst.copy_(src)

        for _ in range(20):
            bridge.launch(outputs, inputs)
            baseline()
        torch.cuda.synchronize()
        raw_us = elapsed_us(lambda: bridge.launch(outputs, inputs), args.iterations)
        baseline_us = elapsed_us(baseline, args.iterations)
        bridge.launch(outputs, inputs)
        torch.cuda.synchronize()
        exact = all(torch.equal(got, want) for got, want in zip(outputs, reference(*inputs)))
        timings.append(
            {
                "batch": batch,
                "raw_mean_us": raw_us,
                "baseline_mean_us": baseline_us,
                "speedup": baseline_us / raw_us,
                "exact": exact,
            }
        )

    passed = not failures and all(bool(t["exact"]) for t in timings)
    rendered = json.dumps(
        {
            "target": target_name,
            "geometry": {
                "block_size": 5,
                "verify_width": 6,
                "swa_window": 128,
                "swa_ring": 133,
            },
            "case_count": case_count,
            "failed_case_count": len(failures),
            "iterations": args.iterations,
            "timings": timings,
            "failures": failures,
            "pass": passed,
        },
        indent=2,
        sort_keys=True,
    )
    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered + "\n")
    print(rendered)
    if not passed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
