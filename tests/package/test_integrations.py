from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

import pytest

from netra_kernel.integrations import (
    IntegrationError,
    available_integrations,
    load_integration,
)


class _Point:
    def __init__(self, name: str, value: object) -> None:
        self.name = name
        self._value = value

    def load(self) -> object:
        return self._value


class _Adapter:
    name = "reference"

    def check(self, configuration):
        return {"ok": True, "configuration": dict(configuration)}

    def activate(self, bundle: Path, *, overwrite: bool = False):
        return {"REFERENCE_BUNDLE": str(bundle)}


def test_third_party_adapter_is_discovered() -> None:
    point = _Point("reference", _Adapter())
    with patch("netra_kernel.integrations._entry_points", return_value=(point,)):
        assert available_integrations() == ("reference",)
        assert load_integration("reference").name == "reference"


def test_missing_adapter_has_actionable_error() -> None:
    with patch("netra_kernel.integrations._entry_points", return_value=()):
        with pytest.raises(IntegrationError, match="not installed"):
            load_integration("missing")
