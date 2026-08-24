from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path

import pytest

from netra_kernel.bundle import (
    BUNDLE_FORMAT,
    BundleError,
    available_profiles,
    activate_bundle,
    build_bundle,
    locate_artifacts,
    validate_bundle,
)
from netra_kernel.cli import main


def _hash(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def test_locate_artifacts_uses_locked_hash(tmp_path: Path) -> None:
    old = tmp_path / "old" / "kernel.hsaco"
    new = tmp_path / "new" / "kernel.hsaco"
    old.parent.mkdir()
    new.parent.mkdir()
    old.write_bytes(b"old")
    new.write_bytes(b"accepted")
    profile = {
        "target": "gfx950",
        "wave_size": 64,
        "accepted": True,
        "artifacts": [
            {"name": "kernel", "filename": "kernel.hsaco", "sha256": _hash(new)}
        ]
    }
    located = locate_artifacts(profile, [tmp_path])
    assert located[0].source == new


def test_locate_artifacts_reports_every_missing_file(tmp_path: Path) -> None:
    with pytest.raises(BundleError, match="one.hsaco") as error:
        locate_artifacts(
            {
                "target": "gfx950",
                "wave_size": 64,
                "accepted": True,
                "artifacts": [
                    {"name": "one", "filename": "one.hsaco", "sha256": "0" * 64},
                    {"name": "two", "filename": "two.so", "sha256": "1" * 64},
                ]
            },
            [tmp_path],
        )
    assert "two.so" in str(error.value)


def test_build_validate_and_activate(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    source = tmp_path / "input" / "kernel.hsaco"
    source.parent.mkdir()
    source.write_bytes(b"kernel")
    profile = {
        "format": "netra-sglang-profile-1",
        "revision": "test",
        "target": "gfx950",
        "wave_size": 64,
        "accepted": True,
        "artifacts": [
            {"name": "kernel", "filename": source.name, "sha256": _hash(source)}
        ],
        "integrations": {
            "sglang": {
                "environment": {
                    "NETRA_TEST_KERNEL": "{root}/artifacts/kernel/kernel.hsaco"
                }
            }
        },
    }
    monkeypatch.setattr("netra_kernel.bundle.load_profile", lambda _name: profile)
    output = tmp_path / "bundle"
    manifest_path = build_bundle(
        "test", [source.parent], output, mode="copy", runtime_root="/opt/netra"
    )
    assert json.loads(manifest_path.read_text())["format"] == BUNDLE_FORMAT
    assert validate_bundle(output)["ok"] is True
    monkeypatch.delenv("NETRA_TEST_KERNEL", raising=False)
    configured = activate_bundle(output, integration="sglang")
    assert configured["NETRA_TEST_KERNEL"] == str(
        output / "artifacts/kernel/kernel.hsaco"
    )
    assert os.environ["NETRA_TEST_KERNEL"] == configured["NETRA_TEST_KERNEL"]
    (output / "artifacts/kernel/kernel.hsaco").write_bytes(b"corrupt")
    assert validate_bundle(output)["ok"] is False


def test_nonempty_output_is_rejected(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    output = tmp_path / "bundle"
    output.mkdir()
    (output / "keep").write_text("user data")
    monkeypatch.setattr(
        "netra_kernel.bundle.load_profile",
        lambda _name: {
            "format": "netra-sglang-profile-1",
            "target": "gfx950",
            "wave_size": 64,
            "accepted": True,
            "artifacts": [
                {"name": "unused", "filename": "unused.hsaco", "sha256": "0" * 64}
            ],
        },
    )
    with pytest.raises(BundleError, match="not empty"):
        build_bundle("test", [], output)


def test_shell_environment_quotes_bundle_paths(
    capsys: pytest.CaptureFixture[str], tmp_path: Path
) -> None:
    bundle = tmp_path / "bundle with spaces"
    bundle.mkdir()
    artifact = bundle / "kernel.hsaco"
    artifact.write_bytes(b"kernel")
    (bundle / "bundle.json").write_text(
        json.dumps(
            {
                "format": BUNDLE_FORMAT,
                "profile": "test",
                "profile_revision": "test@1",
                "target": "gfx950",
                "wave_size": 64,
                "runtime_root": "/opt/netra",
                "artifacts": [
                    {
                        "name": "kernel",
                        "filename": "kernel.hsaco",
                        "kind": "code_object",
                        "path": "kernel.hsaco",
                        "sha256": _hash(artifact),
                    }
                ],
                "integrations": {
                    "sglang": {
                        "environment": {
                            "NETRA_TEST_KERNEL": "/opt/netra/kernel.hsaco"
                        }
                    }
                },
            }
        )
    )
    assert main(["env", str(bundle)]) == 0
    output = capsys.readouterr().out
    assert f"export NETRA_BUNDLE='{bundle}'" in output
    assert f"export NETRA_TEST_KERNEL='{bundle}/kernel.hsaco'" in output


def test_packaged_historical_profile_inherits_and_overrides() -> None:
    from netra_kernel.bundle import load_profile

    profile = load_profile("qwen36-35b-20260817-best")
    artifacts = {item["name"]: item for item in profile["artifacts"]}
    assert artifacts["moe-silu-quant"]["sha256"] == (
        "7cd82259b2ae3a8d92a99361e9ba9dc7dfc96b50a9cb10b586cd694de78c51fb"
    )
    assert artifacts["gqa4"]["sha256"] == (
        "1a84d68eb5d9823d7b045f0209528de4c244eeb0eb361e23ca5b869dac0dfbef"
    )
    assert "gdn-replay-precompute" in artifacts


def test_selectable_profiles_lock_every_artifact() -> None:
    from netra_kernel.bundle import load_profile

    assert available_profiles()
    for name in available_profiles():
        profile = load_profile(name)
        assert profile["accepted"] is True
        assert profile.get("abstract") is not True
        assert all(len(item["sha256"]) == 64 for item in profile["artifacts"])


def test_missing_digest_is_rejected_before_discovery(tmp_path: Path) -> None:
    with pytest.raises(BundleError, match="requires an exact sha256"):
        locate_artifacts(
            {
                "target": "gfx950",
                "wave_size": 64,
                "accepted": True,
                "artifacts": [{"name": "unsafe", "filename": "unsafe.hsaco"}],
            },
            [tmp_path],
        )


@pytest.mark.parametrize("artifact_path", ["../outside", "/tmp/outside"])
def test_bundle_rejects_paths_outside_root(
    tmp_path: Path, artifact_path: str
) -> None:
    (tmp_path / "bundle.json").write_text(
        json.dumps(
            {
                "format": BUNDLE_FORMAT,
                "profile": "test",
                "profile_revision": "test@1",
                "target": "gfx950",
                "wave_size": 64,
                "runtime_root": "/opt/netra",
                "artifacts": [
                    {
                        "name": "escape",
                        "filename": "outside",
                        "kind": "data",
                        "path": artifact_path,
                        "sha256": "0" * 64,
                    }
                ],
                "integrations": {},
            }
        )
    )
    result = validate_bundle(tmp_path)
    assert result["ok"] is False
    assert any("escapes its root" in item for item in result["errors"])


def test_bundle_rejects_symlink_escape(tmp_path: Path) -> None:
    outside = tmp_path.parent / "outside.hsaco"
    outside.write_bytes(b"outside")
    link = tmp_path / "kernel.hsaco"
    link.symlink_to(outside)
    (tmp_path / "bundle.json").write_text(
        json.dumps(
            {
                "format": BUNDLE_FORMAT,
                "profile": "test",
                "profile_revision": "test@1",
                "target": "gfx950",
                "wave_size": 64,
                "runtime_root": "/opt/netra",
                "artifacts": [
                    {
                        "name": "escape",
                        "filename": "kernel.hsaco",
                        "kind": "code_object",
                        "path": link.name,
                        "sha256": _hash(outside),
                    }
                ],
                "integrations": {},
            }
        )
    )
    assert validate_bundle(tmp_path)["ok"] is False


def test_legacy_bundle_infers_artifact_kind(tmp_path: Path) -> None:
    library = tmp_path / "bridge.so"
    library.write_bytes(b"bridge")
    (tmp_path / "bundle.json").write_text(
        json.dumps(
            {
                "format": "netra-sglang-bundle-1",
                "profile": "legacy",
                "profile_revision": "legacy@1",
                "target": "gfx950",
                "wave_size": 64,
                "runtime_root": "/opt/netra",
                "artifacts": [
                    {
                        "name": "bridge",
                        "filename": library.name,
                        "path": library.name,
                        "sha256": _hash(library),
                    }
                ],
                "environment": {},
            }
        )
    )
    assert validate_bundle(tmp_path)["ok"] is True
