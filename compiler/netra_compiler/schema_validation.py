from __future__ import annotations

import re
from collections.abc import Mapping, Sequence
from typing import Any

from .errors import ValidationError


def _resolve(root: Mapping[str, Any], reference: str) -> Mapping[str, Any]:
    if not reference.startswith("#/"):
        raise ValidationError(f"only local JSON schema references are supported: {reference}")
    value: Any = root
    for token in reference[2:].split("/"):
        token = token.replace("~1", "/").replace("~0", "~")
        if not isinstance(value, Mapping) or token not in value:
            raise ValidationError(f"unresolved JSON schema reference: {reference}")
        value = value[token]
    if not isinstance(value, Mapping):
        raise ValidationError(f"JSON schema reference is not an object: {reference}")
    return value


def _type_matches(value: Any, expected: str) -> bool:
    return {
        "object": isinstance(value, Mapping),
        "array": isinstance(value, Sequence) and not isinstance(value, (str, bytes, bytearray)),
        "string": isinstance(value, str),
        "integer": isinstance(value, int) and not isinstance(value, bool),
        "number": isinstance(value, (int, float)) and not isinstance(value, bool),
        "boolean": isinstance(value, bool),
        "null": value is None,
    }.get(expected, False)


def _errors(
    value: Any,
    schema: Mapping[str, Any],
    root: Mapping[str, Any],
    path: str,
) -> list[str]:
    if "$ref" in schema:
        return _errors(value, _resolve(root, str(schema["$ref"])), root, path)
    if "oneOf" in schema:
        matches = [
            not _errors(value, candidate, root, path)
            for candidate in schema["oneOf"]
        ]
        if sum(matches) != 1:
            return [f"{path}: expected exactly one schema variant"]
    errors: list[str] = []
    expected_type = schema.get("type")
    if expected_type is not None:
        choices = [expected_type] if isinstance(expected_type, str) else list(expected_type)
        if not any(_type_matches(value, choice) for choice in choices):
            return [f"{path}: expected type {'/'.join(choices)}"]
    if "const" in schema and value != schema["const"]:
        errors.append(f"{path}: expected constant {schema['const']!r}")
    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{path}: value is outside the allowed enum")
    if isinstance(value, Mapping):
        for name in schema.get("required", []):
            if name not in value:
                errors.append(f"{path}: missing required property {name!r}")
        properties = schema.get("properties", {})
        for name, child in properties.items():
            if name in value:
                errors.extend(_errors(value[name], child, root, f"{path}.{name}"))
        if schema.get("additionalProperties") is False:
            for name in sorted(set(value) - set(properties)):
                errors.append(f"{path}: unexpected property {name!r}")
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes, bytearray)):
        if len(value) < int(schema.get("minItems", 0)):
            errors.append(f"{path}: array is shorter than minItems")
        if "maxItems" in schema and len(value) > int(schema["maxItems"]):
            errors.append(f"{path}: array is longer than maxItems")
        for index, child in enumerate(schema.get("prefixItems", [])):
            if index < len(value):
                errors.extend(_errors(value[index], child, root, f"{path}[{index}]"))
        item_schema = schema.get("items")
        if isinstance(item_schema, Mapping):
            for index, item in enumerate(value):
                errors.extend(_errors(item, item_schema, root, f"{path}[{index}]"))
    if isinstance(value, str):
        if len(value) < int(schema.get("minLength", 0)):
            errors.append(f"{path}: string is shorter than minLength")
        if "pattern" in schema and re.search(str(schema["pattern"]), value) is None:
            errors.append(f"{path}: string does not match required pattern")
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            errors.append(f"{path}: number is below minimum")
        if "maximum" in schema and value > schema["maximum"]:
            errors.append(f"{path}: number is above maximum")
    return errors


def validate_json_schema(
    value: Any, schema: Mapping[str, Any], *, label: str = "document"
) -> None:
    """Validate the repository's deterministic schema subset without dependencies."""
    errors = _errors(value, schema, schema, "$")
    if errors:
        raise ValidationError(f"{label} schema validation failed: " + "; ".join(errors))
