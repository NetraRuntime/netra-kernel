# gfx950 build-system refactor (2026-08-16)

The MI350X production build surface was consolidated without changing any
kernel, runtime bridge, or harness source.

## Changes

- Added `tools/build/lib/gfx950_assembly.sh` as the single implementation of
  the wave64 assemble, link, disassemble, and metadata-validation sequence.
- Added `tools/build/lib/gdn_variants.sh` as the single mapping from GDN
  variant names to assembler IDs, with separate M12 and M16 contracts.
- Migrated the raw FP8 decode, router, M12 verification, M12 replay, M16
  verification, and full-attention M16 builders to the shared primitives.
- Added the model-neutral `build_production.sh`, independently loadable gfx950
  operation-contract adapters, and data-only `gfx950-qwen36-dflash` composition
  profile. Public production builder names describe operation contracts rather
  than the model that first supplied their internal ABI.
  Its GDN contract explicitly pins interleaved variant 17, Triton-exact
  precompute 7, lossless K0, share-QK, and dynamic wavegroups.
- Removed accidentally tracked root-level argmax build outputs. The canonical
  source, harness, builder, validation script, and accepted-result notes remain
  in their architecture/family directories and Git history retains the files.

Measured negative experiments and their evidence were intentionally retained;
they are optimization history, not competing production entrypoints.

## Performance-preservation gate

Parent `bf05fd0` and the refactored worktree were archived separately and built
on the same MI350X host with the same ROCm installation. Each pair was built
sequentially from identical absolute source and output paths to exclude ELF
build-identity differences caused by path names.

Compared output trees:

- raw FP8 decode/MoE bundle and BF16 router, including their harnesses and
  bridges;
- promoted M12 K0 verification with dynamic 1/4/8-wave artifacts;
- M12 single- and dual-destination state replay for 1/4/8 waves;
- default M16 GDN verification, including both harnesses and the bridge;
- full-attention M16 verification, including all stages and its bridge.

Every generated output file was byte-identical. The aggregate SHA-256 over the
promoted M12 `.hsaco` and `.so` checksum list was
`66a2b604cb234cf436e0fcdf1ad1496cba2a2b9b9cbf6fa24a23d5e0a2704f84`.
The aggregate over every M16/full-attention output file was
`80b121ef5ac6f1033b4c3e4a1d64ff6b48f795a48efd2ca132db5219297414e6`.
The aggregate over every raw-FP8/router output file was
`fa6190f36814258257aed34f6025b11cf065af03cadb6eecab260f43dd12441b`.

The follow-up generic runner/profile/component split was also compared against
the Qwen-branded runner from identical source and output paths. The full
promoted M12 K0 output tree was byte-identical; its relative-path/content
checksum aggregate was
`6e9c14c56e89e91f0043759a0076b985e7d8dfea759da38f927755182a4a19aa`.
The active serving endpoint was healthy before and after validation.

Because the executable artifacts are identical, this refactor cannot change
kernel or bridge performance. Any future refactor that changes these bytes
requires correctness and performance requalification rather than being treated
as build-system cleanup.
