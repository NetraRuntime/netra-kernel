from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from .errors import ValidationError
from .types import DType, Epilogue, Maturity, stable_hash


_U64_MAX = (1 << 64) - 1


@dataclass(frozen=True)
class Launch:
    grid: tuple[int, int, int]
    block: tuple[int, int, int]
    # lds_bytes is code-object fixed LDS. dynamic_lds_bytes is the distinct
    # hipModuleLaunchKernel sharedMemBytes argument.
    lds_bytes: int = 0
    dynamic_lds_bytes: int = 0

    def __post_init__(self) -> None:
        if len(self.grid) != 3 or len(self.block) != 3:
            raise ValidationError("launch grid and block must have three dimensions")
        if any(v <= 0 for v in (*self.grid, *self.block)):
            raise ValidationError("launch dimensions must be positive")
        threads = self.block[0] * self.block[1] * self.block[2]
        if threads > 1024:
            raise ValidationError("threads per workgroup exceeds 1024")
        if self.lds_bytes < 0 or self.dynamic_lds_bytes < 0:
            raise ValidationError("LDS bytes must be nonnegative")


@dataclass(frozen=True)
class Workspace:
    bytes: int = 0
    alignment: int = 256

    def __post_init__(self) -> None:
        if self.bytes < 0 or self.bytes > _U64_MAX:
            raise ValidationError("workspace byte count is outside uint64")
        if self.alignment <= 0 or self.alignment & (self.alignment - 1):
            raise ValidationError("workspace alignment must be a power of two")


@dataclass(frozen=True)
class NumericalContract:
    accumulation_dtype: DType = DType.FP32
    output_rounding: str = "fp32_accumulate_then_rne_bf16_store"
    reduction_order: str = "k_block_ascending_fixed"
    nan_behavior: str = "ieee_preserve"
    deterministic: bool = True


@dataclass(frozen=True)
class KernelSemantics:
    """Versioned, model-independent interpretation of a raw-kernel ABI.

    These identifiers deliberately describe meanings rather than Python model
    classes.  A fixed assembly tactic is reusable only when every identifier
    matches; equal dimensions alone are not sufficient to reinterpret buffers.
    """

    abi: str
    dtypes: str
    quantization: str
    layouts: str
    numerical: str

    def __post_init__(self) -> None:
        for field_name in ("abi", "dtypes", "quantization", "layouts", "numerical"):
            value = getattr(self, field_name)
            if not value or any(character.isspace() for character in value):
                raise ValidationError(
                    f"kernel semantic identifier {field_name} must be nonempty and whitespace-free"
                )
            lowered = value.lower()
            if any(model in lowered for model in ("qwen", "gemma", "llama")):
                raise ValidationError(
                    f"kernel semantic identifier {field_name} must be model-independent"
                )

    def to_dict(self) -> dict[str, str]:
        return {
            "abi": self.abi,
            "dtypes": self.dtypes,
            "quantization": self.quantization,
            "layouts": self.layouts,
            "numerical": self.numerical,
        }


