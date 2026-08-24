#!/usr/bin/env python3
"""CPU-only compile checks for the public C header and bundled SHA-256."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    compiler = shutil.which("cc")
    cxx = shutil.which("c++")
    if not compiler or not cxx:
        raise RuntimeError("native SDK check requires cc and c++")
    with tempfile.TemporaryDirectory(prefix="netra-sdk-") as value:
        temporary = Path(value)
        header_test = temporary / "header.c"
        header_test.write_text(
            '#include <netra/engine.h>\n'
            '_Static_assert(NETRA_ENGINE_ABI_VERSION == 1, "ABI");\n'
            'int main(void) { netra_stream_t s = 0; return s != 0; }\n'
        )
        subprocess.run(
            [compiler, "-std=c11", "-Werror", "-I", str(ROOT / "include"),
             "-fsyntax-only", str(header_test)],
            check=True,
        )
        sha_test = temporary / "sha.cpp"
        sha_test.write_text(
            '#include "sha256.h"\n#include <iostream>\n'
            'int main(int n, char** v) { if (n != 2) return 2; '
            'std::cout << netra_detail::sha256_file(v[1]); }\n'
        )
        executable = temporary / "sha"
        subprocess.run(
            [cxx, "-std=c++17", "-Werror", "-I",
             str(ROOT / "runtime/gfx950/engine"), str(sha_test), "-o", str(executable)],
            check=True,
        )
        payload = temporary / "payload"
        payload.write_bytes(b"abc")
        actual = subprocess.check_output([str(executable), str(payload)], text=True)
        expected = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        if actual != expected:
            raise RuntimeError(f"native SHA-256 mismatch: {actual}")
    print("native SDK compile and digest checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
