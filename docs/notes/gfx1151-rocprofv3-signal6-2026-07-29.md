# gfx1151 rocprofv3 signal 6 diagnosis (2026-07-29)

## Symptom

PID 33358 was Python's `multiprocessing.resource_tracker`, spawned below the
profiled SGLang process. It inherited rocprofv3's injected tool and SIGABRT
handler. A single abort entered that handler; the handler logged/finalized and
then invoked its chained SIGABRT action, which re-entered the same profiler
path. That is why the same PID printed `rocprofv3 caught signal 6` repeatedly.
It was profiler signal-handler recursion, not an SGLang inference loop or a
gfx1151 kernel hang.

There are also two independently reproduced abort triggers which must not be
conflated with PID 33358:

1. The RocPD/SQLite writer aborts on an empty SQL name in some traces. CSV
   output bypasses that writer.
2. The active PyTorch is `2.9.1+rocm7.13.0a20260513` and loads ROCm 7.13 from
   `_rocm_sdk_core`. Launching it with `/opt/rocm-7.2.1/bin/rocprofv3` mixes
   profiler ABIs and reproduced error 16, `Configuration request occurred
   outside of valid rocprofiler configuration period`, followed by SIGABRT.

Unsetting `LD_LIBRARY_PATH` is not a valid Python workaround. It reproduced
`undefined symbol: hsa_ext_image_create_v2, version ROCR_1` by mixing the HSA
runtime in the other direction.

## Correct profiler selection

- For PyTorch/SGLang processes mapped from `_rocm_sdk_core`, use the ABI-matched
  `/root/venv1151/bin/rocprofv3` and CSV output. The replacement-kernel run
  finalized normally and emitted kernel trace/stats CSVs.
- Use `/opt/rocm-7.2.1/bin/rocprofv3` with `env -u LD_LIBRARY_PATH` only for a
  harness compiled and linked entirely with `/opt/rocm-7.2.1/bin/hipcc`.
- `scripts/rocm/tools/profiling/profile_sglang_request.sh` detects the mapped registration
  library and selects the matching profiler automatically.
- Prefer `--output-format csv`: an independent RocPD/SQLite empty-name writer
  bug also aborts during some traces, while CSV bypasses that writer.


## Confirmed safe full-stack invocation

The later recompute-W/U inventory used the ABI-matched wheel profiler from
process start with `--disable-signal-handlers true` and `--output-format csv`.
It finalized 13.56 MB of kernel trace and 30.35 MB of HIP API trace normally;
no repeated signal 6 occurred. Attaching to an already-running scheduler was
separately observed to terminate that scheduler, so process-start collection
is the required SGLang path on this machine.
The failed trace contains no valid GPU timing evidence. Only normally finalized
CSV output is labeled measured on gfx1151.

## Counter-path recurrence and resolution

A later gfx1151 counter sweep reproduced signal 6 without any active SGLang
server. The log identified the immediate cause before SIGABRT:
`aqlprofile API table load failed: HSA_STATUS_ERROR`. The system ROCm 7.2
profiler cannot preload the PyTorch wheel's ROCm 7.13 HIP library
(`hsa_ext_image_create_v2` is unresolved), while the wheel profiler can trace
that Python process but cannot bind the system `aqlprofile` counter API.

This is why retry wrappers appeared to loop over new PIDs: every counter pass
launched a fresh incompatible profiler process, each aborted with signal 6.
The accepted fix is workload-dependent: use the ABI-matched wheel profiler
with signal handlers disabled for PyTorch kernel/API traces, and use a pure
ROCm 7.2 HIP executable plus `/opt/rocm-7.2.1/bin/rocprofv3` for hardware
counter passes. The ordered recompute sweep completed fourteen counter passes
with the latter path.
