#!/usr/bin/env bash
set -euo pipefail

# Inject one Netra bundle mount into an existing, otherwise unchanged Docker
# launch script.  Set NETRA_DOCKER_IMAGE to the exact image argument used by
# that script and put a symlink named `docker` to this file first on PATH.
real_docker=${NETRA_REAL_DOCKER:-/usr/bin/docker}
if [[ ${1:-} != run ]]; then
  exec "$real_docker" "$@"
fi
if [[ -z ${NETRA_BUNDLE_HOST:-} || -z ${NETRA_DOCKER_IMAGE:-} ]]; then
  echo "NETRA_BUNDLE_HOST and NETRA_DOCKER_IMAGE are required" >&2
  exit 2
fi

args=("$@")
injected=()
found=0
for arg in "${args[@]}"; do
  if [[ $arg == "$NETRA_DOCKER_IMAGE" ]]; then
    injected+=(
      --env NETRA_BUNDLE=/opt/netra
      --volume "$NETRA_BUNDLE_HOST:/opt/netra:ro"
    )
    found=1
  fi
  injected+=("$arg")
done
if [[ $found != 1 ]]; then
  echo "Docker image argument not found: $NETRA_DOCKER_IMAGE" >&2
  exit 2
fi
exec "$real_docker" "${injected[@]}"
