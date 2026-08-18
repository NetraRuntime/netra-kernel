## Contract and scope

- Target/wave size:
- Operation and exact profiles:
- Dtypes, quantization, and layouts:
- Numerical/reduction contract:
- Fallback:
- Tactic maturity before/after:

## What changed

Describe the compiler, runtime, template, manifest, or documentation change.

## Validation

- [ ] `make check`
- [ ] Cross-assembly and metadata checks, or not applicable
- [ ] Independent correctness oracle, or not run
- [ ] Determinism and graph replay, or not run
- [ ] Matched serving A/B, or not run
- [ ] Raw evidence is linked or included in machine-readable form

## Performance evidence

State hardware, ROCm, checkpoint/configuration, baseline, warmup, sample count,
raw samples, median/p90, and statistical decision. Write `not run` rather than
inferring performance from compilation or a single timing sample.

## Safety

- [ ] No credentials, checkpoints, captures, or generated binaries are committed
- [ ] Unsupported contracts preserve an explicit fallback
- [ ] No allocation, synchronization, filesystem access, parsing, or module loading was added to the launch path
