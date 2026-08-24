"""Compatibility shim for the former copied-into-SGLang adapter.

Install the ``netra-kernel`` wheel into the SGLang environment before copying
this file. The implementation lives in the wheel so the plugin and legacy
source-overlay paths execute exactly the same adapter.
"""

try:
    from netra_kernel.sglang.adapter import *  # noqa: F401,F403
except ModuleNotFoundError as error:
    if error.name == "netra_kernel":
        raise ModuleNotFoundError(
            "the copied Netra SGLang shim requires the netra-kernel package; "
            "install the wheel in this SGLang environment first"
        ) from error
    raise