@dataclass(frozen=True)
class FixedKernelContract:
    """One completely specialized raw-assembly code-object contract.

    ``constants`` are semantic/tile invariants fixed by the leaf.  ``specialization``
    contains the concrete choice for each validated assembler-time option.  The
    compatibility symbol is intentionally excluded from computational identity.
    """

    target: str
    wave_size: int
    operation: str
    family: str
    constants: tuple[tuple[str, int], ...]
    specialization: tuple[tuple[str, int], ...]
    semantics: KernelSemantics
    kernarg_size: int
    symbol: str
    launch: Launch
    workspace: Workspace = field(default_factory=Workspace)
    graph_capture: bool = True
    deterministic: bool = True
    fallback: str = "framework"
    maturity: Maturity = Maturity.EXPERIMENT
    source_refs: tuple[str, ...] = ()
    evidence_refs: tuple[str, ...] = ()

    def __post_init__(self) -> None:
        if self.target != "gfx950" or self.wave_size != 64:
            raise ValidationError("fixed gfx950 contracts require gfx950/wave64")
        if not self.operation or not self.family or not self.symbol:
            raise ValidationError("fixed kernel operation, family, and symbol are required")
        if self.kernarg_size <= 0 or self.kernarg_size % 4:
            raise ValidationError("fixed kernel kernarg size must be positive and dword aligned")
        names = [name for name, _ in (*self.constants, *self.specialization)]
        if len(names) != len(set(names)):
            raise ValidationError("duplicate fixed kernel compile-time constant")
        if any(not name or value < 0 for name, value in (*self.constants, *self.specialization)):
            raise ValidationError("fixed kernel constants require names and nonnegative integers")

    def identity_dict(self) -> dict[str, Any]:
        return {
            "target": self.target,
            "wave_size": self.wave_size,
            "operation": self.operation,
            "family": self.family,
            "constants": dict(self.constants),
            "specialization": dict(self.specialization),
            "semantics": self.semantics.to_dict(),
            "kernarg_size": self.kernarg_size,
            "launch": {
                "grid": list(self.launch.grid),
                "block": list(self.launch.block),
                "lds_bytes": self.launch.lds_bytes,
                "dynamic_lds_bytes": self.launch.dynamic_lds_bytes,
            },
            "workspace": {
                "bytes": self.workspace.bytes,
                "alignment": self.workspace.alignment,
            },
            "graph_capture": self.graph_capture,
            "deterministic": self.deterministic,
        }

    @property
    def stable_id(self) -> str:
        return "nk_" + stable_hash(self.identity_dict())[:24]

    def to_dict(self) -> dict[str, Any]:
        result = self.identity_dict()
        result.update({
            "id": self.stable_id,
            "symbol": self.symbol,
            "fallback": self.fallback,
            "maturity": self.maturity.value,
            "artifact_kind": "raw_assembly_template",
            "source_refs": list(self.source_refs),
            "evidence_refs": list(self.evidence_refs),
        })
        return result


@dataclass(frozen=True)
class KernelContract:
    target: str
    wave_size: int
    operation: str
    m: int
    n: int
    k: int
    input_dtype: DType
    weight_dtype: DType
    accumulator_dtype: DType
    output_dtype: DType
    activation_quantization: str
    weight_quantization: str
    activation_scale_block: int
    weight_scale_block: tuple[int, int]
    activation_layout: str
    weight_layout: str
    output_layout: str
    epilogue: Epilogue
    tactic: str
    launch: Launch
    workspace: Workspace = field(default_factory=Workspace)
    graph_capture: bool = True
    deterministic: bool = True
    numerical: NumericalContract = field(default_factory=NumericalContract)
    fallback: str = "framework"
    maturity: Maturity = Maturity.EXPERIMENT
    source_refs: tuple[str, ...] = ()
    evidence_refs: tuple[str, ...] = ()

    def __post_init__(self) -> None:
        if self.target != "gfx950":
            raise ValidationError(f"unsupported target: {self.target}")
        if self.wave_size != 64:
            raise ValidationError("gfx950 contracts require wave64")
        if self.operation != "dense":
            raise ValidationError(f"unsupported operation: {self.operation}")
        if min(self.m, self.n, self.k) <= 0:
            raise ValidationError("M, N, and K must be positive")
        if self.activation_scale_block <= 0 or min(self.weight_scale_block) <= 0:
            raise ValidationError("scale blocks must be positive")
        if self.k % self.activation_scale_block:
            raise ValidationError("K must be divisible by the activation scale block")
        if self.n % self.weight_scale_block[0] or self.k % self.weight_scale_block[1]:
            raise ValidationError("N/K must be divisible by the weight scale block")
        if self.accumulator_dtype is not DType.FP32:
            raise ValidationError("the gfx950 dense slice requires FP32 accumulation")
        if self.deterministic and not self.numerical.deterministic:
            raise ValidationError("deterministic contract has nondeterministic numerical rules")

    def identity_dict(self) -> dict[str, Any]:
        """Computational identity; intentionally excludes model/evidence/build paths."""
        return {
            "target": self.target,
            "wave_size": self.wave_size,
            "operation": self.operation,
            "shape": [self.m, self.n, self.k],
            "dtypes": [
                self.input_dtype.value,
                self.weight_dtype.value,
                self.accumulator_dtype.value,
                self.output_dtype.value,
            ],
            "quantization": {
                "activation": self.activation_quantization,
                "weight": self.weight_quantization,
                "activation_scale_block": self.activation_scale_block,
                "weight_scale_block": list(self.weight_scale_block),
            },
            "layouts": [self.activation_layout, self.weight_layout, self.output_layout],
            "epilogue": self.epilogue.value,
            "tactic": self.tactic,
            "launch": {
                "grid": list(self.launch.grid),
                "block": list(self.launch.block),
                "lds_bytes": self.launch.lds_bytes,
                "dynamic_lds_bytes": self.launch.dynamic_lds_bytes,
            },
            "workspace": {
                "bytes": self.workspace.bytes,
                "alignment": self.workspace.alignment,
            },
            "graph_capture": self.graph_capture,
            "deterministic": self.deterministic,
            "numerical": {
                "accumulation_dtype": self.numerical.accumulation_dtype.value,
                "output_rounding": self.numerical.output_rounding,
                "reduction_order": self.numerical.reduction_order,
                "nan_behavior": self.numerical.nan_behavior,
                "deterministic": self.numerical.deterministic,
            },
        }

    @property
    def stable_id(self) -> str:
        return "nk_" + stable_hash(self.identity_dict())[:24]

    def to_dict(self) -> dict[str, Any]:
        result = self.identity_dict()
        result.update(
            {
                "id": self.stable_id,
                "fallback": self.fallback,
                "maturity": self.maturity.value,
                "source_refs": list(self.source_refs),
                "evidence_refs": list(self.evidence_refs),
            }
        )
        return result


