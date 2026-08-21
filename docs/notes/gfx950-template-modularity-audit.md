# gfx950 template modularity audit

The repository-wide scan covered 182 files under `kernels`. This document
records the gfx950 template result because that is the target of the current
Qwen3.6 deployment.

The rejected dense M=1 assembly family has been removed completely. It was not
used by the locked Qwen3.6-27B or Qwen3.6-35B deployment and both schedules
regressed matched serving performance. Dense operations therefore remain on
the explicit framework AITER fallback.

The GDN verification families now use one public template per operation:

- `gdn/verify/precompute.inc` covers HV32 and HV48, gate-producing and QK-only
  contracts.
- `gdn/common/recurrent_bv16_core.inc` covers HV32 and HV48, T8 and T12, BF16
  and FP32 state, verification, and replay contracts.
- `gdn/verify/qkvz_causal_conv.inc` covers the T8 two-dimensional grid and T12
  one-dimensional grid schedules.

Every choice above is an assembler-time constant in the exact tactic contract.
No runtime shape selection was added.

The scan also identified seven large attention sources that are still frozen
imported ISA rather than compact compositional templates:

- GQA4 FP8-KV verification
- GQA8 FP8-KV verification
- three GQA6 M8 pointer-width schedules
- split-sequence stages 1 and 2

They remain byte-locked because they are part of validated deployments. They
must not be described as fully modular until a text-preserving decomposition is
completed and all locked text and metadata hashes pass on gfx950. A unit test
pins this exact debt inventory and rejects new large imported templates.

All other gfx950 template files are compact operation schedules or shared ABI,
addressing, numerical, reduction, synchronization, MFMA, state, and metadata
modules. Model compatibility names remain outside computational tactic
identity.

The scan also found a separate gfx1151 tree containing checked-in raw kernels
and many experiment variants. Those files are not consumed by the gfx950
compiler catalog. They remain a legacy migration for the gfx1151 target and
must not be counted as modular gfx950 templates. They were not deleted during
this change because doing so would remove unrelated target support without its
own compatibility and hardware evidence.
