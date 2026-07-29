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

## Native piecewise graph result

At pinned SGLang commit `1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4`,
`tc_piecewise` is the native torch.compile-driven prefill backend. It FX-splits
at attention layers, keeps attention metadata outside captured pieces, uses
stable graph pools, and caches concrete token tiers. An explicitly selected
prefill backend is locked before SGLang's automatic HIP compatibility cascade,
so the native CLI is sufficient; no removal of the general HIP rule is needed.

The first capture exposed two real graph breaks in the model integration:
the expert-distribution recorder context was entered inside the compiled layer
loop, and routed-MoE group construction called `.item()` on a device tensor.
The bridge now presents the raw gfx1151 AMDGCN prefill launch as an SGLang
custom-op boundary. During piecewise prefill, the recorder context is omitted
and routed-MoE uses a fixed group capacity
`E + floor((P - E) / 64)` for `P > E`, otherwise `P`. This is the exact maximum
of `sum(ceil(tokens_per_expert / 64))`, so no routed group can exceed the
preallocated workspace. It removes the CPU/GPU synchronization and keeps all
raw compute in the existing gfx1151 `.s` kernels.

The later raw QKVZ/BA split-copy capture exposed two additional direct-ctypes
boundaries in the M=1 fused QKVZ+BA projection and general M=1 linear path.
Both now use registered custom ops. The final gfx1151 M64 capture completed in
12.06 s using 0.28 GB and replay matched eager output; the compute remains raw
AMDGCN and module loading occurs before capture.

All serving rows below are host-monotonic, uncached, exact-input/+1-output
measurements on gfx1151. Each median has three matched-seed eager and piecewise
runs except M64, which has five. Every matched pair has identical input-ID and
output-text SHA-256 hashes.

| Tier | Eager median ms | Piecewise median ms | Eager / piecewise | Decision | Status |
|---:|---:|---:|---:|---|---|
| M64 | 478.170 | 484.441 | 0.9871x | reject: 1.31% regression | gfx1151 measured |
| M128 | 503.539 | 501.853 | 1.0034x | neutral/noise | gfx1151 measured |
| M256 | 561.034 | 556.982 | 1.0073x | neutral/noise | gfx1151 measured |
| M1,024 | 964.782 | 958.983 | 1.0060x | neutral/noise | gfx1151 measured |
| M2,048 | 1,695.754 | 1,697.762 | 0.9988x | neutral/noise | gfx1151 measured |
| M4,096 | 3,415.790 | 3,412.113 | 1.0011x | neutral/noise | gfx1151 measured |
| M8,192 | 7,151.251 | 7,137.229 | 1.0020x | neutral/noise | gfx1151 measured |

The isolated M64 graph captured in 12.46 seconds and used 0.28 GB. Capturing
M64/M128/M256 together took 29.14 seconds and 0.40 GB. Capturing
M1,024/M2,048/M4,096/M8,192 together took 53.80 seconds and 0.52 GB. These are
SGLang log measurements on gfx1151. The end-to-end deltas are host serving
measurements, not GPU-duration claims; no speedup is accepted because all
positive medians are below one percent and the construction/memory cost is
material. Piecewise capture remains available as a correctness-proven
integration path, but it is not the default performance path.

## Correctness and optimization gates

- Graph replay has completed on the real checkpoint with the raw gfx1151 ASM modules and persistent workspaces.
- The accepted QKVZ+BA M=1 fusion is bit-exact at the layer boundary, matches the fixed 1/+32 full-model output hash, and improves both repeated serving cases end to end.
- Piecewise M64 through M8,192 matched eager input IDs and output hashes for every measured seed. Several seeds emitted non-empty text, so correctness does not rely on empty one-token decodes.
- Native piecewise replay is rejected as a speed optimization on the measured tiers; its best median delta is below one percent.
- dFlash graph modes remain unavailable until a compatible draft checkpoint and its `dflash_config` are supplied.
