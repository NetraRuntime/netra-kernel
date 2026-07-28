# MXFP4 raw-ASM versus Triton on gfx1151

All results below are measured on the Ryzen AI Max+ PRO 395 (`gfx1151`) with
real Qwen3.6-35B-A3B-MXFP4 checkpoint weights. They are kernel timings, not
end-to-end token throughput.

## Baseline

The baseline is Triton 3.5.1 `matmul_ogs` at commit
`0add68262ab0a2e33b84524346cb27cbb2787356`, with the public RDNA manual
MXFP4 dequant path from `Capicua25x/vllm-rocm-rdna4` commit
`fdeb0eed441779e3009183e0b5dfa324b9c9540f`.

Stock Triton 3.5.1 `tl.dot_scaled` compiled and ran on gfx1151, but its output
on the real checkpoint was wrong (about 0.81 maximum absolute error and 1.44
normalized L2). That timing was rejected. The RDNA manual-dequant path passed
the fp64 subset check with normalized L2 from 3.14e-8 through 6.42e-8.

Both sides below were rerun with the same rocprofv3 build bundled with the
PyTorch 2.9.1+rocm7.13 environment. The system ROCm 7.2.1 profiler cannot
profile this newer Python runtime because its HSA ABI is incompatible. Each
figure is the mean of the final 30 kernel calls. Expert weights rotate over
more than 32 MiB (38.25 MiB raw ASM and 68 MiB Triton).

## Measured results

| Operation on gfx1151 | Shape | Raw ASM (us) | Tuned Triton (us) | Raw speedup |
|---|---:|---:|---:|---:|
| Decode gate/up | E8 M1 N512 K2048 | 82.459733 | 92.993567 | 1.1277x |
| Decode down | E8 M1 N2048 K512 | 45.078367 | 52.649100 | 1.1679x |
| Verify gate/up | E8 M12 N512 K2048 | 51.128533 | 113.267833 | 2.2154x |
| Verify down | E8 M12 N2048 K512 | 25.234333 | 59.920100 | 2.3745x |
| Prefill gate/up | G8 M64 N512 K2048 | 98.837300 | 128.743900 | 1.3026x |
| Prefill down | G8 M64 N2048 K512 | 85.319833 | 105.650800 | 1.2383x |
| MXFP4 LM head decode | M1 N248320 K2048 | 1197.229833 | 2082.831400 | 1.7397x |
| MXFP4 LM head verify | M12 N248320 K2048 | 1439.266600 | 2452.505733 | 1.7040x |

Qwen's expert MLP has two N512 projections (gate and up) and one down
projection. Summing those three kernels gives:

| Expert MLP path on gfx1151 | Raw ASM (us) | Tuned Triton (us) | Raw speedup | Latency reduction |
|---|---:|---:|---:|---:|
| Decode M1 | 209.997833 | 238.636234 | 1.1364x | 12.00% |
| Speculative verify M12 | 127.491399 | 286.455766 | 2.2469x | 55.49% |
| Grouped prefill M64 | 282.994433 | 363.138600 | 1.2832x | 22.07% |

The checkpoint's shipped LM head is BF16. The two LM-head rows above compare
the suite's separately quantized MXFP4 case only.

## Winning Triton configurations

All use split-K 1 and the RDNA manual-dequant path:

| Case | BLOCK_M | BLOCK_N | BLOCK_K |
|---|---:|---:|---:|
| gate M1 | 1 | 64 | 128 |
| down M1 | 1 | 64 | 64 |
| gate/down M12 | 16 | 64 | 32 |
| gate M64 | 64 | 64 | 64 |
| down M64 | 64 | 128 | 64 |
| LM M1 | 1 | 64 | 128 |
| LM M12 | 16 | 64 | 128 |

Negative tuning results are retained: several M1 BLOCK_M values from 2
through 8 hit a gfx1151 WMMA layout assertion, and the largest
BLOCK_N/BLOCK_K combinations either exhausted the 64 KiB LDS limit or
regressed sharply. None of those failed or incorrect configurations enter the
reported minima.
