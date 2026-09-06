# SPDX-License-Identifier: MIT
"""Isolated gfx950 correctness and graph timing; never a serving TPS claim."""
import argparse
import json
import math
import os
from pathlib import Path
import sys

import torch

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "runtime/gfx950/attention/indexer"))
from dsv4_mqa import Scorer, select_schedule
from aiter.ops.triton.attention.pa_mqa_logits import deepgemm_fp8_paged_mqa_logits


def packed(keys, scales):
    n = keys.shape[0]
    buf = torch.empty((n, 8448), dtype=torch.uint8, device="cuda")
    shuffled = keys.view(n, 4, 16, 8, 16).permute(0, 1, 3, 2, 4).contiguous()
    buf[:, :8192].copy_(shuffled.view(torch.uint8).reshape(n, 8192))
    buf[:, 8192:].copy_(scales.contiguous().view(torch.uint8).reshape(n, 256))
    return buf.view(n, 64, 1, 132)


def make(rows, width, seed, onehot=False, request_groups=1):
    torch.manual_seed(seed)
    n = math.ceil(width / 64)
    key_pages = n * request_groups + 3
    keys = torch.randn(key_pages, 64, 128, device="cuda").to(torch.float8_e4m3fn)
    q = torch.randn(rows, 1, 64, 128, device="cuda").to(torch.float8_e4m3fn)
    if onehot:
        q = torch.zeros(rows, 1, 64, 128, device="cuda")
        for r in range(rows):
            q[r, 0, torch.arange(64), (torch.arange(64) * 13 + r * 7) % 128] = 1
        q = q.to(torch.float8_e4m3fn)
    scales = torch.rand(key_pages, 64, device="cuda") * .1 + .01
    weights = torch.randn(rows, 64, device="cuda")
    if seed % 2:
        weights.abs_()
    pages = torch.stack([torch.randperm(n, device="cuda") +
                         (r * request_groups // rows) * n for r in range(rows)]).int()
    lengths = torch.full((rows,), width, device="cuda", dtype=torch.int32)
    if rows > 1:
        lengths[:min(rows, 7)] = torch.tensor([0, 1, 63, 64, 65, max(0, width-1), width][:min(rows, 7)], device="cuda", dtype=torch.int32).clamp_max(width)
        pages[0].fill_(-12345)  # zero-length rows must not touch the page table.
    kv = packed(keys, scales)
    out = torch.full((rows, width + 17), 123456., device="cuda")[:, :width]
    return q, kv, weights, lengths, pages, out, keys, scales


def oracle(q, weights, lengths, pages, keys, scales, width):
    result = torch.full((len(q), width), -torch.inf, device="cuda")
    for row in range(len(q)):
        length = int(lengths[row])
        if not length:
            continue
        kk = keys[pages[row].long()].double().reshape(-1, 128)[:length]
        ss = scales[pages[row].long()].double().reshape(-1)[:length]
        # FP64 oracle avoids library-dependent FP32 GEMM precision modes.
        dot = q[row, 0].double() @ kk.T
        result[row, :length] = ((dot * ss).relu() * weights[row, :, None].double()).sum(0)
    return result


def reference(t):
    q, kv, weights, lengths, pages, out = t[:6]
    # AITER writes complete trailing stage tiles. Its serving wrapper supplies
    # a padded width; do the same for synthetic odd widths (65, 257, ...).
    width = math.ceil(out.shape[1] / 256) * 256
    result = torch.full((len(q), width), -torch.inf, device="cuda")
    table = torch.zeros((len(q), width // 64), dtype=torch.int32, device="cuda")
    table[:, :pages.shape[1]].copy_(pages)
    deepgemm_fp8_paged_mqa_logits(q, kv, weights, result, lengths, table,
                                width, Preshuffle=True, KVBlockSize=64)
    result = result[:, :out.shape[1]]
    mask = torch.arange(out.shape[1], device="cuda")[None, :] < lengths[:, None]
    result.masked_fill_(~mask, -torch.inf)
    return result


def check(actual, expected, lengths, atol=3e-4, rtol=3e-5):
    mask = torch.arange(actual.shape[1], device="cuda")[None, :] < lengths[:, None]
    torch.testing.assert_close(actual[mask], expected[mask], atol=atol, rtol=rtol)
    assert torch.isneginf(actual[~mask]).all().item()
    topk_equal = True
    for r in range(len(actual)):
        k = min(512, int(lengths[r]))
        if k:
            aa = actual[r].topk(k).indices.sort().values
            bb = expected[r].topk(k).indices.sort().values
            topk_equal &= torch.equal(aa, bb)
    delta = (actual[mask] - expected[mask]).abs()
    return {"max_abs": delta.max().item() if delta.numel() else 0.,
            "top512_set_equal": topk_equal}


def graph_time(fn, repeats=20):
    for _ in range(3): fn()
    torch.cuda.synchronize()
    g = torch.cuda.CUDAGraph()
    with torch.cuda.graph(g):
        for _ in range(5): fn()
    for _ in range(3): g.replay()
    start, end = torch.cuda.Event(enable_timing=True), torch.cuda.Event(enable_timing=True)
    start.record()
    for _ in range(repeats): g.replay()
    end.record(); end.synchronize()
    return start.elapsed_time(end) * 1000 / (5 * repeats)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--build", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--smoke", action="store_true")
    parser.add_argument("--mode", type=int, choices=list(range(-1,14)), default=-1)
    parser.add_argument("--correctness-only", action="store_true")
    parser.add_argument("--skip-native-topk", action="store_true", help="Skip production SGLang exact-topK integration check")
    args = parser.parse_args()
    torch.backends.cuda.matmul.allow_tf32 = False
    scorer = Scorer(args.build, mode=None if args.mode == -1 else args.mode)
    native_topk = None
    if not args.smoke and not args.skip_native_topk:
        os.environ["NETRA_DSV4_EXACT_TOPK"] = "1"
        from sglang.jit_kernel.dsv4.topk import plan_topk_v2, topk_transform_512_v2
        native_topk = (plan_topk_v2, topk_transform_512_v2)
    report = {"state": "running", "device": torch.cuda.get_device_name(), "cases": [], "timings": [], "mode": args.mode}
    def save(): Path(args.output).write_text(json.dumps(report, indent=2) + "\n")
    save()
    try:
        shapes = [(1, 64), (8, 65), (9, 257), (8, 4096)]
        if not args.smoke: shapes += [(16, 32768), (8, 262144), (1024, 4096), (256, 257), (16, 32769), (2, 4096), (4, 4096), (16, 4096), (24, 4096), (32, 4096), (64, 4096), (128, 4096), (256, 4096), (1, 16384), (128, 1024), (128, 16384), (512, 4096), (8, 65536)]
        for i, (rows, width) in enumerate(shapes):
            t = make(rows, width, 30+i, onehot=i<2)
            scorer(*t[:6]); torch.cuda.synchronize()
            ref = reference(t)
            case = {"rows": rows, "width": width, "gluon": check(t[5], ref, t[3]), "auto_schedule": select_schedule(rows, width)}
            if rows <= 16:
                high_precision = oracle(t[0],t[2],t[3],t[4],t[6],t[7],width)
                # The native MFMA path (including Gluon) has a small arithmetic
                # difference from the FP64 mathematical oracle. Record both;
                # candidate-vs-Gluon uses the tighter tolerance above.
                case["gluon_vs_oracle"] = check(ref,high_precision,t[3],atol=1e-3,rtol=1e-4)
                case["oracle"] = check(t[5],high_precision,t[3],atol=1e-3,rtol=1e-4)
                assert case["oracle"]["max_abs"] <= case["gluon_vs_oracle"]["max_abs"] + 3e-5
            if native_topk:
                plan, select = native_topk
                metadata = plan(t[3])
                actual_idx = torch.empty((rows,512), dtype=torch.int32, device="cuda")
                expected_idx = torch.empty_like(actual_idx)
                # The production exact selector requires a 16-byte row stride.
                # Force a new padded allocation, including for a singleton row
                # whose .contiguous() can retain an arbitrary leading stride.
                aligned_a = torch.full((rows,math.ceil(width/4)*4),-torch.inf,device="cuda")
                aligned_b = torch.empty_like(aligned_a)
                aligned_a[:,:width].copy_(t[5]); aligned_b.copy_(aligned_a)
                aligned_b[:,:width].copy_(ref)
                select(aligned_a,t[3],t[4],actual_idx,64,metadata)
                select(aligned_b,t[3],t[4],expected_idx,64,metadata)
                assert torch.equal(actual_idx.sort().values,expected_idx.sort().values)
                case["native_exact_top512_page_set_equal"] = True
            # Verify row-padding canaries are intact.
            full = t[5].as_strided((rows, width+17), (width+17, 1))
            assert (full[:, width:] == 123456).all().item()
            assert case["gluon"]["top512_set_equal"], case
            report["cases"].append(case); save()
            print(json.dumps(case), flush=True)
        # Capture and replay with changing query, length and page contents.
        t = make(8, 257, 50)
        g = torch.cuda.CUDAGraph()
        with torch.cuda.graph(g): scorer(*t[:6])
        for seed in range(3):
            replacement = make(8, 257, seed+100)
            for dest, src in zip(t[:5], replacement[:5]): dest.copy_(src)
            g.replay()
            assert check(t[5], reference(t), t[3])["top512_set_equal"]
        torch.cuda.synchronize()
        report["changed_graph_replays"] = 3; save()
        # Independent in-flight requests share a module, never mutable buffers.
        requests = [make(8, 4096, 60+i) for i in range(2)]
        streams = [torch.cuda.Stream() for _ in requests]
        for stream in streams: stream.wait_stream(torch.cuda.current_stream())
        for stream, request in zip(streams, requests):
            with torch.cuda.stream(stream):
                for _ in range(5): scorer(*request[:6])
        for stream in streams: stream.synchronize()
        for request in requests:
            assert check(request[5], reference(request), request[3])["top512_set_equal"]
        report["concurrent_streams"] = 2; save()
        # Independently padded Q, weights and page-table rows.
        t = make(8, 4096, 63)
        qpad = torch.empty((8,1,65,128),dtype=t[0].dtype,device="cuda")[:,:,:64,:]
        wpad = torch.empty((8,68),device="cuda")[:,:64]
        ppad = torch.empty((8,t[4].shape[1]+4),dtype=torch.int32,device="cuda")[:,:t[4].shape[1]]
        for dst, src in [(qpad,t[0]),(wpad,t[2]),(ppad,t[4])]: dst.copy_(src)
        scorer(qpad,t[1],wpad,t[3],ppad,t[5])
        assert check(t[5],reference(t),t[3])["top512_set_equal"]
        report["padded_input_rows"] = True; save()
        if not args.smoke:
            # Output rows straddle 2/4 GiB; only 3x64 actual stores.
            t = make(3, 64, 80)
            stride = 536870976
            storage = torch.empty(2*stride+64, device="cuda")
            wide = storage.as_strided((3, 64), (stride, 1))
            scorer(*t[:5], wide)
            assert check(wide, reference(t), t[3])["top512_set_equal"]
            del wide, storage
            # Physical KV page starts beyond 4 GiB. Only initialized active pages read.
            t = make(1, 64, 82)
            page = (1 << 32) // 8448 + 1
            pool = torch.empty((page+1,64,1,132), dtype=torch.uint8, device="cuda")
            expected = reference(t)
            pool[page].copy_(t[1][int(t[4][0,0])]); t[4].fill_(page)
            scorer(t[0],pool,t[2],t[3],t[4],t[5]); torch.cuda.synchronize()
            check(t[5],expected,t[3]); del pool
            report["wide_address_tests"] = ["output_rows_above_2_and_4_GiB", "KV_page_above_4_GiB"]
            save()
            for rows, width in ([] if args.correctness_only else [(1,4096),(8,4096),(128,4096),(1024,4096),(8,262144),(128,32768),(1024,262144)]):
                groups = max(1, rows // 8)
                t = make(rows,width,90,request_groups=groups)
                t[3].fill_(width); t[4][0].copy_(t[4][-1] if rows>1 else t[4][0])
                if t[1].numel() * t[1].element_size() > (1 << 31):
                    report["timings"].append({"rows": rows, "width": width,
                        "skipped": "Full-pool Gluon has 32-bit KV buffer offsets; use sweep_small.py for the rebased-reference assembly comparison"})
                    save()
                    continue
                base = torch.empty_like(t[5])
                a = lambda: scorer(*t[:6])
                b = lambda: deepgemm_fp8_paged_mqa_logits(*t[:3],base,t[3],t[4],width,Preshuffle=True,KVBlockSize=64)
                # Alternate timing order to reduce systematic warmup/clock bias.
                times = []
                for order in range(3):
                    if order % 2: gu, au = graph_time(b), graph_time(a)
                    else: au, gu = graph_time(a), graph_time(b)
                    times.append({"asm_us":au,"gluon_us":gu,"speedup":gu/au})
                item = {"rows":rows,"width":width,"request_groups":groups,
                        "kv_bytes":t[1].numel(),"rounds":times}
                report["timings"].append(item); save(); print(json.dumps(item),flush=True)
        torch.cuda.synchronize()
        del g
        scorer.close(); scorer.close()
        report["explicit_module_close"] = True
        report["state"] = "passed"
    except BaseException as e:
        report["state"] = "failed"; report["error"] = repr(e); raise
    finally:
        save()
    print(json.dumps(report,indent=2),flush=True)


if __name__ == "__main__": main()
