"""SGLang implementation of the framework-neutral adapter protocol."""

from __future__ import annotations

from pathlib import Path
from typing import Mapping

from netra_kernel.bundle import activate_bundle
from netra_kernel.sglang.compat import probe


class SGLangAdapter:
    name = "sglang"

    def check(self, configuration: Mapping[str, object]) -> Mapping[str, object]:
        required = tuple(str(value) for value in configuration.get("required_modules", ()))
        report = probe(required)
        result = report.to_dict()
        result["ok"] = report.usable
        return result

    def activate(
        self, bundle: Path, *, overwrite: bool = False
    ) -> Mapping[str, str]:
        return activate_bundle(bundle, integration=self.name, overwrite=overwrite)


adapter = SGLangAdapter()
