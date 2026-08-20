from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .backends.gfx950.catalog import FixedAssemblyTactic, load_fixed_tactic_catalog
from .contracts import (
    FallbackKernelContract,
    FixedKernelContract,
    GoldenKernelContract,
    KernelContract,
)
from .errors import ValidationError
from .ir import Graph, Operation
from .library import KernelLibrary
from .profiles import ShapeProfile
from .tactics import GoldenTactic, Tactic, gfx950_registry, golden_tactic, rank_tactics
from .types import DType, Epilogue


@dataclass(frozen=True)
class PlannedOperation:
    operation: Operation
    contract: (
        KernelContract
        | FallbackKernelContract
        | GoldenKernelContract
        | FixedKernelContract
        | None
    )
    tactic: Tactic | GoldenTactic | FixedAssemblyTactic | None
    execution: str
    fallback: str
    explanation: tuple[dict[str, Any], ...]


@dataclass(frozen=True)
class Plan:
    graph: Graph
    profile: ShapeProfile
    operations: tuple[PlannedOperation, ...]


def _request(op: Operation, profile: ShapeProfile, target: str) -> dict[str, Any]:
    a = op.attributes
    guards = dict(profile.guards)
    if "m" not in guards or guards["m"].minimum != guards["m"].maximum:
        raise ValidationError("dense code generation requires an exact M guard")
    request = {
        "target": target, "wave_size": 64, "m": guards["m"].minimum,
        "n": int(a["n"]), "k": int(a["k"]),
        "input_dtype": DType(a.get("input_dtype", "fp8_e4m3")),
        "weight_dtype": DType(a.get("weight_dtype", "fp8_e4m3")),
        "output_dtype": DType(a.get("output_dtype", "bf16")),
        "activation_quantization": a.get("activation_quantization", "e4m3_per_128"),
        "weight_quantization": a.get("weight_quantization", "e4m3_128x128"),
        "activation_scale_block": int(a.get("activation_scale_block", 128)),
        "weight_scale_block": tuple(a.get("weight_scale_block", (128, 128))),
        "activation_layout": a.get("activation_layout", "row_major_fp8_block128"),
        "weight_layout": a.get("weight_layout", "aiter_shuffle_16x16_fp8_block128"),
        "output_layout": a.get("output_layout", "row_major_bf16"),
        "epilogue": Epilogue(a.get("epilogue", "identity")),
        "graph_capture": bool(a.get("graph_capture", True)),
        "deterministic": bool(a.get("deterministic", True)),
        "fallback": a.get("fallback", "framework.aiter"),
    }
    for name in ("activation_scale_layout", "weight_scale_layout"):
        if name in a and a[name] != "row_major":
            request[name] = str(a[name])
    return request


def _fallback_contract(request: Mapping[str, Any]) -> FallbackKernelContract:
    return FallbackKernelContract(
        target=str(request["target"]),
        wave_size=int(request["wave_size"]),
        operation="dense",
        m=int(request["m"]),
        n=int(request["n"]),
        k=int(request["k"]),
        input_dtype=request["input_dtype"],
        weight_dtype=request["weight_dtype"],
        output_dtype=request["output_dtype"],
        activation_quantization=str(request["activation_quantization"]),
        weight_quantization=str(request["weight_quantization"]),
        activation_scale_block=int(request["activation_scale_block"]),
        weight_scale_block=tuple(request["weight_scale_block"]),
        activation_layout=str(request["activation_layout"]),
        weight_layout=str(request["weight_layout"]),
        output_layout=str(request["output_layout"]),
        activation_scale_layout=request.get("activation_scale_layout"),
        weight_scale_layout=request.get("weight_scale_layout"),
        epilogue=request["epilogue"],
        graph_capture=bool(request["graph_capture"]),
        deterministic=bool(request["deterministic"]),
        fallback=str(request["fallback"]),
    )


def _fixed_request(
    op: Operation, target: str, *, allow_experimental: bool
) -> dict[str, Any]:
    attributes = op.attributes
    required = {"family", "operation", "constants", "semantics", "launch_grid"}
    missing = sorted(required - set(attributes))
    if missing:
        raise ValidationError(
            f"fixed kernel {op.name} lacks required attributes: {', '.join(missing)}"
        )
    constants = attributes["constants"]
    if not isinstance(constants, Mapping) or any(
        not isinstance(name, str) or not isinstance(value, int)
        for name, value in constants.items()
    ):
        raise ValidationError(f"fixed kernel {op.name} constants must be integer mappings")
    semantics = attributes["semantics"]
    if not isinstance(semantics, Mapping):
        raise ValidationError(f"fixed kernel {op.name} semantics must be an object")
    grid = attributes["launch_grid"]
    if not isinstance(grid, (list, tuple)) or len(grid) != 3:
        raise ValidationError(f"fixed kernel {op.name} launch_grid must have three dimensions")
    return {
        "family": str(attributes["family"]),
        "operation": str(attributes["operation"]),
        "target": target,
        "wave_size": int(attributes.get("wave_size", 64)),
        "constants": dict(constants),
        "semantics": dict(semantics),
        "launch_grid": tuple(int(value) for value in grid),
        "graph_capture": bool(attributes.get("graph_capture", True)),
        "deterministic": bool(attributes.get("deterministic", True)),
        "fallback": str(attributes.get("fallback", "framework")),
        "allow_experimental": allow_experimental,
    }


