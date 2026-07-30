# gfx1151 ROCm repository reorganization (2026-07-30)

Status: canonical paths migrated and validated on gfx1151.

The SGLang bridge, patches, launcher, serving build, touched serving benchmarks, and touched profiler entry points now live under `scripts/rocm/`. Findings and evidence from new work remain under `docs/netra/notes/`. Existing untouched legacy kernel/tool paths remain only for incremental reproducibility; no new page-16 production implementation was left in the legacy tree.

Canonical production entry points:

- `scripts/rocm/integrations/sglang/`
- `scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh`
- `scripts/rocm/tools/benchmark/benchmark_sglang_fast_load.sh`
- `scripts/rocm/tools/benchmark/benchmark_sglang_fresh_request.sh`
- `scripts/rocm/tools/profiling/profile_sglang_request.sh`

Validation inside Netra:

- all migrated shell entry points passed `bash -n`;
- migrated Python integration and attention comparator passed `py_compile`;
- the complete raw-ASM SGLang backend rebuilt from the new canonical build path;
- a fresh real-checkpoint exact 210-input/+1-output request reached health and completed from the moved launch path on gfx1151;
- measured host serving E2E was 714.572176 ms, cached tokens 0, graph disabled, dFlash disabled, peak unified VRAM 99,520,413,696 bytes;
- measured launch-to-health was 24,148 ms;
- measured 26-shard load progress completed in about 10 seconds, so the prior 10–20 minute shard-loading failure did not recur.

The benchmark cleanup reports server status 137 because it deliberately terminates the launched process after the request; the request itself completed successfully.

Publication policy: commits are bundled inside Netra, streamed to the host-local `/home/rbisri/Projects/netra-kernel` clone, fast-forwarded and pushed there, then fetched back into Netra. Netra does not push directly.
