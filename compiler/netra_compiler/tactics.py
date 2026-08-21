from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

from .contracts import GoldenKernelContract, KernelArgument, KernelContract, Launch, Workspace
from .types import DType, Epilogue, Maturity


@dataclass(frozen=True)
class ContractPredicate:
    target: str
    wave_size: int
    m: tuple[int, ...]
    n: tuple[int, ...]
    k: tuple[int, ...]
    input_dtype: DType
    weight_dtype: DType
    output_dtype: DType
    activation_scale_block: int
    weight_scale_block: tuple[int, int]
    activation_layout: str
    weight_layout: str
    output_layout: str
    epilogues: tuple[Epilogue, ...]

    def rejection_reasons(self, request: dict[str, Any]) -> list[str]:
        checks = (
            (request["target"] == self.target, "target mismatch"),
            (request["wave_size"] == self.wave_size, "wave-size mismatch"),
            (request["m"] in self.m, "M mismatch"),
            (request["n"] in self.n, "N mismatch"),
            (request["k"] in self.k, "K mismatch"),
            (request["input_dtype"] == self.input_dtype, "input dtype mismatch"),
            (request["weight_dtype"] == self.weight_dtype, "weight dtype mismatch"),
            (request["output_dtype"] == self.output_dtype, "output dtype mismatch"),
            (request["activation_scale_block"] == self.activation_scale_block, "activation scale mismatch"),
            (request["weight_scale_block"] == self.weight_scale_block, "weight scale mismatch"),
            (request["activation_layout"] == self.activation_layout, "activation layout mismatch"),
            (request["weight_layout"] == self.weight_layout, "weight layout mismatch"),
            (request["output_layout"] == self.output_layout, "output layout mismatch"),
            (request["epilogue"] in self.epilogues, "epilogue mismatch"),
        )
        return [reason for ok, reason in checks if not ok]


@dataclass(frozen=True)
class Tactic:
    name: str
    predicate: ContractPredicate
    maturity: Maturity
    artifact_kind: str
    source: str | None
    symbol: str | None
    launch: Launch
    workspace: Workspace
    graph_capture: bool
    deterministic: bool
    rank: int
    compile_parameters: tuple[tuple[str, int | str], ...] = ()
    evidence_refs: tuple[str, ...] = ()
    rejection_note: str | None = None
    source_template: str | None = None
    source_revision: str | None = None
    source_sha256: str | None = None

    def rejection_reasons(self, request: dict[str, Any], *, allow_experimental: bool) -> list[str]:
        reasons = self.predicate.rejection_reasons(request)
        if self.maturity is Maturity.REJECTED:
            reasons.append("maturity is rejected")
        elif self.maturity is Maturity.EXPERIMENT and not allow_experimental:
            reasons.append("experimental tactics are disabled")
        if request.get("graph_capture", True) and not self.graph_capture:
            reasons.append("graph capture required")
        if request.get("deterministic", True) and not self.deterministic:
            reasons.append("determinism required")
        return reasons

    def make_contract(self, request: dict[str, Any]) -> KernelContract:
        return KernelContract(
            target=request["target"], wave_size=request["wave_size"], operation="dense",
            m=request["m"], n=request["n"], k=request["k"],
            input_dtype=request["input_dtype"], weight_dtype=request["weight_dtype"],
            accumulator_dtype=DType.FP32, output_dtype=request["output_dtype"],
            activation_quantization=request["activation_quantization"],
            weight_quantization=request["weight_quantization"],
            activation_scale_block=request["activation_scale_block"],
            weight_scale_block=request["weight_scale_block"],
            activation_layout=request["activation_layout"], weight_layout=request["weight_layout"],
            output_layout=request["output_layout"], epilogue=request["epilogue"],
            tactic=self.name, launch=self.launch, workspace=self.workspace,
            graph_capture=self.graph_capture, deterministic=self.deterministic,
            fallback=request.get("fallback", "framework.aiter"), maturity=self.maturity,
            source_refs=(() if self.source is None else (self.source,)),
            evidence_refs=self.evidence_refs,
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name, "maturity": self.maturity.value,
            "artifact_kind": self.artifact_kind, "source": self.source,
            "symbol": self.symbol,
            "launch": {
                "grid": list(self.launch.grid),
                "block": list(self.launch.block),
                "lds_bytes": self.launch.lds_bytes,
                "dynamic_lds_bytes": self.launch.dynamic_lds_bytes,
            },
            "workspace": {"bytes": self.workspace.bytes, "alignment": self.workspace.alignment},
            "graph_capture": self.graph_capture, "deterministic": self.deterministic,
            "rank": self.rank, "compile_parameters": dict(self.compile_parameters),
            "evidence_refs": list(self.evidence_refs), "rejection_note": self.rejection_note,
            "source_template": self.source_template,
            "source_revision": self.source_revision,
            "source_sha256": self.source_sha256,
        }