def plan_graph(graph: Graph, profile: ShapeProfile, target: str,
               *, allow_experimental: bool = False,
               registry: tuple[Tactic, ...] | None = None,
               fixed_registry: tuple[FixedAssemblyTactic, ...] | None = None,
               library_root: Path | None = None) -> Plan:
    tactics = gfx950_registry() if registry is None else registry
    if fixed_registry is None:
        repo_root = KernelLibrary.discover(library_root).root
        fixed_tactics = load_fixed_tactic_catalog(repo_root, target)
    else:
        fixed_tactics = fixed_registry
    planned = []
    for op in graph.operations:
        if op.kind == "golden_kernel":
            tactic = golden_tactic(op.attributes)
            if tactic.contract.target != target:
                raise ValidationError(
                    f"golden tactic {tactic.name} target does not match {target}"
                )
            planned.append(PlannedOperation(
                op, tactic.contract, tactic, "kernel", tactic.contract.fallback,
                ({"tactic": tactic.name, "selected": True,
                  "reasons": ["exact accepted golden HSACO contract"]},),
            ))
            continue
        if op.kind == "fixed_kernel":
            profile_names = op.attributes.get("profile_names", ())
            if profile_names and profile.name not in profile_names:
                fallback = str(op.attributes.get("fallback", "framework"))
                planned.append(PlannedOperation(
                    op, None, None, "fallback", fallback,
                    ({"tactic": None, "selected": False,
                      "reasons": [f"operation is outside profile {profile.name}"]},),
                ))
                continue
            request = _fixed_request(
                op, target, allow_experimental=allow_experimental
            )
            compatible: list[FixedAssemblyTactic] = []
            rejected: list[tuple[FixedAssemblyTactic, tuple[str, ...]]] = []
            for fixed_tactic in fixed_tactics:
                reasons = fixed_tactic.rejection_reasons(
                    request, allow_experimental=allow_experimental
                )
                if reasons:
                    rejected.append((fixed_tactic, reasons))
                else:
                    compatible.append(fixed_tactic)
            compatible.sort(key=lambda candidate: (candidate.rank, candidate.name))
            rejected.sort(key=lambda item: item[0].name)
            explanation = [
                {
                    "tactic": candidate.name,
                    "selected": bool(compatible and candidate is compatible[0]),
                    "reasons": [],
                }
                for candidate in compatible
            ]
            explanation.extend(
                {
                    "tactic": candidate.name,
                    "selected": False,
                    "reasons": list(reasons),
                }
                for candidate, reasons in rejected
            )
            if not compatible:
                planned.append(PlannedOperation(
                    op,
                    None,
                    None,
                    "fallback",
                    request["fallback"],
                    tuple(explanation),
                ))
                continue
            if len(compatible) > 1 and compatible[0].rank == compatible[1].rank:
                tied = ", ".join(
                    candidate.name
                    for candidate in compatible
                    if candidate.rank == compatible[0].rank
                )
                raise ValidationError(
                    f"ambiguous fixed tactics at rank {compatible[0].rank} for "
                    f"{op.name}: {tied}"
                )
            fixed_tactic = compatible[0]
            contract = fixed_tactic.make_contract(request)
            planned.append(PlannedOperation(
                op,
                contract,
                fixed_tactic,
                "kernel",
                contract.fallback,
                tuple(explanation),
            ))
            continue
        if op.kind != "dense":
            fallback = str(op.attributes.get("fallback", "framework"))
            planned.append(PlannedOperation(op, None, None, "fallback", fallback, (
                {"tactic": None, "selected": False, "reasons": ["operation is outside dense vertical slice"]},
            )))
            continue
        request = _request(op, profile, target)
        compatible, rejected = rank_tactics(request, tactics, allow_experimental=allow_experimental)
        explanation = [
            {"tactic": t.name, "selected": bool(compatible and t is compatible[0]), "reasons": []}
            for t in compatible
        ]
        explanation.extend(
            {"tactic": t.name, "selected": False, "reasons": reasons + ([t.rejection_note] if t.rejection_note else [])}
            for t, reasons in rejected
        )
        if not compatible:
            planned.append(PlannedOperation(
                op,
                _fallback_contract(request),
                None,
                "fallback",
                request["fallback"],
                tuple(explanation),
            ))
            continue
        tactic = compatible[0]
        contract = tactic.make_contract(request)
        execution = "framework_fallback" if tactic.artifact_kind == "framework_external" else "kernel"
        planned.append(PlannedOperation(op, contract, tactic, execution, request["fallback"], tuple(explanation)))
    return Plan(graph, profile, tuple(planned))
