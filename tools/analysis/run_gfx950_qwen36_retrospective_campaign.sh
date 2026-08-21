#!/usr/bin/env bash
set -euo pipefail

mode="${1:-audit}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
kernel_root="$(cd -- "${script_dir}/../.." && pwd)"
server_root="${NETRA_RETRO_SERVER_ROOT:-$(cd -- "${kernel_root}/.." && pwd)/netra-server}"
report_root="${kernel_root}/docs/retrospectives/gfx950-qwen36-20260821"
artifact_root="${NETRA_RETRO_ARTIFACT_ROOT:-/data/netra/benchmarks}"

preflight() {
  test -d "${kernel_root}/.git" -o -f "${kernel_root}/.git"
  test -d "${server_root}/.git" -o -f "${server_root}/.git"
  printf 'kernel=%s\nserver=%s\nartifacts=%s\n' "${kernel_root}" "${server_root}" "${artifact_root}"
  printf 'kernel_head=%s\n' "$(git -C "${kernel_root}" rev-parse HEAD)"
  printf 'server_head=%s\n' "$(git -C "${server_root}" rev-parse HEAD)"
  if [[ -e /dev/kfd ]]; then printf 'dev_kfd=present\n'; else printf 'dev_kfd=absent\n'; fi
  for tool in rocminfo rocm-smi amd-smi rocprofv3 hipcc docker; do
    if command -v "${tool}" >/dev/null 2>&1; then
      printf '%s=%s\n' "${tool}" "$(command -v "${tool}")"
    else
      printf '%s=absent\n' "${tool}"
    fi
  done
}

audit() {
  python3 "${kernel_root}/tools/analysis/collect_gfx950_qwen36_retrospective.py" \
    --kernel-root "${kernel_root}" \
    --server-root "${server_root}" \
    --output-dir "${report_root}/data"
  python3 "${kernel_root}/tools/analysis/build_gfx950_qwen36_retrospective_tables.py"
  python3 -m py_compile "${kernel_root}/tools/analysis/collect_gfx950_qwen36_retrospective.py" \
    "${kernel_root}/tools/analysis/build_gfx950_qwen36_retrospective_tables.py"
  (
    cd "${kernel_root}"
    find docs/retrospectives/gfx950-qwen36-20260821 tools/analysis \
      -type f ! -name artifact-manifest.sha256 ! -path '*/__pycache__/*' -print0 \
      | sort -z | xargs -0 sha256sum > "${report_root}/artifact-manifest.sha256"
  )
  printf 'audit artifacts refreshed under %s\n' "${report_root}"
}

require_gpu() {
  [[ -e /dev/kfd ]] || { printf 'refusing GPU mode: /dev/kfd is absent\n' >&2; return 2; }
  command -v rocminfo >/dev/null 2>&1 || { printf 'refusing GPU mode: rocminfo is absent\n' >&2; return 2; }
  rocminfo | grep -q 'Name:[[:space:]]*gfx950' || { printf 'refusing GPU mode: no gfx950 agent\n' >&2; return 2; }
  [[ -d "${artifact_root}" ]] || { printf 'refusing GPU mode: %s is not mounted\n' "${artifact_root}" >&2; return 2; }
}

case "${mode}" in
  preflight)
    preflight
    ;;
  audit)
    preflight
    audit
    ;;
  gpu-preflight)
    preflight
    require_gpu
    printf 'GPU prerequisites passed. Follow %s/REPRODUCE.md.\n' "${report_root}"
    ;;
  *)
    printf 'usage: %s {preflight|audit|gpu-preflight}\n' "$0" >&2
    exit 2
    ;;
esac
