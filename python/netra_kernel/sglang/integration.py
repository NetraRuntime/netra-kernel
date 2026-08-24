"""Transactional source integration for SGLang versions without plugins."""

from __future__ import annotations

import subprocess
import tarfile
import tempfile
from dataclasses import dataclass
from importlib.resources import files
from pathlib import Path


GFX1151_BASE_COMMIT = "1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4"
GFX1151_PATCHES = (
    "sglang-gfx1151-integration.patch",
    "sglang-gfx1151-qkvz-ba-fusion.patch",
    "sglang-gfx1151-extend-attention.patch",
    "sglang-gfx1151-gdn-chunk-o.patch",
    "sglang-gfx1151-gdn-recompute-w-u.patch",
    "sglang-gfx1151-causal-conv1d.patch",
    "sglang-gfx1151-qk-mrope-kv-fusion.patch",
    "sglang-gfx1151-mamba-track-host-flag.patch",
    "sglang-gfx1151-gdn-syncfree-chunk-metadata.patch",
    "sglang-gfx1151-bf16-lm-head.patch",
    "sglang-gfx1151-bf16-qkv.patch",
    "sglang-gfx1151-bf16-shared-gate-up-silu.patch",
    "sglang-gfx1151-bf16-attention-output.patch",
    "sglang-gfx1151-bf16-router.patch",
    "sglang-gfx1151-qwen36-rmsnorm.patch",
)


class IntegrationError(RuntimeError):
    """Raised when a source overlay cannot be applied safely."""


@dataclass(frozen=True)
class IntegrationReport:
    target: str
    source_commit: str
    expected_commit: str
    exact_base: bool
    patch_count: int
    preflight_passed: bool
    applied: bool

    def to_dict(self) -> dict:
        return self.__dict__.copy()


def _run(argv: list[str], *, cwd: Path) -> str:
    result = subprocess.run(
        argv,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode:
        detail = result.stderr.strip() or result.stdout.strip()
        raise IntegrationError(f"{' '.join(argv)} failed: {detail}")
    return result.stdout.strip()


def _extract_patches(destination: Path) -> Path:
    archive_path = Path(
        str(
            files("netra_kernel").joinpath(
                "assets", "overlays", "gfx1151-patches.tar.gz"
            )
        )
    )
    if not archive_path.is_file():
        raise IntegrationError("the gfx1151 SGLang overlay is absent from this install")
    destination.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive_path, "r:gz") as archive:
        members = archive.getmembers()
        names = {member.name for member in members}
        if names != set(GFX1151_PATCHES) or any(
            Path(member.name).name != member.name or not member.isfile()
            for member in members
        ):
            raise IntegrationError("the packaged gfx1151 overlay has invalid members")
        for member in members:
            source = archive.extractfile(member)
            if source is None:
                raise IntegrationError(
                    f"cannot read packaged gfx1151 patch {member.name}"
                )
            (destination / member.name).write_bytes(source.read())
    return destination


def _validate_tree(root: Path) -> str:
    root = root.expanduser().resolve()
    if not (root / ".git").exists() or not (root / "python/sglang").is_dir():
        raise IntegrationError(f"not an SGLang git checkout: {root}")
    dirty = _run(["git", "status", "--porcelain"], cwd=root)
    if dirty:
        raise IntegrationError(
            "SGLang checkout has uncommitted changes; commit or stash them before integration"
        )
    return _run(["git", "rev-parse", "HEAD"], cwd=root)


def _apply_patches(root: Path, patch_root: Path) -> None:
    for name in GFX1151_PATCHES:
        _run(["git", "apply", "--3way", str(patch_root / name)], cwd=root)


def _write_adapter_shim(root: Path) -> None:
    destination = root / "python/sglang/srt/layers/quantization/netra_gfx1151.py"
    if destination.exists():
        raise IntegrationError(f"adapter destination already exists: {destination}")
    destination.write_text(
        '"""Netra gfx1151 adapter supplied by the netra-kernel package."""\n'
        "try:\n"
        "    from netra_kernel.sglang.adapter import *  # noqa: F401,F403\n"
        "except ModuleNotFoundError as error:\n"
        "    if error.name == 'netra_kernel':\n"
        "        raise ModuleNotFoundError(\n"
        "            'the Netra SGLang overlay requires netra-kernel to be installed'\n"
        "        ) from error\n"
        "    raise\n",
        encoding="utf-8",
    )


def integrate(root: Path, *, apply: bool = False) -> IntegrationReport:
    """Preflight the full overlay in a disposable worktree, then optionally apply."""

    root = root.expanduser().resolve()
    commit = _validate_tree(root)
    with tempfile.TemporaryDirectory(prefix="netra-sglang-preflight-") as temp:
        temporary_root = Path(temp)
        patch_root = _extract_patches(temporary_root / "patches")
        worktree = temporary_root / "sglang"
        _run(["git", "worktree", "add", "--detach", str(worktree), commit], cwd=root)
        try:
            _apply_patches(worktree, patch_root)
            _write_adapter_shim(worktree)
        finally:
            _run(["git", "worktree", "remove", "--force", str(worktree)], cwd=root)
        if apply:
            _apply_patches(root, patch_root)
            _write_adapter_shim(root)
    return IntegrationReport(
        target="gfx1151",
        source_commit=commit,
        expected_commit=GFX1151_BASE_COMMIT,
        exact_base=commit == GFX1151_BASE_COMMIT,
        patch_count=len(GFX1151_PATCHES),
        preflight_passed=True,
        applied=apply,
    )
