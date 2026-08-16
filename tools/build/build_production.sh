#!/usr/bin/env bash
set -euo pipefail

# Generic production-bundle runner. Hardware/model policy belongs in a profile
# under tools/build/profiles; this entrypoint only selects and executes it.

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "${script_dir}/../.." && pwd)
profile_name=${1:-gfx950-qwen36-dflash}
action=${2:-all}

if [[ "$profile_name" == list-profiles ]]; then
  for profile_file in "${script_dir}"/profiles/*.sh; do
    profile_basename=${profile_file##*/}
    printf '%s\n' "${profile_basename%.sh}" | tr '_' '-'
  done
  exit 0
fi

if [[ ! "$profile_name" =~ ^[a-z0-9-]+$ ]]; then
  echo "invalid production profile name: $profile_name" >&2
  exit 2
fi

profile_file=${script_dir}/profiles/${profile_name//-/_}.sh
if [[ ! -f "$profile_file" ]]; then
  echo "unknown production profile: $profile_name" >&2
  exit 2
fi

source "$profile_file"
output_root=${NETRA_BUILD_ROOT:-${repo_dir}/build}
source "${script_dir}/lib/component_registry.sh"
netra_load_component_registry \
  "$NETRA_PROFILE_COMPONENT_REGISTRY" "${script_dir}/components"

case "$action" in
  list)
    printf '%s\n' "${NETRA_PROFILE_COMPONENTS[@]}"
    ;;
  contracts)
    printf '%s\n' "${NETRA_COMPONENT_CONTRACTS[@]}"
    ;;
  all)
    for component in "${NETRA_PROFILE_COMPONENTS[@]}"; do
      netra_build_component \
        "$component" "$repo_dir" "$output_root" "$script_dir" \
        "$NETRA_PROFILE_OUTPUT_NAMESPACE"
    done
    ;;
  *)
    netra_build_component \
      "$action" "$repo_dir" "$output_root" "$script_dir" \
      "$NETRA_PROFILE_OUTPUT_NAMESPACE"
    ;;
esac
