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

The seven frozen attention sources have completed a text-preserving
decomposition:

- GQA4 and GQA8 use explicit entry/addressing, prefix FP8-KV attention, and
  causal-tail/output modules.
- GQA6 M8 has one public family template. QO32/KV32, QO32/KV64, and QO64/KV64
  remain separate fixed register schedules selected at assembly time.
- Every GQA6 pointer ABI reuses one FP32 output-normalization module and one
  BF16 packing/first-store module.
- Split-sequence stages 1 and 2 share one ABI metadata module.
- Every attention operation shares one parameterized AMDHSA kernel descriptor.
- Compiler debug sections and source-location directives were removed because
  they do not participate in loaded instructions or the launch contract.

The pointer-width leaves are schedules rather than public templates. They stay
separate because index width changes register allocation across the kernel.
Combining those instructions behind runtime branches would violate the fixed
contract rule. The public GQA6 template resolves the leaf with assembler-time
constants and emits no runtime dispatch.

No numbered size-only fragments are used. Unit tests require the semantic
module layout, forbid the three legacy GQA6 public templates, and reject
reintroduced compiler debug payload.

Hardware validation on gfx950 proved that the refactor preserves the loaded
programs:

- all 18 locked Qwen3.6-35B artifact text hashes remained identical;
- all three Qwen3.6-27B GQA6 M8 text hashes remained identical;
- kernarg size, workgroup size, LDS, VGPR, SGPR, and AGPR metadata remained
  identical for every refactored attention artifact;
- five fresh Qwen3.6-27B dFlash-8, BF16-state, C192 GSM8K runs averaged
  6,464.93 output tokens/s with 5.5861 mean acceptance, 96.2699 percent
  accuracy, 6,595 completed requests, and no request errors;
- five fresh single-GPU Qwen3.6-35B dFlash-12, C64 GSM8K runs averaged
  9,864.13 output tokens/s with 6.8756 mean acceptance, 94.8901 percent
  accuracy, 6,595 completed requests, and no request errors.

The 27B result is 0.55 percent below its 6,500.89 tokens/s lock and remains
inside the locked five-run variance. The 35B GSM8K run uses a different
natural-EOS workload from the locked fixed-output performance gate, so it is
serving correctness and stability evidence rather than a replacement lock.
The loaded process maps confirmed the new modular GQA4, GQA8, split-sequence,
and GQA6 code objects. Evidence is stored under
`/data/netra/benchmarks/gfx950_qwen36_27b/20260821-modular-attention-final` and
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260821-modular-attention-final`.

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
