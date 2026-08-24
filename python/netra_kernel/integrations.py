"""Inference-engine adapter discovery and activation.

The core package owns bundle integrity and lifecycle.  Engine adapters only
translate a namespaced integration configuration into an engine-specific
compatibility check.  Third-party adapters register the
``netra.inference_engines`` entry-point group and need no changes in Netra.
"""

from __future__ import annotations

from importlib.metadata import entry_points
from pathlib import Path
from typing import Mapping, Protocol, runtime_checkable

from .bundle import BundleError, integration_configuration, validate_bundle


@runtime_checkable
class InferenceEngineAdapter(Protocol):
    """Stable, deliberately small contract implemented by engine plugins."""

    name: str

    def check(self, configuration: Mapping[str, object]) -> Mapping[str, object]:
        """Return a serializable report containing at least an ``ok`` boolean."""

    def activate(
        self, bundle: Path, *, overwrite: bool = False
    ) -> Mapping[str, str]:
        """Validate and activate the adapter's bundle namespace."""


class IntegrationError(RuntimeError):
    """Raised when an engine adapter is missing or violates the protocol."""


def _entry_points() -> tuple[object, ...]:
    selected = entry_points()
    if hasattr(selected, "select"):
        return tuple(selected.select(group="netra.inference_engines"))
    return tuple(selected.get("netra.inference_engines", ()))  # pragma: no cover


def available_integrations() -> tuple[str, ...]:
    return tuple(sorted({point.name for point in _entry_points()}))


def load_integration(name: str) -> InferenceEngineAdapter:
    matches = [point for point in _entry_points() if point.name == name]
    if not matches:
        available = ", ".join(available_integrations()) or "<none>"
        raise IntegrationError(
            f"inference-engine adapter {name!r} is not installed; available: {available}"
        )
    if len(matches) != 1:
        raise IntegrationError(f"multiple inference-engine adapters are named {name!r}")
    adapter = matches[0].load()
    if not isinstance(adapter, InferenceEngineAdapter):
        raise IntegrationError(f"adapter {name!r} does not implement the Netra protocol")
    if adapter.name != name:
        raise IntegrationError(
            f"adapter entry point {name!r} exposes mismatched name {adapter.name!r}"
        )
    return adapter


def check_integration(bundle: Path, name: str) -> Mapping[str, object]:
    validation = validate_bundle(bundle)
    if not validation["ok"]:
        raise BundleError("bundle validation failed: " + ", ".join(validation["errors"]))
    configuration = integration_configuration(bundle, name)
    report = dict(load_integration(name).check(configuration))
    if not isinstance(report.get("ok"), bool):
        raise IntegrationError(f"adapter {name!r} returned no boolean ok status")
    return report


def activate_integration(
    bundle: Path, name: str, *, overwrite: bool = False
) -> Mapping[str, str]:
    validation = validate_bundle(bundle)
    if not validation["ok"]:
        raise BundleError("bundle validation failed: " + ", ".join(validation["errors"]))
    configuration = integration_configuration(bundle, name)
    adapter = load_integration(name)
    report = adapter.check(configuration)
    if report.get("ok") is not True:
        detail = report.get("error") or report.get("missing_modules") or "incompatible"
        raise IntegrationError(f"adapter {name!r} rejected the bundle: {detail}")
    return adapter.activate(bundle, overwrite=overwrite)
