from __future__ import annotations

import re
from pathlib import Path

from ...errors import ValidationError


def validate_readobj_metadata(path: Path, *, symbol: str, kernarg_size: int,
                              threads: int, lds_bytes: int) -> dict[str, int | str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    max_workgroup_match = re.search(r"max_flat_workgroup_size:\s*(\d+)", text)
    max_threads = int(max_workgroup_match.group(1)) if max_workgroup_match else 0
    checks = {
        "target": "amdgcn-amd-amdhsa--gfx950" in text,
        "wave64": bool(re.search(r"wavefront_size:\s*64", text)),
        "symbol": bool(re.search(
            rf"\.symbol:\s*['\"]?{re.escape(symbol)}\.kd['\"]?\s*$",
            text,
            flags=re.MULTILINE,
        )),
        "kernarg": bool(re.search(rf"kernarg_segment_size:\s*{kernarg_size}\b", text)),
        # AMDHSA records a maximum, not a required launch block. The exact
        # block is part of the engine contract and may be smaller.
        "threads": threads > 0 and threads <= max_threads,
        "lds": bool(re.search(rf"group_segment_fixed_size:\s*{lds_bytes}\b", text)),
    }
    failed = [key for key, ok in checks.items() if not ok]
    if failed:
        raise ValidationError(f"metadata assertions failed ({', '.join(failed)}): {path}")
    resources: dict[str, int | str] = {"target": "gfx950", "wave_size": 64,
                                      "kernarg_size": kernarg_size,
                                      "threads": threads,
                                      "max_threads": max_threads,
                                      "lds_bytes": lds_bytes}
    for name in ("vgpr_count", "sgpr_count", "agpr_count", "private_segment_fixed_size"):
        match = re.search(rf"{name}:\s*(\d+)", text)
        if match:
            resources[name] = int(match.group(1))
    return resources
