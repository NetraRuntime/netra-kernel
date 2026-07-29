# gfx1151 graph and piecewise-graph report (2026-07-29)

Every numeric result in this report is measured on gfx1151 unless explicitly marked pending or unavailable. Serving time uses the host monotonic clock; graph construction comes from SGLang's server log. dFlash is disabled throughout because the supplied environment has no compatible draft checkpoint.

## Full batch-1 decode graph

The graph-safe raw-ASM bridge loads all HSACO modules and allocates persistent per-layer MoE decode workspaces during model weight processing. Capture therefore has stable device pointers and performs no module load or persistent workspace allocation.

| Capture property | gfx1151 result | Status |
|---|---:|---|
| Decode tiers | batch 1 / M=1 | measured |
| Construction time | 2.06 s | measured |
| Graph memory | 0.10 GiB | measured |
| Prefill graph | disabled | measured configuration |
| dFlash | disabled | measured configuration |

SGLang logged `cuda graph: True` for decode replay and `cuda graph: False` for each prefill/chunk. All measured requests below report zero cached tokens.

| Scenario | Exact input/output | TTFT ms | Decode ms | E2E ms | Input tok/s | Output tok/s | Peak VRAM GiB | Status |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Short prefill | 16 / 1 | 371.836 | 0.062 | 371.898 | 43.030 | n/a | 57.99 | measured |
| Exact 210 | 210 / 1 | 410.012 | 0.171 | 410.183 | 512.180 | n/a | 58.32 | measured |
| Prefill chunk | 8,192 / 1 | 7,168.135 | 0.129 | 7,168.264 | 1,142.836 | n/a | 62.32 | measured |
| Long prefill | 32,768 / 1 | 34,911.877 | 0.092 | 34,911.969 | 938.592 | n/a | 62.32 | measured |
| Decode | 1 / 32 | 86.480 | 1,859.381 | 1,945.860 | 11.563 | 16.672 | 62.32 | measured |
| Serving | 210 / 128 | 389.324 | 7,641.140 | 8,030.464 | 539.397 | 16.621 | 62.32 | measured |

Three uncached repeats establish the unprofiled graph variance:

| Scenario | E2E samples ms | Median ms | Median TTFT ms | Median output tok/s | Status |
|---|---|---:|---:|---:|---|
| 210 / 1 | 393.496, 401.180, 389.918 | 393.496 | 393.423 | n/a | measured |
| 1 / 32 | 1,943.403, 1,944.784, 1,947.595 | 1,944.784 | 87.786 | 16.678 | measured |
| 210 / 128 | 8,032.045, 8,033.376, 8,036.383 | 8,033.376 | 395.733 | 16.624 | measured |

## Accepted QKVZ+BA raw-ASM graph integration

The M=1 GDN path concatenates each layer's QKVZ and BA MXFP4 tensors at load
time, pads N=12,352 to N=12,800, and performs one launch of the existing raw
gfx1151 AMDGCN decode kernel. Prefill retains two exact-shape dispatches.
Real-checkpoint layer output is bit-exact to the two-dispatch raw-ASM path.

| Scenario | Original median ms | Fused samples ms | Fused median ms | Speedup | Output tok/s | Status |
|---|---:|---|---:|---:|---:|---|
| 1 / 32 | 1,944.784 | 1,802.571, 1,797.770, 1,800.900 | 1,800.900 | 1.0799x | 18.030 | gfx1151 measured |
| 210 / 128 | 8,033.376 | 7,448.737, 7,455.958, 7,466.136 | 7,455.958 | 1.0774x | 17.978 | gfx1151 measured |

The fused server constructed its batch-1 decode graph in 1.55 seconds and used
0.10 GiB of graph memory, both measured on gfx1151. Construction time is not
claimed as an optimization because module and page-cache state were not
matched. The fixed 1/+32 output hash matches the pre-fusion graph. Long
128-token generations were not hash-stable even across two pre-fusion server
epochs, so layer bit-exactness and the stable 1/+32 sequence are the numerical
acceptance gates.

After moving the fused output workspace to load-time storage, a final graph
replay captured in 1.56 seconds with 0.10 GiB graph memory. Stable hashes still
matched; 1/+32 measured 1,799.200 ms and 210/+128 measured 7,443.251 ms on
gfx1151. No fused compute allocation now occurs during capture or replay.

The historical exact-210 post-M64 baseline is 447.245 ms median with graph disabled. The 393.496 ms graph median is 1.137x faster, but seeds and run epoch are not matched, so this comparison is explicitly uncontrolled and is not an optimization acceptance gate.

## Graph profiling failure

A delayed launch-from-start rocprofv3 run completed the same six uncached graph requests. The profiler did not finalize CSV output when the collection period ended. On termination, SGLang's inherited Python `multiprocessing.resource_tracker` entered rocprofv3's abort-handler recursively and repeated signal 6. The exact orphan was killed; useful server logs and all request JSONs were retained. Two raw unflushed buffers (108,527,832-byte HIP API and 62,914,680-byte kernel trace) are preserved under the run's `raw-unflushed/` directory.

This is a profiler failure, not GPU evidence. No kernel time, launch-gap reduction, or graph speedup is inferred from the unflushed buffers.

A separate short-lived QKVZ+BA trace revealed that rocprofv3's default RocPD
writer aborts when it encounters an empty SQL name, then recursively handles
its own signal 6. Forcing `--output-format csv` bypassed that writer and
finalized normally. The valid CSV trace measured separate raw-ASM kernel
medians of 100.351 + 84.922 us versus 101.114 us fused on gfx1151 (1.8323x).
The failed SQLite database is retained only as tool-failure evidence.

## Native piecewise graph status

At pinned SGLang commit `1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4`, `tc_piecewise` is the native torch.compile-driven prefill backend. It FX-splits at attention layers, keeps attention metadata outside captured pieces, uses stable graph pools, and caches concrete token tiers. The implementation contains an explicit HIP single-trace warmup path, but `ServerArgs._disable_tc_piecewise_cudagraph_if_incompatible` currently disables the backend whenever `is_hip()` is true.

Consequently, piecewise construction time, replay overhead, memory, graph-break count, and serving improvement are pending. The next gate is a guarded removal of only the HIP compatibility rule followed by a 64-token tier correctness/capture test; broader 128/256/1,024/2,048/4,096/8,192 tiers must not be prebuilt until that test passes.

## Correctness and optimization gates

- Graph replay has completed on the real checkpoint with the raw gfx1151 ASM modules and persistent workspaces.
- The accepted QKVZ+BA M=1 fusion is bit-exact at the layer boundary, matches the fixed 1/+32 full-model output hash, and improves both repeated serving cases end to end.
- Matched-seed eager versus graph output hashes outside the accepted fusion cases remain pending; empty one-token decoded strings are not treated as sufficient correctness evidence.
- dFlash graph modes remain unavailable until a compatible draft checkpoint and its `dflash_config` are supplied.
