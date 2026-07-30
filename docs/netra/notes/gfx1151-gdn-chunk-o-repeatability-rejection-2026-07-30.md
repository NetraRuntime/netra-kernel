# gfx1151 GDN chunk-output repeatability rejection — 2026-07-30

Status: **rejected and quarantined**. Every number below is measured on gfx1151 (AMD Ryzen AI Max+ PRO 395). This is a correctness rejection, not a performance rejection.

Update on 2026-07-31: this rejection remains authoritative for the old four-wave implementation. A newly derived and independently gated two-wave kernel supersedes its production quarantine; see `gfx1151-gdn-chunk-o-two-wave-2026-07-31.md`. The old invalid results below have not been rewritten.

## Why the prior acceptance was invalid

The original raw `gdn_chunk_o_bv32_gfx1151` gate checked one output after warmups. A successful launch could therefore mask an intermittent dependency or execution-order defect. A later exact 32,768/+1 serving repeat changed its greedy token even though the new MoE up+SiLU intermediate was exact. Layer isolation placed the first divergence at layer 0 `linear_attn.attn`, before MoE.

The stronger harness poisons every output, runs the real B1/T8192/H32/Hg16/K128/V128/BT64 shape, compares against tuned model-native Triton, and checks eager and captured HIP-graph replay independently.

## Measured rejection

| Path | Repeats | Failures | Result |
|---|---:|---:|---|
| eager raw ASM | 30 | 21 | rejected |
| HIP-graph raw ASM replay | 30 | 15 | rejected |
| combined | 60 | 36 | rejected |

Failures include finite values as large as `5.35e34` and NaN/Inf. All recorded worst token positions are `32 mod 64`, identifying the logical second 32-row/BV32 wave path. The measured raw median was 13.535 ms versus 18.084 ms for tuned Triton (1.336x), but invalid output makes that speedup unusable.

The old 21,544.885 ms exact-32K host-E2E result is reclassified as invalid. One correct greedy token did not establish deterministic kernel correctness.

## Negative experiments

- CU mode still failed 7/40 repeated launches.
- Adding broad loader, stage, iteration, `depctr`, `vmcnt`, and `vscnt` waits did not fix the defect; one measured variant failed 53/100 launches, and a combined-wait diagnostic failed 58/60.
- WGP mode, plain `v64` initialization, and reducing allocated VGPRs from 212 to 112 changed observed frequency but did not eliminate failures.
- A qh-only low-VGPR diagnostic passed 50/50, which narrows the causal interaction, but the complete qh+qk+Av kernel still failed.
- The first two-wave/32-row redesign did not reproduce model-native math and is retained only as a clearly marked rejected experiment.

These negative sources live under `scripts/rocm/kernels/gfx1151/gdn/experiments/`; they are not production targets.

## Safe integration policy

The SGLang patch now requires `SGLANG_NETRA_ENABLE_UNSAFE_GDN_CHUNK_O_RAW=1` before importing or dispatching the rejected raw kernel. The default gfx1151 path uses the tuned Triton BK64/BV32/eight-warp kernel as a temporary correctness oracle. `SGLANG_NETRA_DISABLE_GDN_CHUNK_O_RAW=1` remains an explicit kill switch.

This compiler oracle is temporary: the final targeted replacement still must be newly derived raw gfx1151 AMDGCN and must pass repeated poisoned eager and HIP-graph gates before re-entry.

Two corrected-stack, uncached exact 32,768/+1 serving runs used identical input hashes and both produced token 82 with identical output hashes. Their measured host E2E values were 21,828.363 ms and 35,117.219 ms; the second run was heavily throttled, so it is correctness evidence rather than a stable performance median. Graph and dFlash were disabled.

## Reproduction

Run only inside Netra:

```bash
cd /root/netra-mxfp4-gfx1151
python scripts/rocm/tools/correctness/check_gdn_chunk_o_repeated.py \
  --eager-repeats 30 --graph-repeats 30 --samples 11 \
  --output results/correctness/gfx1151/gdn-chunk-o-raw-production-rejection-20260730.json
```

Machine-readable failure details, including the worst tensor index for each bad repeat, are in the adjacent JSON note.
