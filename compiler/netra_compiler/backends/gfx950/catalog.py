from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

from ...contracts import FixedKernelContract, KernelSemantics, Launch, Workspace
from ...types import Maturity, stable_hash


_REQUIRE_EQ = re.compile(r"^\s*NETRA_REQUIRE_EQ\s+([A-Z0-9_]+),\s*([0-9]+)\s*$", re.MULTILINE)
_INCLUDE = re.compile(r'^\s*\.include\s+"([^"]+)"\s*$', re.MULTILINE)
_MAX_WORKGROUP = re.compile(r"\.max_flat_workgroup_size:\s*(\d+)")
_FIXED_LDS = re.compile(r"\.amdhsa_group_segment_fixed_size\s+(\d+)")
_KERNARG_SIZE = re.compile(r"\.amdhsa_kernarg_size\s+(\d+)")
_TARGET_CONSTANTS = {"NETRA_TARGET_GFX", "NETRA_WAVE_SIZE"}


@dataclass(frozen=True)
class FixedAssemblyTactic:
    """A model-independent assembly schedule with assembler-time-only choices."""

    name: str
    family: str
    operation: str
    target: str
    wave_size: int
    template: str
    template_sha256: str
    source_closure_sha256: str
    computational_sha256: str
    instantiation_macro: str
    macro_parameters: tuple[str, ...]
    contract_constants: tuple[tuple[str, tuple[int, ...]], ...]
    compile_definitions: tuple[tuple[str, tuple[int, ...]], ...]
    compile_ranges: tuple[tuple[str, int, int, int], ...]
    semantics: KernelSemantics
    kernarg_size: int
    launch_block_constant: str | None
    launch_block_multiplier: int
    threads_per_workgroup: int
    lds_bytes: int
    dynamic_lds_bytes: int
    workspace: Workspace
    graph_capture: bool
    deterministic: bool
    fallback: str
    maturity: Maturity
    acceptance_scope: str
    rank: int
    evidence_refs: tuple[str, ...]
    compatibility_symbols: tuple[str, ...]

    @property
    def artifact_kind(self) -> str:
        return "raw_assembly_template"

    @property
    def stable_id(self) -> str:
        # Compatibility aliases and model evidence are deliberately excluded.
        identity = {
            "operation": self.operation,
            "family": self.family,
            "target": self.target,
            "wave_size": self.wave_size,
            "computational_sha256": self.computational_sha256,
            "contract_constants": self.contract_constants,
            "compile_definitions": self.compile_definitions,
            "compile_ranges": self.compile_ranges,
            "semantics": self.semantics.to_dict(),
            "kernarg_size": self.kernarg_size,
            "launch_block_constant": self.launch_block_constant,
            "launch_block_multiplier": self.launch_block_multiplier,
            "threads_per_workgroup": self.threads_per_workgroup,
            "lds_bytes": self.lds_bytes,
            "dynamic_lds_bytes": self.dynamic_lds_bytes,
            "workspace": {
                "bytes": self.workspace.bytes,
                "alignment": self.workspace.alignment,
            },
            "graph_capture": self.graph_capture,
            "deterministic": self.deterministic,
        }
        return stable_hash(identity)

    def rejection_reasons(
        self, request: Mapping[str, Any], *, allow_experimental: bool = False
    ) -> tuple[str, ...]:
        reasons: list[str] = []
        requested_family = request.get("family")
        if requested_family is not None and requested_family != self.family:
            reasons.append("tactic-family mismatch")
        if request.get("operation") != self.operation:
            reasons.append("operation mismatch")
        if request.get("target") != self.target:
            reasons.append("target mismatch")
        if request.get("wave_size") != self.wave_size:
            reasons.append("wave-size mismatch")
        requested_semantics = request.get("semantics")
        if isinstance(requested_semantics, KernelSemantics):
            semantic_values: Mapping[str, Any] | None = requested_semantics.to_dict()
        elif isinstance(requested_semantics, Mapping):
            semantic_values = requested_semantics
        else:
            semantic_values = None
        if semantic_values is None:
            reasons.append("semantic contract missing")
        else:
            expected_semantics = self.semantics.to_dict()
            for name, expected in expected_semantics.items():
                if semantic_values.get(name) != expected:
                    reasons.append(f"{name} semantic mismatch")
            for name in sorted(set(semantic_values) - set(expected_semantics)):
                reasons.append(f"undeclared semantic field {name}")
        if self.maturity is Maturity.REJECTED:
            reasons.append("maturity is rejected")
        elif self.maturity is Maturity.EXPERIMENT and not allow_experimental:
            reasons.append("experimental tactics are disabled")
        if request.get("graph_capture", True) and not self.graph_capture:
            reasons.append("graph capture required")
        if request.get("deterministic", True) and not self.deterministic:
            reasons.append("determinism required")
        constants = request.get("constants")
        if not isinstance(constants, Mapping):
            reasons.append("compile-time constants missing")
            return tuple(reasons)
        for name, allowed in (*self.contract_constants, *self.compile_definitions):
            if name not in constants:
                reasons.append(f"{name} missing")
            elif constants[name] not in allowed:
                reasons.append(f"{name} mismatch")
        for name, minimum, maximum, step in self.compile_ranges:
            value = constants.get(name)
            if value is None:
                reasons.append(f"{name} missing")
            elif (
                not isinstance(value, int)
                or isinstance(value, bool)
                or value < minimum
                or value > maximum
                or (value - minimum) % step
            ):
                reasons.append(f"{name} mismatch")
        declared = {
            name for name, _ in (*self.contract_constants, *self.compile_definitions)
        }
        declared.update(name for name, _, _, _ in self.compile_ranges)
        for name in sorted(set(constants) - declared):
            reasons.append(f"undeclared compile-time constant {name}")
        return tuple(reasons)

    def make_contract(self, request: Mapping[str, Any]) -> FixedKernelContract:
        reasons = self.rejection_reasons(
            request, allow_experimental=bool(request.get("allow_experimental", False))
        )
        if reasons:
            raise ValueError(f"cannot instantiate {self.name}: {', '.join(reasons)}")
        raw_grid = request.get("launch_grid")
        if not isinstance(raw_grid, (list, tuple)) or len(raw_grid) != 3:
            raise ValueError("fixed assembly request requires a three-dimensional launch_grid")
        grid = tuple(int(value) for value in raw_grid)
        constants = request["constants"]
        block_x = self.launch_block_multiplier
        if self.launch_block_constant is not None:
            block_x *= int(constants[self.launch_block_constant])
        if block_x > self.threads_per_workgroup:
            raise ValueError(
                f"resolved block size {block_x} exceeds code-object maximum "
                f"{self.threads_per_workgroup}"
            )
        concrete_specialization = tuple(
            (name, int(constants[name])) for name, _ in self.compile_definitions
        ) + tuple(
            (name, int(constants[name])) for name, _, _, _ in self.compile_ranges
        )
        identity = {
            "tactic": self.stable_id,
            "constants": dict(self.contract_constants),
            "specialization": dict(concrete_specialization),
            "grid": list(grid),
        }
        symbol = str(
            request.get("symbol")
            or f"netra_{self.operation}_{stable_hash(identity)[:16]}_gfx950"
        )
        return FixedKernelContract(
            target=self.target,
            wave_size=self.wave_size,
            operation=self.operation,
            family=self.family,
            constants=tuple((name, values[0]) for name, values in self.contract_constants),
            specialization=concrete_specialization,
            semantics=self.semantics,
            kernarg_size=self.kernarg_size,
            symbol=symbol,
            launch=Launch(
                grid,
                (block_x, 1, 1),
                self.lds_bytes,
                self.dynamic_lds_bytes,
            ),
            workspace=self.workspace,
            graph_capture=self.graph_capture,
            deterministic=self.deterministic,
            fallback=str(request.get("fallback", self.fallback)),
            maturity=self.maturity,
            source_refs=(self.template,),
            evidence_refs=self.evidence_refs,
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "stable_id": self.stable_id,
            "family": self.family,
            "operation": self.operation,
            "target": self.target,
            "wave_size": self.wave_size,
            "maturity": self.maturity.value,
            "acceptance_scope": self.acceptance_scope,
            "rank": self.rank,
            "artifact_kind": "raw_assembly_template",
            "template": self.template,
            "template_sha256": self.template_sha256,
            "source_closure_sha256": self.source_closure_sha256,
            "computational_sha256": self.computational_sha256,
            "instantiation_macro": self.instantiation_macro,
            "macro_parameters": list(self.macro_parameters),
            "contract_constants": {
                name: values[0] if len(values) == 1 else list(values)
                for name, values in self.contract_constants
            },
            "compile_definitions": {
                name: values[0] if len(values) == 1 else list(values)
                for name, values in self.compile_definitions
            },
            "compile_ranges": {
                name: {"min": minimum, "max": maximum, "step": step}
                for name, minimum, maximum, step in self.compile_ranges
            },
            "semantics": self.semantics.to_dict(),
            "kernarg_size": self.kernarg_size,
            "launch_constraints": {
                "max_threads_per_workgroup": self.threads_per_workgroup,
                "block_x": (
                    self.launch_block_multiplier
                    if self.launch_block_constant is None
                    else {
                        "constant": self.launch_block_constant,
                        "multiplier": self.launch_block_multiplier,
                    }
                ),
                "lds_bytes": self.lds_bytes,
                "dynamic_lds_bytes": self.dynamic_lds_bytes,
                "grid": "resolved_by_exact_engine_profile",
            },
            "compatibility_symbols": list(self.compatibility_symbols),
            "workspace": {
                "bytes": self.workspace.bytes,
                "alignment": self.workspace.alignment,
            },
            "graph_capture": self.graph_capture,
            "deterministic": self.deterministic,
            "fallback": self.fallback,
            "evidence_refs": list(self.evidence_refs),
        }


