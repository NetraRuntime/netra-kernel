from __future__ import annotations

from dataclasses import dataclass, field
from types import MappingProxyType
from typing import Any, Mapping

from .errors import ValidationError
from .types import DType, canonical_json


def _freeze(value: Any) -> Any:
    if isinstance(value, Mapping):
        return MappingProxyType({str(key): _freeze(item) for key, item in value.items()})
    if isinstance(value, (list, tuple)):
        return tuple(_freeze(item) for item in value)
    return value


def _thaw(value: Any) -> Any:
    if isinstance(value, Mapping):
        return {str(key): _thaw(item) for key, item in value.items()}
    if isinstance(value, tuple):
        return [_thaw(item) for item in value]
    return value


@dataclass(frozen=True)
class Tensor:
    name: str
    shape: tuple[int | str, ...]
    dtype: DType
    layout: str
    role: str = "temporary"
    alias_of: str | None = None
    persistent: bool = False

    def __post_init__(self) -> None:
        if not self.name or not self.shape:
            raise ValidationError("tensor name and shape are required")
        if any(
            (isinstance(dimension, int) and dimension <= 0)
            or (isinstance(dimension, str) and not dimension)
            or not isinstance(dimension, (int, str))
            for dimension in self.shape
        ):
            raise ValidationError(f"tensor {self.name} has an invalid shape")
        if self.role not in {"input", "output", "state", "weight", "temporary"}:
            raise ValidationError(f"invalid tensor role: {self.role}")
        if self.alias_of == self.name:
            raise ValidationError("tensor cannot alias itself")

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "shape": list(self.shape),
            "dtype": self.dtype.value,
            "layout": self.layout,
            "role": self.role,
            "alias_of": self.alias_of,
            "persistent": self.persistent,
        }


@dataclass(frozen=True)
class Operation:
    name: str
    kind: str
    inputs: tuple[str, ...]
    outputs: tuple[str, ...]
    attributes: Mapping[str, Any] = field(default_factory=dict)
    numerical: Mapping[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if not self.name or not self.kind:
            raise ValidationError("operation name and kind are required")
        object.__setattr__(self, "attributes", _freeze(self.attributes))
        object.__setattr__(self, "numerical", _freeze(self.numerical))

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "kind": self.kind,
            "inputs": list(self.inputs),
            "outputs": list(self.outputs),
            "attributes": _thaw(self.attributes),
            "numerical": _thaw(self.numerical),
        }


def Dense(name: str, inputs: tuple[str, ...], outputs: tuple[str, ...],
          attributes: dict[str, Any], numerical: dict[str, Any]) -> Operation:
    return Operation(name, "dense", inputs, outputs, attributes, numerical)


def Activation(name: str, input_name: str, output_name: str, kind: str,
               *, rounding: str) -> Operation:
    return Operation(name, "activation", (input_name,), (output_name,),
                     {"activation": kind}, {"rounding": rounding})


def Normalization(name: str, input_name: str, output_name: str,
                  attributes: dict[str, Any]) -> Operation:
    return Operation(name, "normalization", (input_name,), (output_name,), attributes,
                     {"reduction_order": attributes.get("reduction_order", "explicit_required")})


def LayoutConversion(name: str, input_name: str, output_name: str,
                     source_layout: str, target_layout: str) -> Operation:
    return Operation(name, "layout_conversion", (input_name,), (output_name,),
                     {"source_layout": source_layout, "target_layout": target_layout})


def Quantize(name: str, input_name: str, output_name: str,
             semantics: dict[str, Any]) -> Operation:
    return Operation(name, "quantize", (input_name,), (output_name,), semantics,
                     {"rounding": semantics.get("rounding", "explicit_required")})


def Dequantize(name: str, input_name: str, output_name: str,
               semantics: dict[str, Any]) -> Operation:
    return Operation(name, "dequantize", (input_name,), (output_name,), semantics,
                     {"rounding": semantics.get("rounding", "exact_scale_multiply")})