@dataclass(frozen=True)
class GoldenTactic:
    """An immutable accepted code object; selection is exact, never ranked."""

    name: str
    contract: GoldenKernelContract
    maturity: Maturity = Maturity.ACCEPTED
    artifact_kind: str = "golden_external_hsaco"

    @property
    def symbol(self) -> str:
        return self.contract.symbol

    @property
    def source(self) -> str | None:
        return self.contract.source_refs[0] if self.contract.source_refs else None

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "maturity": self.maturity.value,
            "artifact_kind": self.artifact_kind,
            "source": self.source,
            "symbol": self.symbol,
            "launch": {
                "grid": list(self.contract.launch.grid),
                "block": list(self.contract.launch.block),
                "lds_bytes": self.contract.launch.lds_bytes,
                "dynamic_lds_bytes": self.contract.launch.dynamic_lds_bytes,
            },
            "workspace": {
                "bytes": self.contract.workspace.bytes,
                "alignment": self.contract.workspace.alignment,
            },
            "graph_capture": self.contract.graph_capture,
            "deterministic": self.contract.deterministic,
            "rank": 0,
            "compile_parameters": {},
            "evidence_refs": list(self.contract.evidence_refs),
            "rejection_note": None,
        }


def golden_tactic(attributes: Mapping[str, Any]) -> GoldenTactic:
    artifact = attributes.get("golden_artifact")
    if not isinstance(artifact, Mapping):
        raise ValueError("golden_kernel operation requires golden_artifact")
    arguments = tuple(
        KernelArgument(
            name=str(argument["name"]),
            kind=str(argument["kind"]),
            access=str(argument.get("access", "read")),
            value=argument.get("value"),
        )
        for argument in artifact.get("arguments", ())
    )
    contract = GoldenKernelContract(
        target=str(artifact.get("target", "gfx950")),
        wave_size=int(artifact.get("wave_size", 64)),
        operation=str(artifact["operation"]),
        tactic=str(artifact["tactic"]),
        symbol=str(artifact["symbol"]),
        hsaco_name=str(artifact["hsaco_name"]),
        hsaco_sha256=str(artifact["hsaco_sha256"]),
        kernarg_size=int(artifact["kernarg_size"]),
        launch=Launch(
            tuple(int(value) for value in artifact["launch"]["grid"]),
            tuple(int(value) for value in artifact["launch"]["block"]),
            int(artifact["launch"].get("lds_bytes", 0)),
            int(artifact["launch"].get("dynamic_lds_bytes", 0)),
        ),
        arguments=arguments,
        workspace=Workspace(
            int(artifact.get("workspace", {}).get("bytes", 0)),
            int(artifact.get("workspace", {}).get("alignment", 256)),
        ),
        graph_capture=bool(artifact.get("graph_capture", True)),
        deterministic=bool(artifact.get("deterministic", True)),
        fallback=str(artifact.get("fallback", "framework")),
        maturity=Maturity(str(artifact.get("maturity", "accepted"))),
        source_refs=tuple(str(value) for value in artifact.get("source_refs", ())),
        evidence_refs=tuple(str(value) for value in artifact.get("evidence_refs", ())),
    )
    return GoldenTactic(contract.tactic, contract)


def gfx950_registry() -> tuple[Tactic, ...]:
    predicate = ContractPredicate(
        "gfx950", 64, (1,), (2048,), (4096,), DType.FP8_E4M3, DType.FP8_E4M3,
        DType.BF16, 128, (128, 128), "row_major_fp8_block128",
        "aiter_shuffle_16x16_fp8_block128", "row_major_bf16", (Epilogue.IDENTITY,),
    )
    return (
        Tactic(
            "gfx950.aiter_blockscale_dense_m1.compat", predicate, Maturity.ACCEPTED,
            "framework_external", None, None, Launch((1, 1, 1), (1, 1, 1)), Workspace(),
            True, True, 1000,
            evidence_refs=("deployed Netra SGLang AITER path; retained as compatibility baseline",),
        ),
    )


def rank_tactics(request: dict[str, Any], tactics: Iterable[Tactic], *,
                 allow_experimental: bool = False) -> tuple[list[Tactic], list[tuple[Tactic, list[str]]]]:
    accepted, rejected = [], []
    for tactic in tactics:
        reasons = tactic.rejection_reasons(request, allow_experimental=allow_experimental)
        (rejected if reasons else accepted).append((tactic, reasons) if reasons else tactic)
    accepted.sort(key=lambda t: (-t.rank, t.name))
    rejected.sort(key=lambda item: item[0].name)
    return accepted, rejected