@dataclass(frozen=True)
class FallbackKernelContract:
    """Model-independent requested dense contract with no selected GPU tactic.

    A framework fallback still needs a stable computational identity so repeated
    layer bindings can deduplicate and mismatched models cannot be described as
    sharing a kernel.  It intentionally has no launch, workspace, symbol, or
    schedule because those properties belong to the framework implementation,
    not to a selected Netra tactic.
    """

    target: str
    wave_size: int
    operation: str
    m: int
    n: int
    k: int
    input_dtype: DType
    weight_dtype: DType
    output_dtype: DType
    activation_quantization: str
    weight_quantization: str
    activation_scale_block: int
    weight_scale_block: tuple[int, int]
    activation_layout: str
    weight_layout: str
    output_layout: str
    epilogue: Epilogue
    graph_capture: bool
    deterministic: bool
    fallback: str
    activation_scale_layout: str | None = None
    weight_scale_layout: str | None = None
    numerical: NumericalContract = field(default_factory=NumericalContract)

    def identity_dict(self) -> dict[str, Any]:
        result = {
            "target": self.target,
            "wave_size": self.wave_size,
            "operation": self.operation,
            "shape": [self.m, self.n, self.k],
            "dtypes": [
                self.input_dtype.value,
                self.weight_dtype.value,
                self.numerical.accumulation_dtype.value,
                self.output_dtype.value,
            ],
            "quantization": {
                "activation": self.activation_quantization,
                "weight": self.weight_quantization,
                "activation_scale_block": self.activation_scale_block,
                "weight_scale_block": list(self.weight_scale_block),
            },
            "layouts": [
                self.activation_layout,
                self.weight_layout,
                self.output_layout,
            ],
            "epilogue": self.epilogue.value,
            "graph_capture": self.graph_capture,
            "deterministic": self.deterministic,
            "numerical": {
                "accumulation_dtype": self.numerical.accumulation_dtype.value,
                "output_rounding": self.numerical.output_rounding,
                "reduction_order": self.numerical.reduction_order,
                "nan_behavior": self.numerical.nan_behavior,
                "deterministic": self.numerical.deterministic,
            },
        }
        scale_layouts = {}
        if self.activation_scale_layout is not None:
            scale_layouts["activation"] = self.activation_scale_layout
        if self.weight_scale_layout is not None:
            scale_layouts["weight"] = self.weight_scale_layout
        if scale_layouts:
            result["scale_layouts"] = scale_layouts
        return result

    @property
    def stable_id(self) -> str:
        return "nkf_" + stable_hash(self.identity_dict())[:24]

    def to_dict(self) -> dict[str, Any]:
        result = self.identity_dict()
        result.update({
            "id": self.stable_id,
            "artifact_kind": "framework_fallback",
            "fallback": self.fallback,
        })
        return result


