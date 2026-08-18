from __future__ import annotations

from typing import Any

from ..errors import ValidationError
from ..ir import Graph, Operation, Tensor
from ..types import DType
from .builders import append_dense_projection, dense_attributes


def _dense_attributes(spec: dict[str, Any], config: dict[str, Any]) -> dict[str, Any]:
    return dense_attributes(
        spec,
        config,
        fallback="framework.aiter",
        checkpoint_layout="aiter_shuffle_16x16_fp8_block128",
        kernel_weight_layout="aiter_shuffle_16x16_fp8_block128",
    )


def qwen_graph(model: dict[str, Any]) -> Graph:
    config = model.get("configuration", {})
    dense = list(model.get("dense_operations", []))
    layer_dense = model.get("layer_dense_operations", [])
    golden = model.get("golden_operations", [])
    fallbacks = model.get("fallback_operations", [])
    if not dense and not layer_dense and not golden and not fallbacks:
        raise ValidationError(
            "Qwen manifest must explicitly list dense_operations, "
            "layer_dense_operations, golden_operations, or fallback_operations"
        )
    if layer_dense:
        layer_types = config.get("layer_types")
        layer_count = config.get("layers", config.get("num_hidden_layers"))
        if (
            not isinstance(layer_types, list)
            or not layer_types
            or any(
                layer_type not in {"linear_attention", "full_attention"}
                for layer_type in layer_types
            )
        ):
            raise ValidationError(
                "layer_dense_operations require explicit Qwen layer_types"
            )
        if (
            not isinstance(layer_count, int)
            or isinstance(layer_count, bool)
            or layer_count != len(layer_types)
        ):
            raise ValidationError(
                "Qwen layer count must exactly match layer_types"
            )
        expanded: list[dict[str, Any]] = []
        for layer, layer_type in enumerate(layer_types):
            for template in layer_dense:
                selector = template.get("layers")
                if selector not in {"all", layer_type}:
                    continue
                spec = dict(template)
                spec.pop("layers", None)
                for field in ("name", "weight_binding"):
                    value = spec.get(field)
                    if value is not None:
                        spec[field] = str(value).format(layer=layer)
                for field in ("checkpoint_tensors", "checkpoint_scale_tensors"):
                    if field in spec:
                        spec[field] = [
                            str(value).format(layer=layer)
                            for value in spec[field]
                        ]
                expanded.append(spec)
        dense.extend(expanded)
    tensors: list[Tensor] = []
    operations: list[Operation] = []
    graph_inputs, graph_outputs = [], []
    for spec in dense:
        name = str(spec["name"])
        append_dense_projection(
            name=name,
            attributes=_dense_attributes(spec, config),
            tensors=tensors,
            operations=operations,
            graph_inputs=graph_inputs,
            graph_outputs=graph_outputs,
        )
    known_tensors = {tensor.name for tensor in tensors}
    for spec in golden:
        name = str(spec["name"])
        artifact = dict(spec["golden_artifact"])
        op_inputs: list[str] = []
        op_outputs: list[str] = []
        for argument in artifact.get("arguments", []):
            if argument.get("kind") != "pointer":
                continue
            tensor_spec = argument.get("tensor")
            if not isinstance(tensor_spec, dict):
                raise ValidationError(
                    f"golden pointer argument {argument.get('name')!r} requires tensor"
                )
            tensor_name = str(tensor_spec.get("name", argument["name"]))
            if tensor_name not in known_tensors:
                role = str(tensor_spec.get("role", "temporary"))
                tensors.append(Tensor(
                    tensor_name,
                    tuple(tensor_spec["shape"]),
                    DType(str(tensor_spec["dtype"])),
                    str(tensor_spec.get("layout", "row_major")),
                    role,
                    persistent=bool(tensor_spec.get("persistent", role in {"weight", "state"})),
                ))
                known_tensors.add(tensor_name)
                if role == "input":
                    graph_inputs.append(tensor_name)
                elif role == "output":
                    graph_outputs.append(tensor_name)
            access = str(argument.get("access", "read"))
            if access in {"read", "read_write"}:
                op_inputs.append(tensor_name)
            if access in {"write", "read_write"}:
                op_outputs.append(tensor_name)
        operations.append(Operation(
            name,
            "golden_kernel",
            tuple(op_inputs),
            tuple(op_outputs),
            {"golden_artifact": artifact},
            dict(spec.get("numerical", {})),
        ))
    for spec in fallbacks:
        name = str(spec["name"])
        operations.append(Operation(
            name,
            "server_fallback",
            (),
            (),
            {
                "operation": str(spec["operation"]),
                "fallback": str(spec["fallback"]),
                "external_status": str(
                    spec.get("external_status", "accepted_external_dispatch")
                ),
                "profile_constraints": dict(spec.get("profile_constraints", {})),
                "evidence_refs": list(spec.get("evidence_refs", ())),
            },
            dict(spec.get("numerical", {})),
        ))
    return Graph(model.get("name", "qwen-dense"), tuple(tensors), tuple(operations),
                 tuple(dict.fromkeys(graph_inputs)), tuple(dict.fromkeys(graph_outputs)))
