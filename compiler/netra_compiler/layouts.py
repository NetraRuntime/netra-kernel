from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .errors import ValidationError


@dataclass(frozen=True)
class RepackStep:
    source_layout: str
    target_layout: str
    transform: str
    parameters: tuple[tuple[str, int], ...] = ()
    validated_scope: str = "fixture_only"

    def to_dict(self) -> dict[str, Any]:
        return {
            "source_layout": self.source_layout,
            "target_layout": self.target_layout,
            "transform": self.transform,
            "parameters": dict(self.parameters),
            "validated_scope": self.validated_scope,
        }


@dataclass(frozen=True)
class LayoutBinding:
    tensor: str
    checkpoint_layout: str
    kernel_layout: str
    output_layout: str | None
    steps: tuple[RepackStep, ...]
    checkpoint_tensors: tuple[str, ...] = ()

    def to_dict(self) -> dict[str, Any]:
        result = {
            "tensor": self.tensor,
            "checkpoint_layout": self.checkpoint_layout,
            "kernel_layout": self.kernel_layout,
            "output_layout": self.output_layout,
            "steps": [s.to_dict() for s in self.steps],
        }
        if self.checkpoint_tensors:
            result["checkpoint_tensors"] = list(self.checkpoint_tensors)
        return result


@dataclass(frozen=True)
class ScaleBinding:
    tensor: str
    checkpoint_tensors: tuple[str, ...]
    checkpoint_dtype: str
    kernel_dtype: str
    block: tuple[int, int]
    steps: tuple[str, ...]

    def to_dict(self) -> dict[str, Any]:
        return {
            "tensor": self.tensor,
            "checkpoint_tensors": list(self.checkpoint_tensors),
            "checkpoint_dtype": self.checkpoint_dtype,
            "kernel_dtype": self.kernel_dtype,
            "block": list(self.block),
            "checkpoint_layout": "row_major_block_grid",
            "kernel_layout": "row_major_block_grid",
            "steps": list(self.steps),
        }


@dataclass(frozen=True)
class LayoutTransform:
    source_layout: str
    target_layout: str
    transform: str
    parameters: tuple[tuple[str, int], ...]
    validated_scope: str

    def make_step(self) -> RepackStep:
        return RepackStep(
            self.source_layout,
            self.target_layout,
            self.transform,
            self.parameters,
            self.validated_scope,
        )


_LAYOUT_TRANSFORMS = {
    (source, "aiter_shuffle_16x16_fp8_block128"): LayoutTransform(
        source,
        "aiter_shuffle_16x16_fp8_block128",
        "aiter_shuffle_16x16",
        (("tile_m", 16), ("tile_k", 16)),
        "real_checkpoint_hook_unvalidated",
    )
    for source in (
        "checkpoint_row_major_fp8_block128",
        "row_major_fp8_block128",
        # Retained solely for the small deterministic fixture API.
        "row",
    )
}

_SPLIT_PACKED_LAYOUT = "checkpoint_split_output_row_major_fp8_block128"
_SHUFFLED_LAYOUT = "aiter_shuffle_16x16_fp8_block128"


def plan_weight_layout(
    tensor: str,
    checkpoint_layout: str,
    kernel_layout: str,
    *,
    checkpoint_tensors: tuple[str, ...] = (),
) -> LayoutBinding:
    """Select one explicit layout transform; never assume a universal shuffle."""

    if checkpoint_layout == kernel_layout:
        return LayoutBinding(
            tensor,
            checkpoint_layout,
            kernel_layout,
            None,
            (),
            checkpoint_tensors,
        )
    if checkpoint_layout == _SPLIT_PACKED_LAYOUT and kernel_layout == _SHUFFLED_LAYOUT:
        if len(checkpoint_tensors) < 2:
            raise ValidationError(
                "split-output checkpoint layout requires at least two source tensors"
            )
        steps = (
            RepackStep(
                _SPLIT_PACKED_LAYOUT,
                "checkpoint_row_major_fp8_block128",
                "concatenate_output_shards",
                (("axis", 0), ("shards", len(checkpoint_tensors))),
                "real_checkpoint_recipe_unvalidated",
            ),
            _LAYOUT_TRANSFORMS[
                ("checkpoint_row_major_fp8_block128", _SHUFFLED_LAYOUT)
            ].make_step(),
        )
        return LayoutBinding(
            tensor,
            checkpoint_layout,
            kernel_layout,
            None,
            steps,
            checkpoint_tensors,
        )
    transform = _LAYOUT_TRANSFORMS.get((checkpoint_layout, kernel_layout))
    if transform is None:
        raise ValidationError(
            f"unsupported weight layout transform: {checkpoint_layout} -> {kernel_layout}"
        )
    return LayoutBinding(
        tensor,
        checkpoint_layout,
        kernel_layout,
        None,
        (transform.make_step(),),
        checkpoint_tensors,
    )


def qwen_fp8_weight_plan(tensor: str, checkpoint_layout: str) -> LayoutBinding:
    """Compatibility wrapper for the original dense vertical-slice API."""

    return plan_weight_layout(
        tensor, checkpoint_layout, "aiter_shuffle_16x16_fp8_block128"
    )


def plan_scale_layout(
    tensor: str,
    checkpoint_tensors: tuple[str, ...],
    *,
    checkpoint_dtype: str,
    kernel_dtype: str,
    block: tuple[int, int],
) -> ScaleBinding:
    if not checkpoint_tensors:
        raise ValidationError("scale layout requires checkpoint source tensors")
    if len(block) != 2 or min(block) <= 0:
        raise ValidationError("scale layout requires a positive two-dimensional block")
    if checkpoint_dtype not in {"bf16", "fp32"} or kernel_dtype not in {
        "bf16",
        "fp32",
    }:
        raise ValidationError("unsupported checkpoint or kernel scale dtype")
    steps: list[str] = []
    if len(checkpoint_tensors) > 1:
        steps.append("concatenate_output_scale_shards_axis0")
    if checkpoint_dtype != kernel_dtype:
        if (checkpoint_dtype, kernel_dtype) != ("bf16", "fp32"):
            raise ValidationError("unsupported scale dtype transform")
        steps.append("widen_bf16_to_fp32_exact")
    return ScaleBinding(
        tensor,
        checkpoint_tensors,
        checkpoint_dtype,
        kernel_dtype,
        block,
        tuple(steps),
    )


def repack_fixture(data: bytes, rows: int, columns: int, step: RepackStep) -> bytes:
    """Small deterministic byte transform used to validate recipe plumbing.

    Real AITER checkpoint repacking remains delegated to its validated loader.
    """
    if rows <= 0 or columns <= 0 or len(data) != rows * columns:
        raise ValidationError("fixture dimensions do not match input byte count")
    if step.transform == "identity":
        return bytes(data)
    if step.transform == "transpose_bytes":
        return bytes(data[r * columns + c] for c in range(columns) for r in range(rows))
    raise ValidationError(
        f"transform {step.transform!r} is a recipe hook, not a validated fixture transform"
    )
