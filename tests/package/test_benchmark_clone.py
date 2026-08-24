from __future__ import annotations

import importlib.util
import json
from pathlib import Path


def _module():
    path = (
        Path(__file__).resolve().parents[2]
        / "tools/benchmark/run_bundle_gate_from_inspect.py"
    )
    spec = importlib.util.spec_from_file_location("bundle_gate_clone", path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_clone_changes_only_delivery_fields(tmp_path: Path) -> None:
    inspect = [{
        "Config": {
            "Env": ["HIP_VISIBLE_DEVICES=7", "OLD=value"],
            "Cmd": ["python", "-m", "sglang.launch_server", "--port", "32187"],
            "WorkingDir": "/workspace",
            "User": "",
        },
        "HostConfig": {
            "NetworkMode": "host",
            "IpcMode": "host",
            "ShmSize": 1024,
            "CapAdd": ["SYS_PTRACE"],
            "SecurityOpt": ["seccomp=unconfined"],
            "Devices": [{
                "PathOnHost": "/dev/kfd",
                "PathInContainer": "/dev/kfd",
                "CgroupPermissions": "rwm",
            }],
            "Ulimits": [],
        },
        "Mounts": [
            {"Source": "/models", "Destination": "/models", "RW": False},
            {"Source": "/old-results", "Destination": "/results", "RW": True},
        ],
    }]
    inspect_path = tmp_path / "inspect.json"
    inspect_path.write_text(json.dumps(inspect))
    bundle = tmp_path / "bundle"
    bundle.mkdir()
    results = tmp_path / "results"
    args = type("Args", (), {
        "inspect_json": inspect_path,
        "name": "candidate",
        "image": "plugin:image",
        "bundle": bundle,
        "results": results,
        "docker": "/usr/bin/docker",
    })()
    command = _module().build_command(args)
    assert "NETRA_BUNDLE=/opt/netra" in command
    assert f"{bundle.resolve()}:/opt/netra:ro" in command
    assert f"{results.resolve()}:/results" in command
    assert "/old-results:/results" not in command
    assert "/models:/models:ro" in command
    assert command[-5:] == ["python", "-m", "sglang.launch_server", "--port", "32187"]


def test_clone_can_use_sglang_baked_into_image(tmp_path: Path) -> None:
    inspect = [{
        "Config": {
            "Env": [
                "PYTHONPATH=/recorded-source/python",
                "AITER_CONFIG=/recorded-source/tuned.csv",
                "KEEP=value",
            ],
            "Cmd": ["python", "serve.py"],
            "WorkingDir": "/workspace",
            "User": "",
        },
        "HostConfig": {
            "NetworkMode": "host",
            "IpcMode": "host",
            "ShmSize": 1024,
            "CapAdd": [],
            "SecurityOpt": [],
            "Devices": [],
            "Ulimits": [],
        },
        "Mounts": [
            {
                "Source": "/host/recorded-source",
                "Destination": "/recorded-source",
                "RW": False,
            },
            {"Source": "/models", "Destination": "/models", "RW": False},
        ],
    }]
    inspect_path = tmp_path / "inspect.json"
    inspect_path.write_text(json.dumps(inspect))
    bundle = tmp_path / "bundle"
    bundle.mkdir()
    args = type("Args", (), {
        "inspect_json": inspect_path,
        "name": "candidate",
        "image": "base:image",
        "bundle": bundle,
        "results": tmp_path / "results",
        "docker": "/usr/bin/docker",
        "use_image_sglang": True,
    })()
    command = _module().build_command(args)
    joined = " ".join(command)
    assert "/host/recorded-source" not in joined
    assert "PYTHONPATH=/recorded-source/python" not in joined
    assert "AITER_CONFIG=/recorded-source/tuned.csv" not in joined
    assert "/models:/models:ro" in command
    assert "KEEP=value" in command