@dataclass(frozen=True)
class Graph:
    name: str
    tensors: tuple[Tensor, ...]
    operations: tuple[Operation, ...]
    inputs: tuple[str, ...]
    outputs: tuple[str, ...]
    state: tuple[str, ...] = ()

    def __post_init__(self) -> None:
        names = [t.name for t in self.tensors]
        if len(names) != len(set(names)):
            raise ValidationError("duplicate tensor name")
        available = set(names)
        operation_names = [operation.name for operation in self.operations]
        if len(operation_names) != len(set(operation_names)):
            raise ValidationError("duplicate operation name")
        tensors = {tensor.name: tensor for tensor in self.tensors}
        for tensor in self.tensors:
            if tensor.alias_of is None:
                continue
            target = tensors.get(tensor.alias_of)
            if target is None:
                raise ValidationError(f"tensor {tensor.name} aliases an unknown tensor")
            if tensor.role != "temporary" or target.role != "temporary":
                raise ValidationError("only temporary tensors may alias in netra-ir-1")
            if tensor.persistent or target.persistent or target.alias_of is not None:
                raise ValidationError(f"tensor {tensor.name} has an illegal alias target")
            if tensor.dtype is not target.dtype or tensor.layout != target.layout:
                raise ValidationError(f"tensor {tensor.name} alias changes dtype or layout")
        for op in self.operations:
            if not set((*op.inputs, *op.outputs)) <= available:
                raise ValidationError(f"operation {op.name} refers to an unknown tensor")
        if not set((*self.inputs, *self.outputs, *self.state)) <= available:
            raise ValidationError("graph boundary refers to an unknown tensor")
        for label, boundary in (
            ("input", self.inputs), ("output", self.outputs), ("state", self.state)
        ):
            if len(boundary) != len(set(boundary)):
                raise ValidationError(f"duplicate graph {label} tensor")
        for name in self.inputs:
            if tensors[name].role != "input":
                raise ValidationError(f"graph input {name} does not have input role")
        for name in self.outputs:
            if tensors[name].role != "output":
                raise ValidationError(f"graph output {name} does not have output role")
        for name in self.state:
            if tensors[name].role != "state" or not tensors[name].persistent:
                raise ValidationError(f"graph state {name} must be persistent state")
        aliases: dict[str, set[str]] = {}
        for tensor in self.tensors:
            if tensor.alias_of is not None:
                aliases.setdefault(tensor.alias_of, set()).add(tensor.name)
        ready = set(self.inputs) | set(self.state) | {
            tensor.name for tensor in self.tensors if tensor.persistent
        }
        for target, views in aliases.items():
            if target in ready:
                ready.update(views)
        producer: dict[str, str] = {}
        for op in self.operations:
            missing = sorted(set(op.inputs) - ready)
            if missing:
                raise ValidationError(
                    f"operation {op.name} consumes tensors before production: "
                    + ", ".join(missing)
                )
            for output in op.outputs:
                tensor = tensors[output]
                if tensor.alias_of is not None:
                    raise ValidationError(
                        f"operation {op.name} cannot independently produce alias {output}"
                    )
                if tensor.role in {"input", "weight"}:
                    raise ValidationError(
                        f"operation {op.name} cannot produce {tensor.role} tensor {output}"
                    )
                previous = producer.get(output)
                if previous is not None and tensor.role != "state":
                    raise ValidationError(
                        f"tensor {output} has multiple producers: {previous}, {op.name}"
                    )
                producer[output] = op.name
                ready.add(output)
                ready.update(aliases.get(output, ()))
        unavailable_outputs = sorted(set(self.outputs) - ready)
        if unavailable_outputs:
            raise ValidationError(
                "graph outputs are never produced: " + ", ".join(unavailable_outputs)
            )

    def to_dict(self) -> dict[str, Any]:
        return {
            "format": "netra-ir-1",
            "name": self.name,
            "tensors": [t.to_dict() for t in self.tensors],
            "operations": [op.to_dict() for op in self.operations],
            "inputs": list(self.inputs),
            "outputs": list(self.outputs),
            "state": list(self.state),
        }

    def serialize(self) -> str:
        return canonical_json(self.to_dict())

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Graph":
        tensors = tuple(
            Tensor(
                name=t["name"], shape=tuple(t["shape"]), dtype=DType(t["dtype"]),
                layout=t["layout"], role=t.get("role", "temporary"),
                alias_of=t.get("alias_of"), persistent=bool(t.get("persistent", False)),
            )
            for t in data["tensors"]
        )
        operations = tuple(
            Operation(
                name=o["name"], kind=o["kind"], inputs=tuple(o["inputs"]),
                outputs=tuple(o["outputs"]), attributes=dict(o.get("attributes", {})),
                numerical=dict(o.get("numerical", {})),
            )
            for o in data["operations"]
        )
        return cls(data["name"], tensors, operations, tuple(data["inputs"]),
                   tuple(data["outputs"]), tuple(data.get("state", ())))
