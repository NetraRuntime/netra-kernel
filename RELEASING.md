# Releasing Netra Kernel

Compiler package versions follow semantic versioning. Engine, graph-recipe,
profile, and tactic formats carry independent explicit version fields; a Python
package release does not silently change their compatibility.

## Release checklist

1. Confirm the release commit is based on the intended protected branch.
2. Update `compiler/pyproject.toml`, `compiler/netra_compiler/__init__.py`, and
   `CHANGELOG.md` together.
3. Run `make check` on a clean checkout for every supported Python version.
4. Run `make package`, install the wheel in a fresh environment, and repeat the
   CLI smoke commands with an explicit kernel-library root.
5. Cross-build every accepted deployment recipe and store code-object,
   disassembly, metadata, and comparison reports.
6. Run applicable protected hardware gates. Record unrun gates explicitly.
7. Confirm no tactic maturity or deployment default changed without its linked
   machine-readable evidence.
8. Create a reviewed, annotated tag and publish release notes derived from the
   changelog.

Do not attach locally produced HSACOs as portable generic binaries. A release
artifact must identify its target, wave size, ROCm/code-object ABI, exact
contract, source revision, and build recipe. Checkpoints, captures, credentials,
and benchmark scratch data are never release assets.
