"""SGLang entry point for Netra bundle activation."""

from __future__ import annotations

import logging
import os
from pathlib import Path

from netra_kernel.bundle import (
    BUNDLE_ENV,
    BundleError,
    activate_bundle,
    integration_configuration,
    load_bundle,
)
from netra_kernel.sglang.compat import probe


logger = logging.getLogger(__name__)


def register() -> None:
    """Activate an explicitly selected bundle before SGLang imports hot paths."""

    value = os.environ.get(BUNDLE_ENV)
    if not value:
        logger.debug("Netra plugin installed but %s is not set", BUNDLE_ENV)
        return
    strict = os.environ.get("NETRA_STRICT_COMPATIBILITY", "1") != "0"
    try:
        payload = load_bundle(Path(value))
        integration = integration_configuration(Path(value), "sglang")
        required = tuple(integration.get("required_modules", ()))
        report = probe(required)
        if not report.usable:
            detail = ", ".join(report.missing_modules) or "SGLang plugin API"
            message = f"Netra profile {payload['profile']} is incompatible: missing {detail}"
            if strict:
                raise RuntimeError(message)
            logger.warning(message)
        # NETRA_BUNDLE is an explicit deployment selection.  It must win over
        # stale per-artifact variables inherited from a base image or launcher.
        configured = activate_bundle(
            Path(value), integration="sglang", overwrite=True
        )
        logger.info(
            "Activated Netra profile %s (%d environment values configured)",
            payload["profile"],
            len(configured),
        )
    except (BundleError, RuntimeError) as error:
        logger.exception("Netra plugin activation failed")
        if strict:
            # SGLang intentionally catches Exception around third-party plugin
            # hooks. An explicitly selected, invalid NETRA_BUNDLE must stop the
            # process instead of silently serving through a different path.
            raise SystemExit(f"strict Netra bundle activation failed: {error}") from error
