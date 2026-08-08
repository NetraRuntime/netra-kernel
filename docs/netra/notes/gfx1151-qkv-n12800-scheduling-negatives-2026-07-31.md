# gfx1151 QKV row reuse and N=12800 scheduling negatives — 2026-07-31

Status: **rejected, measured on gfx1151**. Model: Qwen3.6-35B-A3B with checkpoint-native MXFP4 weights and model-native BF16 QKV. All GPU timings use HIP events on AMD Ryzen AI Max+ PRO 395. No alternate quantization was tested and no production kernel was changed.

## BF16 QKV wide-load row reuse

The accepted M=1, N=9216, K=2048 QKV kernel assigns one output row per wave and uses 128-bit activation/weight loads. Two raw-ASM experiments reused each accepted activation fragment across two or four adjacent output rows. Each row retained the accepted lane partition, `v_dot2_f32_bf16` order, butterfly reduction, BF16 rounding, and output layout.

Both candidates were BF16 bit-exact against the accepted raw kernel for all ten real attention layers.

| gfx1151 measured ten-layer HIP-event median | accepted wave1 wide128 | candidate | candidate change |
|---|---:|---:|---:|
| wave2 wide128 | 2.944862 ms | 3.292313 ms | +11.798% |
| wave4 wide128 | 2.760814 ms | 3.966854 ms | +43.682% |

The measured speed ratios are 0.89447x and 0.69597x. Activation reuse does not offset reduced wave-level memory parallelism and the larger live VGPR set. Neither experimental source ships.

## MXFP4 N=12800 load batching

The accepted M=1, N=12800, K=2048 block-parallel raw kernel issues two coalesced weight/scalar-activation rows before each full dependency wait. Batch-four and batch-eight variants preserved every FP32 partial bit exactly across all 30 real GDN layers.

| gfx1151 measured direct rotating result | old median / 30 layers | candidate median | speed ratio |
|---|---:|---:|---:|
| batch four, 80 interleaved samples | 2.480160 ms | 2.449437 ms | 1.01254x |
| batch eight, 40 interleaved samples | 2.479814 ms | 2.431944 ms | 1.01968x |

Batch-four paired median change was -1.145%; its mean paired change was -0.860%. Even the larger isolated ratio affects only the compute half of this two-kernel projection and projects below 0.2% of the current request wall, far below the 1% end-to-end acceptance gate. Both are rejected rather than promoted from noise.

## MXFP4 N=12800 grouped workgroups

The source already contains a block loop. Grouped variants reduced compute workgroups per layer while storing every original `[64,N]` FP32 partial row, so the established exact-order reduction remained unchanged:

| gfx1151 measured variant | workgroups / layer | old median / 30 layers | candidate median | change | exact |
|---|---:|---:|---:|---:|---:|
| group 2 | 800 | 2.483082 ms | 2.491338 ms | +0.332% | yes |
| group 4 | 400 | 2.483082 ms | 2.583631 ms | +4.049% | yes |
| group 8 | 200 | 2.486307 ms | 2.498029 ms | +0.471% | yes |

Fewer workgroups lose enough memory-level parallelism to erase setup/dispatch savings. These variants are rejected and do not ship.

A more aggressive eight-block compute-plus-scale fusion was rejected at design review: producing eight grouped scaled partials would change the established sequential 64-FMA reduction associativity. Storing all 64 scaled contributions would retain correctness but not eliminate the reduction traffic. No relaxed-tolerance implementation was benchmarked.

## Decision

Keep the accepted one-row QKV wide128 kernel and the accepted N=12800 block64 compute/reduction pair unchanged. The current production HSACO was restored and verified at SHA-256 `f16c9cdb6d0fd7bdd6c115225d6a3df76912c170144183c3358df032ba1d411b`. Continue down the measured request ranking.