@dataclass(frozen=True)
class KernelArgument:
    """One fixed code-object kernarg entry.

    Pointer values are bound during engine setup/capture. Scalar constants are
    embedded in the engine record and never supplied by the request path.
    """

    name: str
    kind: str
    access: str = "read"
    value: int | None = None

    def __post_init__(self) -> None:
        if not self.name:
            raise ValidationError("kernel argument name is required")
        if self.kind not in {"pointer", "u32_constant"}:
            raise ValidationError(f"unsupported kernel argument kind: {self.kind}")
        if self.access not in {"read", "write", "read_write", "value"}:
            raise ValidationError(f"invalid kernel argument access: {self.access}")
        if self.kind == "pointer" and self.value is not None:
            raise ValidationError("pointer arguments cannot have a constant value")
        if self.kind == "u32_constant" and (
            self.value is None or self.value < 0 or self.value > (1 << 32) - 1
        ):
            raise ValidationError("u32 constants require a uint32 value")

    def to_dict(self) -> dict[str, Any]:
        result: dict[str, Any] = {
            "name": self.name,
            "kind": self.kind,
            "access": self.access,
        }
        if self.value is not None:
            result["value"] = self.value
        return result


@dataclass(frozen=True)
class GoldenKernelContract:
    """Exact accepted code-object contract used by compatibility engines."""

    target: str
    wave_size: int
    operation: str
    tactic: str
    symbol: str
    hsaco_name: str
    hsaco_sha256: str
    kernarg_size: int
    launch: Launch
    arguments: tuple[KernelArgument, ...]
    workspace: Workspace = field(default_factory=Workspace)
    graph_capture: bool = True
    deterministic: bool = True
    fallback: str = "framework"
    maturity: Maturity = Maturity.ACCEPTED
    source_refs: tuple[str, ...] = ()
    evidence_refs: tuple[str, ...] = ()

    def __post_init__(self) -> None:
        if self.target != "gfx950" or self.wave_size != 64:
            raise ValidationError("golden gfx950 contracts require gfx950/wave64")
        if not self.operation or not self.tactic or not self.symbol:
            raise ValidationError("golden operation, tactic, and symbol are required")
        if self.maturity is not Maturity.ACCEPTED:
            raise ValidationError("golden external HSACOs must already be accepted")
        if len(self.hsaco_sha256) != 64 or any(
            character not in "0123456789abcdef" for character in self.hsaco_sha256
        ):
            raise ValidationError("golden HSACO sha256 must be lowercase hexadecimal")
        if not self.arguments or len(self.arguments) > 16:
            raise ValidationError("golden kernels require one to sixteen kernargs")
        packed_size = sum(8 if argument.kind == "pointer" else 4 for argument in self.arguments)
        aligned_size = (packed_size + 7) & -8
        if self.kernarg_size != aligned_size:
            raise ValidationError(
                f"kernarg size mismatch: declared {self.kernarg_size}, typed {aligned_size}"
            )
        names = [argument.name for argument in self.arguments]
        if len(names) != len(set(names)):
            raise ValidationError("duplicate golden kernel argument name")

    def identity_dict(self) -> dict[str, Any]:
        return {
            "target": self.target,
            "wave_size": self.wave_size,
            "operation": self.operation,
            "tactic": self.tactic,
            "symbol": self.symbol,
            "hsaco_name": self.hsaco_name,
            "hsaco_sha256": self.hsaco_sha256,
            "kernarg_size": self.kernarg_size,
            "launch": {
                "grid": list(self.launch.grid),
                "block": list(self.launch.block),
                "lds_bytes": self.launch.lds_bytes,
                "dynamic_lds_bytes": self.launch.dynamic_lds_bytes,
            },
            "arguments": [argument.to_dict() for argument in self.arguments],
            "workspace": {
                "bytes": self.workspace.bytes,
                "alignment": self.workspace.alignment,
            },
            "graph_capture": self.graph_capture,
            "deterministic": self.deterministic,
        }

    @property
    def stable_id(self) -> str:
        return "nk_" + stable_hash(self.identity_dict())[:24]

    def to_dict(self) -> dict[str, Any]:
        result = self.identity_dict()
        result.update({
            "id": self.stable_id,
            "fallback": self.fallback,
            "maturity": self.maturity.value,
            "artifact_kind": "golden_external_hsaco",
            "source_refs": list(self.source_refs),
            "evidence_refs": list(self.evidence_refs),
        })
        return result