def _values(value: Any) -> tuple[int, ...]:
    values = value if isinstance(value, list) else [value]
    if not values or any(not isinstance(item, int) for item in values):
        raise ValueError("compile definitions must be an integer or nonempty integer list")
    return tuple(sorted(set(values)))


def _computational_text(text: str) -> str:
    """Normalize semantic assembler input while excluding debug provenance."""
    lines: list[str] = []
    in_debug_section = False
    for raw in text.splitlines():
        stripped = raw.strip()
        if stripped.startswith(".section"):
            parts = stripped.split(None, 1)
            section = parts[1] if len(parts) == 2 else ""
            in_debug_section = section.lstrip('"').startswith(".debug")
        if in_debug_section:
            continue
        if stripped.startswith((".file", ".loc", ".cfi_")):
            continue
        # Comments and source paths do not alter loaded instructions or the
        # AMDHSA launch contract. Semicolons in retained sources are comments.
        semantic = raw.split("//", 1)[0].split(";", 1)[0].strip()
        if not semantic:
            continue
        lines.append(" ".join(semantic.split()))
    return "\n".join(lines) + "\n"


def _source_closure(repo_root: Path, root: str) -> tuple[tuple[str, bytes], ...]:
    """Resolve repository-local assembler includes in semantic traversal order."""
    ordered: list[tuple[str, bytes]] = []
    visited: set[str] = set()

    def visit(relative: str) -> None:
        normalized = Path(relative).as_posix()
        if normalized in visited:
            return
        path = (repo_root / normalized).resolve()
        try:
            path.relative_to(repo_root.resolve())
        except ValueError as exc:
            raise ValueError(f"assembly include escapes repository: {relative}") from exc
        if not path.is_file():
            raise ValueError(f"missing assembly include: {relative}")
        visited.add(normalized)
        payload = path.read_bytes()
        ordered.append((normalized, payload))
        text = payload.decode("utf-8")
        for include in _INCLUDE.findall(text):
            visit(include)

    visit(root)
    return tuple(ordered)


