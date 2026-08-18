#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 ENGINE_DIR CAPTURE_DIR" >&2
  exit 2
fi
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/../.." && pwd)
engine_dir=$1
capture_dir=$2
test -f "$capture_dir/q_input.bin"

bash "$script_dir/build_engine_gfx950.sh" "$engine_dir"
harness_dir="$repo_dir/build/gfx950-qwen36-dense-m1"
harness="$harness_dir/qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950_harness"
harness_source="$repo_dir/harness/gfx950/fp8/dense/decode/qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950.hip"
mkdir -p "$harness_dir"
if [[ ! -x "$harness" || "$harness_source" -nt "$harness" ]]; then
  "${HIPCC:-/opt/rocm/bin/hipcc}" --offload-arch=gfx950 -O3 \
    "$harness_source" -o "$harness"
fi
results="$engine_dir/metadata/hardware-qwen-dense"
mkdir -p "$results"

for variant in one_wave four_wave_lds; do
  if [[ "$variant" == one_wave ]]; then
    stem=netra_dense_m1_n2048_k4096_fp8e4m3_bf16_identity_gfx950_wave1
    grid=128
    threads=64
  else
    stem=netra_dense_m1_n2048_k4096_fp8e4m3_bf16_identity_gfx950_wave4_lds
    grid=32
    threads=256
  fi
  for run in 1 2 3 4 5; do
    "$harness" "$engine_dir/hsaco/$stem.hsaco" "$capture_dir" 200 "$stem" "$grid" "$threads" \
      > "$results/${variant}-run${run}.txt"
  done
done

python_bin=${PYTHON:-python3}
if "$python_bin" -c 'import torch, aiter' >/dev/null 2>&1; then
  "$python_bin" "$repo_dir/harness/gfx950/fp8/dense/decode/qwen36_dense_m1_aiter_baseline.py" \
    --capture-dir "$capture_dir" --output "$results/aiter.json" --iterations 200 --warmup 10 --graph-replays 20
else
  printf '%s\n' '{"status":"not_run","reason":"selected Python environment lacks torch and/or aiter"}' \
    > "$results/aiter.json"
  echo "AITER oracle not run: set PYTHON to the validated Torch/AITER environment" >&2
fi
python3 - "$results" <<'PY'
import json
import pathlib
import statistics
import sys

root = pathlib.Path(sys.argv[1])
variants = {}
for variant in ("one_wave", "four_wave_lds"):
    rows = []
    for path in sorted(root.glob(f"{variant}-run*.txt")):
        fields = {}
        for line in path.read_text().splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                fields[key] = value
        rows.append({
            "median_us": float(fields["median_us"]),
            "bf16_mismatches": fields["deployed_bf16_mismatches"],
            "nondeterministic_iterations": fields["nondeterministic_iterations"],
            "graph_output_exact": fields["graph_output_exact"] == "true",
            "cosine_reference_f32": float(fields["cosine_reference_f32"]),
        })
        if fields["deployed_bf16_mismatches"] != "0/2048":
            raise SystemExit(f"{path}: generated output differs from deployed BF16")
        if fields["nondeterministic_iterations"] != "0/200":
            raise SystemExit(f"{path}: generated output is nondeterministic")
        if fields["graph_output_exact"] != "true":
            raise SystemExit(f"{path}: HIP graph replay differs")
    medians = [row["median_us"] for row in rows]
    variants[variant] = {
        "runs": rows,
        "median_of_run_medians_us": statistics.median(medians),
        "maximum_run_median_us": max(medians),
    }
summary = {
    "status": "isolated_hardware_pass",
    "promotion_eligible": False,
    "reason": "raw tactics remain rejected until matched server A/B passes",
    "variants": variants,
    "aiter": json.loads((root / "aiter.json").read_text()),
}
(root / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
PY
echo "Isolated correctness/graph/timing evidence written to $results"
echo "These results do not promote either rejected tactic; matched server A/B remains mandatory."
