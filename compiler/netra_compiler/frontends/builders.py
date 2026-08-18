from __future__ import annotations

from typing import Any

from ..errors import ValidationError
from ..ir import Dense, Operation, Tensor
from ..types import DType


def dense_attributes(
    spec: dict[str, Any],
    configuration: dict[str, Any],
    *,
    fallback: str,
    checkpoint_layout: str,
    kernel_weight_layout: str,
) -> dict[str, Any]:
    """Build one model-independent dense operation attribute record."""

    def value(name: str, default: Any) -> Any:
        return spec.get(name, configuration.get(name, default))

    attributes = {
        "n": int(spec["n"]),
        "k": int(spec["k"]),
        "input_dtype": value("input_dtype", "fp8_e4m3"),
        "weight_dtype": value("weight_dtype", "fp8_e4m3"),
        "output_dtype": value("output_dtype", "bf16"),
        "activation_quantization": value("activation_quantization", "e4m3_per_128"),
        "weight_quantization": value("weight_quantization", "e4m3_128x128"),
        "activation_scale_block": int(value("activation_scale_block", 128)),
        "weight_scale_block": list(value("weight_scale_block", [128, 128])),
        "activation_layout": value("activation_layout", "row_major_fp8_block128"),
        "activation_scale_layout": value("activation_scale_layout", "row_major"),
        "weight_layout": spec.get(
            "kernel_weight_layout",
            spec.get("weight_layout", configuration.get("kernel_weight_layout", kernel_weight_layout)),
        ),
        "checkpoint_layout": value("checkpoint_layout", checkpoint_layout),
        "output_layout": value("output_layout", "row_major_bf16"),
        "weight_scale_layout": value("weight_scale_layout", "row_major"),
        "epilogue": value("epilogue", "identity"),
        "fallback": value("fallback", fallback),
        "tensor_parallel": int(configuration.get("tensor_parallel", 1)),
        "graph_capture": bool(value("graph_capture", True)),
        "deterministic": bool(value("deterministic", True)),
    }
    checkpoint_tensors = spec.get("checkpoint_tensors")
    if checkpoint_tensors is not None:
        if (
            not isinstance(checkpoint_tensors, list)
            or not checkpoint_tensors
            or any(not isinstance(name, str) or not name for name in checkpoint_tensors)
            or len(checkpoint_tensors) != len(set(checkpoint_tensors))
        ):
            raise ValidationError("checkpoint_tensors must be unique nonempty names")
        attributes["checkpoint_tensors"] = list(checkpoint_tensors)
    checkpoint_scale_tensors = spec.get("checkpoint_scale_tensors")
    if checkpoint_scale_tensors is not None:
        if (
            not isinstance(checkpoint_scale_tensors, list)
            or not checkpoint_scale_tensors
            or any(
                not isinstance(name, str) or not name
                for name in checkpoint_scale_tensors
            )
            or len(checkpoint_scale_tensors) != len(set(checkpoint_scale_tensors))
        ):
            raise ValidationError(
                "checkpoint_scale_tensors must be unique nonempty names"
            )
        attributes["checkpoint_scale_tensors"] = list(checkpoint_scale_tensors)
        attributes["checkpoint_scale_dtype"] = value(
            "checkpoint_scale_dtype", "bf16"
        )
        attributes["kernel_scale_dtype"] = value("kernel_scale_dtype", "fp32")
    weight_binding = spec.get("weight_binding")
    if weight_binding is not None:
        if not isinstance(weight_binding, str) or not weight_binding:
            raise ValidationError("weight_binding must be a nonempty name")
        attributes["weight_binding"] = weight_binding
    return attributes


def append_dense_projection(
    *,
    name: str,
    attributes: dict[str, Any],
    tensors: list[Tensor],
    operations: list[Operation],
    graph_inputs: list[str],
    graph_outputs: list[str],
    activation_inputs: tuple[str, str] | None = None,
    output_name: str | None = None,
    boundary_output: bool = True,
    output_role: str = "output",
) -> None:
    """Append a canonical dense projection without model-specific tensor logic."""

    n, k = int(attributes["n"]), int(attributes["k"])
    activation_block = int(attributes["activation_scale_block"])
    weight_blocks = tuple(int(value) for value in attributes["weight_scale_block"])
    if n <= 0 or k <= 0 or activation_block <= 0 or len(weight_blocks) != 2:
        raise ValidationError(f"dense projection {name} has invalid dimensions or scale blocks")
    if k % activation_block or n % weight_blocks[0] or k % weight_blocks[1]:
        raise ValidationError(f"dense projection {name} is not divisible by its scale blocks")
    input_dtype = DType(str(attributes["input_dtype"]))
    weight_dtype = DType(str(attributes["weight_dtype"]))
    output_dtype = DType(str(attributes["output_dtype"]))
    names = {
        "input": activation_inputs[0] if activation_inputs else f"{name}.input",
        "input_scale": activation_inputs[1] if activation_inputs else f"{name}.input_scale",
        "weight": str(attributes.get("weight_binding", f"{name}.weight")),
        "weight_scale": f"{name}.weight_scale",
        "output": output_name or f"{name}.output",
    }
    if activation_inputs is None:
        tensors.extend((
            Tensor(names["input"], ("M", k), input_dtype, str(attributes["activation_layout"]), "input"),
            Tensor(
                names["input_scale"],
                ("M", k // activation_block),
                DType.FP32,
                str(attributes["activation_scale_layout"]),
                "input",
            ),
        ))
        graph_inputs.extend((names["input"], names["input_scale"]))
    tensors.extend((
        Tensor(names["weight"], (n, k), weight_dtype, str(attributes["weight_layout"]), "weight", persistent=True),
        Tensor(
            names["weight_scale"],
            (n // weight_blocks[0], k // weight_blocks[1]),
            DType.FP32,
            str(attributes["weight_scale_layout"]),
            "weight",
            persistent=True,
        ),
        Tensor(names["output"], ("M", n), output_dtype, str(attributes["output_layout"]), output_role),
    ))
    operations.append(Dense(
        name,
        (names["input"], names["input_scale"], names["weight"], names["weight_scale"]),
        (names["output"],),
        attributes,
        {
            "accumulation_dtype": "fp32",
            "output_rounding": "fp32_accumulate_then_rne_bf16_store",
            "reduction_order": "k_block_ascending_fixed",
            "quantization_semantics": (
                f"{attributes['activation_quantization']}_weight_"
                f"{attributes['weight_quantization']}"
            ),
        },
    ))
    if boundary_output:
        graph_outputs.append(names["output"])