def _closure_hash(closure: tuple[tuple[str, bytes], ...]) -> str:
    digest = hashlib.sha256()
    for relative, payload in closure:
        encoded = relative.encode("utf-8")
        digest.update(len(encoded).to_bytes(8, "big"))
        digest.update(encoded)
        digest.update(len(payload).to_bytes(8, "big"))
        digest.update(payload)
    return digest.hexdigest()


def _computational_hash(closure: tuple[tuple[str, bytes], ...]) -> str:
    digest = hashlib.sha256()
    for index, (_, payload) in enumerate(closure):
        semantic = _computational_text(payload.decode("utf-8")).encode("utf-8")
        # The traversal position and payload delimit the semantic input while
        # deliberately excluding repository filenames. Renaming a leaf or
        # include is provenance churn, not a different computational tactic.
        digest.update(index.to_bytes(8, "big"))
        digest.update(len(semantic).to_bytes(8, "big"))
        digest.update(semantic)
    return digest.hexdigest()


def load_fixed_tactic_catalog(
    repo_root: Path, target: str = "gfx950"
) -> tuple[FixedAssemblyTactic, ...]:
    catalog_root = repo_root / "manifests" / target / "tactics"
    manifest_paths = sorted(catalog_root.glob("*.json"))
    tactics: list[FixedAssemblyTactic] = []
    names: set[str] = set()
    for manifest_path in manifest_paths:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
        if data.get("format") != "netra-fixed-tactic-catalog-1":
            continue
        if data.get("target") != target:
            raise ValueError(f"tactic catalog target mismatch: {manifest_path}")
        evidence_sets = data.get("evidence_sets", {})
        default_evidence = data.get("default_evidence_set")
        default_rank = data.get("default_rank")
        for entry in data["tactics"]:
            entry_name = f"{target}.{entry['id']}"
            if entry_name in names:
                raise ValueError(f"duplicate fixed tactic name: {entry_name}")
            names.add(entry_name)
            evidence_id = str(entry.get("evidence_set", default_evidence))
            evidence = evidence_sets.get(evidence_id)
            if not isinstance(evidence, Mapping):
                raise ValueError(
                    f"missing evidence set {evidence_id!r} for {entry['id']}"
                )
            template_path = repo_root / entry["template"]
            payload = template_path.read_bytes()
            digest = hashlib.sha256(payload).hexdigest()
            if digest != entry["template_sha256"]:
                raise ValueError(f"template hash mismatch for {entry['id']}")
            closure = _source_closure(repo_root, entry["template"])
            text = payload.decode("utf-8")
            closure_text = "\n".join(item.decode("utf-8") for _, item in closure)
            closure_digest = _closure_hash(closure)
            if closure_digest != entry["source_closure_sha256"]:
                raise ValueError(f"source closure hash mismatch for {entry['id']}")
            required: dict[str, tuple[int, ...]] = {}
            for name, expected in _REQUIRE_EQ.findall(closure_text):
                if name in _TARGET_CONSTANTS:
                    continue
                value = (int(expected),)
                previous = required.get(name)
                if previous is not None and previous != value:
                    raise ValueError(
                        f"conflicting fixed requirements for {name} in {entry['id']}"
                    )
                required[name] = value
            compile_definitions = tuple(sorted(
                (name, _values(value))
                for name, value in entry["compile_definitions"].items()
            ))
            compile_ranges_list: list[tuple[str, int, int, int]] = []
            for name, raw_range in entry.get("compile_ranges", {}).items():
                if not isinstance(raw_range, Mapping):
                    raise ValueError(
                        f"compile range {name} must be an object in {entry['id']}"
                    )
                minimum = int(raw_range.get("min", 0))
                maximum = int(raw_range.get("max", 0))
                step = int(raw_range.get("step", 1))
                if minimum <= 0 or maximum < minimum or step <= 0:
                    raise ValueError(
                        f"invalid compile range {name} in {entry['id']}"
                    )
                compile_ranges_list.append((str(name), minimum, maximum, step))
            compile_ranges = tuple(sorted(compile_ranges_list))
            selectable = set(dict(compile_definitions)) | {
                name for name, _, _, _ in compile_ranges
            }
            overlap = set(required) & selectable
            if overlap:
                raise ValueError(
                    f"fixed and selectable constants overlap for {entry['id']}: "
                    + ", ".join(sorted(overlap))
                )
            duplicated = set(dict(compile_definitions)) & {
                name for name, _, _, _ in compile_ranges
            }
            if duplicated:
                raise ValueError(
                    f"listed and ranged constants overlap for {entry['id']}: "
                    + ", ".join(sorted(duplicated))
                )
            workgroups = {int(value) for value in _MAX_WORKGROUP.findall(closure_text)}
            lds_sizes = {int(value) for value in _FIXED_LDS.findall(closure_text)}
            kernarg_sizes = {int(value) for value in _KERNARG_SIZE.findall(closure_text)}
            if len(workgroups) != 1 or len(lds_sizes) != 1:
                raise ValueError(f"ambiguous launch metadata for {entry['id']}")
            kernarg_size = int(entry["kernarg_size"])
            if kernarg_size not in kernarg_sizes:
                raise ValueError(f"declared kernarg size is absent for {entry['id']}")
            semantics = KernelSemantics(**entry["semantics"])
            workspace_data = entry.get("workspace", {})
            launch_block = entry.get("launch_block")
            if isinstance(launch_block, int) and not isinstance(launch_block, bool):
                launch_block_constant = None
                launch_block_multiplier = launch_block
            elif isinstance(launch_block, Mapping):
                launch_block_constant = str(launch_block.get("constant", ""))
                launch_block_multiplier = int(launch_block.get("multiplier", 0))
                declared_options = dict(compile_definitions).get(launch_block_constant)
                if not launch_block_constant or declared_options is None:
                    raise ValueError(
                        f"launch block constant is not a build option for {entry['id']}"
                    )
            else:
                raise ValueError(f"missing fixed launch block for {entry['id']}")
            if launch_block_multiplier <= 0:
                raise ValueError(f"invalid launch block multiplier for {entry['id']}")
            macro_match = re.search(
                rf"^\s*\.macro\s+{re.escape(entry['instantiation_macro'])}(?:\s+([^\n]+))?\s*$",
                text,
                re.MULTILINE,
            )
            if macro_match is None:
                raise ValueError(f"instantiation macro is absent for {entry['id']}")
            macro_parameters = tuple(
                parameter.strip().split("=", 1)[0]
                for parameter in (macro_match.group(1) or "").split(",")
                if parameter.strip()
            )
            if not macro_parameters or macro_parameters[0] != "symbol":
                raise ValueError(
                    f"first instantiation parameter must be symbol for {entry['id']}"
                )
            rank_value = entry.get("rank", default_rank)
            if not isinstance(rank_value, int) or isinstance(rank_value, bool):
                raise ValueError(f"fixed tactic rank is required for {entry['id']}")
            tactics.append(FixedAssemblyTactic(
                name=entry_name,
                family=entry["family"],
                operation=entry["operation"],
                target=data["target"],
                wave_size=int(data["wave_size"]),
                template=entry["template"],
                template_sha256=digest,
                source_closure_sha256=closure_digest,
                computational_sha256=_computational_hash(closure),
                instantiation_macro=entry["instantiation_macro"],
                macro_parameters=macro_parameters,
                contract_constants=tuple(sorted(required.items())),
                compile_definitions=compile_definitions,
                compile_ranges=compile_ranges,
                semantics=semantics,
                kernarg_size=kernarg_size,
                launch_block_constant=launch_block_constant,
                launch_block_multiplier=launch_block_multiplier,
                threads_per_workgroup=workgroups.pop(),
                lds_bytes=lds_sizes.pop(),
                dynamic_lds_bytes=int(entry.get("dynamic_lds_bytes", 0)),
                workspace=Workspace(
                    int(workspace_data.get("bytes", 0)),
                    int(workspace_data.get("alignment", 256)),
                ),
                graph_capture=bool(entry.get("graph_capture", True)),
                deterministic=bool(entry.get("deterministic", True)),
                fallback=str(entry.get("fallback", "framework")),
                maturity=Maturity(entry["maturity"]),
                acceptance_scope=entry["acceptance_scope"],
                rank=rank_value,
                evidence_refs=(
                    str(evidence["evidence_root"]),
                    f"{evidence['lock_name']} sha256:{evidence['lock_sha256']}",
                ),
                compatibility_symbols=tuple(entry["symbols"]),
            ))
    if not tactics:
        raise ValueError(f"no fixed tactic catalogs found under {catalog_root}")
    tactics.sort(key=lambda tactic: (tactic.operation, tactic.rank, tactic.name))
    return tuple(tactics)
