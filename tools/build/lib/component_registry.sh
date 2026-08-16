#!/usr/bin/env bash

# Generic registry for independently loadable build components. Architecture
# directories register operation contracts; model profiles only select them.

declare -ag NETRA_COMPONENT_CONTRACTS=()
declare -Ag NETRA_COMPONENT_BUILDERS=()

netra_register_component() {
  local contract=$1
  local builder=$2

  if [[ ! "$contract" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "invalid operation contract: $contract" >&2
    return 2
  fi
  if [[ -n "${NETRA_COMPONENT_BUILDERS[$contract]:-}" ]]; then
    echo "duplicate operation contract: $contract" >&2
    return 2
  fi
  if ! declare -F "$builder" >/dev/null; then
    echo "missing builder function for $contract: $builder" >&2
    return 2
  fi

  NETRA_COMPONENT_CONTRACTS+=("$contract")
  NETRA_COMPONENT_BUILDERS["$contract"]=$builder
}

netra_load_component_registry() {
  local registry=$1
  local components_dir=$2
  local registry_dir=${components_dir}/${registry}
  local component_file
  local -a component_files=()

  if [[ ! "$registry" =~ ^[a-z0-9]+$ ]]; then
    echo "invalid component registry: $registry" >&2
    return 2
  fi
  if [[ ! -d "$registry_dir" ]]; then
    echo "unknown component registry: $registry" >&2
    return 2
  fi

  shopt -s nullglob
  component_files=("${registry_dir}"/*.sh)
  shopt -u nullglob
  if ((${#component_files[@]} == 0)); then
    echo "empty component registry: $registry" >&2
    return 2
  fi

  for component_file in "${component_files[@]}"; do
    source "$component_file"
  done
}

netra_build_component() {
  local contract=$1
  shift
  local builder=${NETRA_COMPONENT_BUILDERS[$contract]:-}

  if [[ -z "$builder" ]]; then
    echo "unknown operation contract: $contract" >&2
    return 2
  fi
  "$builder" "$@"
}
