# Rejected gfx1151 GDN chunk-output staging experiments (2026-07-30)

Status: **rejected; production raw ASM remains unchanged**. Runtime values are
HIP-event measurements on gfx1151. Instruction/resource values are static
assembly or profiler allocation evidence. No speedup is estimated.

## Ranked-path reason

After the accepted attention and MXFP4 gate changes, the exact 32,768-token
profile ranks `gdn_chunk_o_bv32_gfx1151` fourth: 120 invocations,
1,372.819 ms total, 11.440 ms mean, and 6.10% of the measured 22,503.266 ms
GPU-kernel total. The fixed production shape is
B1/T8192/H32/Hg16/K128/V128/BT64/BV32. Production is hand-written AMDGCN,
uses 32 KiB LDS and zero scratch, and reports 212/44 source VGPR/SGPR metadata
(216/128 profiler allocation).

The production recheck remains correct against the tuned Triton oracle:
maximum absolute error 9.536743e-7, raw median 10.956141 ms, Triton median
14.777051 ms, or 1.348746x raw speedup. Graph replay has the same error and a
10.959928 ms median. These are measured gfx1151 results.

## Raw experiments

All candidates preserve the fixed ABI, grid `(4,128,32)`, block 128, 32 KiB
LDS, zero scratch, WMMA count, and output stores.

| Candidate | Static waits | Correctness | Baseline ms | Candidate ms | Relative | Decision |
|---|---:|---|---:|---:|---:|---|
| Production | 191 | Triton max 9.54e-7 | 10.956141 | -- | -- | Retain |
| Global batch2 | 180 | raw/graph bit-exact | 11.536653 | 11.582540 | 0.996038x | Reject, slower |
| QH LDS batch | 159 | raw/graph bit-exact | 11.548975 | 11.559155 | 0.999119x | Reject, neutral/slower |
| QK one-fragment overlap | 175 | raw/graph bit-exact | 10.904491 | 10.911825 | 0.999328x | Reject, neutral/slower |
| QK two-fragment batch | 143 | incorrect and launch-to-launch nondeterministic | -- | -- | -- | Reject correctness |
| QK four-fragment batch | 127 | incorrect | -- | -- | -- | Reject correctness |
| Av LDS batch | 175 | raw/graph bit-exact | 10.919442 | 10.910465 | 1.000823x | Reject as noise over 31 samples |

The batch2, QH, QK1 and Av rows use identical nonuniform random inputs and an
independent Triton oracle. Exact variants have maximum absolute error
9.536743e-7, matching production. The apparent QK2/QK4 timing reductions are
invalid: QK2 reached errors from 7.89e18 to 8.07e33 across runs and repeated
launches were not bit-equal. This is direct evidence of an unsafe outstanding
LDS/dependency schedule, not a numerical tolerance issue. The combined
QH/QK/Av candidate is retained only as a forensic experiment.

Av batching is the only exact candidate whose median moved in the favorable
direction, but 0.0823% over 31 alternating samples is below noise and does not
justify rocprofv3 or serving gates. No candidate passed the isolated HIP-event
acceptance gate, so none was integrated and production serving was not changed.

## Graph-launch harness correction

The first dual launcher placed `hipModuleLaunchKernel`'s packed argument buffer
on the C++ stack. That can make captured replay depend on expired storage. The
retained harness now gives baseline and candidate stable, process-lifetime
argument buffers. QK1 and Av replay are bit-exact after this correction. Graph
fields from earlier invalid QK2/QK4 runs are not used as evidence.

## Static disassembly result

Every candidate retains 152 LDS-load sites, 304 LDS swizzles, and 56 WMMA
instructions. The exact schedules cut static `s_waitcnt` sites by 16 to 32 but
do not reduce elapsed time. QK2/QK4 cut 48/64 waits only by violating a real
runtime dependency. This shows that the broad waits on the production critical
path are not safely removable as a group; future work must overlap independent
global work or restructure data ownership rather than only batch LDS reads.

Complete gfx1151 baseline/candidate disassemblies and diffs are in
`docs/notes/gfx1151-gdn-chunk-o-staging-negative-2026-07-30-disassembly/`.

## Reproduction

Build with `tools/build/build_gdn_chunk_o_staging_experiments.sh`. Run exact
raw-vs-raw correctness, alternating HIP events, repeatability, and graph replay
with `tools/benchmark/benchmark_gdn_chunk_o_raw_variants.py`. The launcher is
`harness/gfx1151/gdn/gdn_chunk_o_dual_launcher.hip`; all raw candidates are
under `kernels/gfx1151/gdn/experiments/`.
