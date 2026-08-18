from __future__ import annotations

from typing import Any

from ..errors import ValidationError
from ..ir import Graph, Operation, Tensor
from ..types import DType
from .builders import append_dense_projection, dense_attributes


def gemma_graph(model: dict[str, Any]) -> Graph:
    config = model.get("configuration", {})
    required = (
        "hidden_size",
        "intermediate_size",
        "tensor_parallel",
        "input_dtype",
        "weight_dtype",
        "output_dtype",
        "activation",
        "activation_quantization",
        "weight_quantization",
        "activation_scale_block",
        "weight_scale_block",
        "activation_layout",
        "weight_layout",
        "kernel_weight_layout",
        "output_layout",
    )
    if any(key not in config for key in required):
        missing = ", ".join(key for key in required if key not in config)
        raise ValidationError(f"Gemma configuration requires explicit fields: {missing}")
    hidden, intermediate = int(config["hidden_size"]), int(config["intermediate_size"])
    if hidden <= 0 or intermediate <= 0:
        raise ValidationError("Gemma dimensions must be positive")
    if config["activation"] != "gated_silu":
        raise ValidationError("the Gemma dense adapter currently requires gated_silu")
    input_dtype = DType(str(config["input_dtype"]))
    output_dtype = DType(str(config["output_dtype"]))
    activation_block = int(config["activation_scale_block"])
    if activation_block <= 0 or hidden % activation_block or intermediate % activation_block:
        raise ValidationError("Gemma activation scale block must divide hidden and intermediate sizes")
    tensors: list[Tensor] = []
    operations: list[Operation] = []
    inputs = ["model.hidden_fp8", "model.hidden_scale"]
    outputs: list[str] = []
    tensors.extend((
        Tensor(inputs[0], ("M", hidden), input_dtype, str(config["activation_layout"]), "input"),
        Tensor(inputs[1], ("M", hidden // activation_block), DType.FP32, "row_major", "input"),
    ))
    projection_outputs: dict[str, str] = {}
    for name in ("gate_proj", "up_proj"):
        n, k = intermediate, hidden
        prefix = f"model.layers.shared.{name}"
        attributes = dense_attributes(
            {"n": n, "k": k, "epilogue": "identity"},
            config,
            fallback="framework.gemma_dense",
            checkpoint_layout=str(
                config.get("weight_layout", "checkpoint_row_major_fp8_block128")
            ),
            kernel_weight_layout=str(
                config.get("kernel_weight_layout", "aiter_shuffle_16x16_fp8_block128")
            ),
        )
        projection_outputs[name] = f"{prefix}.output"
        append_dense_projection(
            name=prefix,
            attributes=attributes,
            tensors=tensors,
            operations=operations,
            graph_inputs=inputs,
            graph_outputs=outputs,
            activation_inputs=("model.hidden_fp8", "model.hidden_scale"),
            output_name=projection_outputs[name],
            boundary_output=False,
            output_role="temporary",
        )
    gated_bf16 = "model.layers.shared.gated_silu.output"
    gated_fp8 = "model.layers.shared.gated_silu.fp8"
    gated_scale = "model.layers.shared.gated_silu.scale"
    tensors.extend((
        Tensor(gated_bf16, ("M", intermediate), output_dtype, str(config["output_layout"])),
        Tensor(gated_fp8, ("M", intermediate), input_dtype, str(config["activation_layout"])),
        Tensor(gated_scale, ("M", intermediate // activation_block), DType.FP32, "row_major"),
    ))
    operations.append(Operation(
        "model.layers.shared.gated_silu",
        "activation",
        (projection_outputs["gate_proj"], projection_outputs["up_proj"]),
        (gated_bf16,),
        {"activation": "gated_silu"},
        {"compute_dtype": "fp32", "output_rounding": "rne_bf16"},
    ))
    operations.append(Operation(
        "model.layers.shared.gated_silu.quantize",
        "quantize",
        (gated_bf16,),
        (gated_fp8, gated_scale),
        {
            "quantization": str(config["activation_quantization"]),
            "scale_block": activation_block,
        },
        {"amax_order": "block_ascending_fixed", "rounding": "rne_fp8_e4m3"},
    ))
    down_prefix = "model.layers.shared.down_proj"
    down_attributes = dense_attributes(
        {"n": hidden, "k": intermediate, "epilogue": "identity"},
        config,
        fallback="framework.gemma_dense",
        checkpoint_layout=str(config["weight_layout"]),
        kernel_weight_layout=str(config["kernel_weight_layout"]),
    )
    append_dense_projection(
        name=down_prefix,
        attributes=down_attributes,
        tensors=tensors,
        operations=operations,
        graph_inputs=inputs,
        graph_outputs=outputs,
        activation_inputs=(gated_fp8, gated_scale),
    )
    return Graph(model.get("name", "gemma-dense-synthetic"), tuple(tensors), tuple(operations), tuple(inputs), tuple(outputs))
