#!/usr/bin/env python3
"""Clone a recorded Docker deployment while replacing artifact delivery.

The model/server configuration, mounts, device permissions, and command come
from an audited ``docker inspect`` capture.  Only the image, container name,
results directory, and the single Netra bundle mount are changed.
"""

from __future__ import annotations

import argparse
import json
import os
import shlex
import subprocess
from pathlib import Path


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inspect-json", type=Path, required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--image", required=True)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--results", type=Path, required=True)
    parser.add_argument("--docker", default="/usr/bin/docker")
    parser.add_argument(
        "--use-image-sglang",
        action="store_true",
        help="drop the recorded source mount/PYTHONPATH and use the image source",
    )
    parser.add_argument("--dry-run", action="store_true")
    return parser


def build_command(args: argparse.Namespace) -> list[str]:
    payload = json.loads(args.inspect_json.read_text(encoding="utf-8"))
    source = payload[0] if isinstance(payload, list) else payload
    config = source["Config"]
    host = source["HostConfig"]
    command = [args.docker, "run", "-d", "--name", args.name]
    if host.get("NetworkMode"):
        command += ["--network", host["NetworkMode"]]
    if host.get("IpcMode"):
        command += ["--ipc", host["IpcMode"]]
    if host.get("ShmSize"):
        command += ["--shm-size", str(host["ShmSize"])]
    for capability in host.get("CapAdd") or []:
        command += ["--cap-add", capability]
    for option in host.get("SecurityOpt") or []:
        command += ["--security-opt", option]
    for device in host.get("Devices") or []:
        value = f"{device['PathOnHost']}:{device['PathInContainer']}"
        if device.get("CgroupPermissions"):
            value += f":{device['CgroupPermissions']}"
        command += ["--device", value]
    for limit in host.get("Ulimits") or []:
        command += [
            "--ulimit",
            f"{limit['Name']}={limit['Soft']}:{limit['Hard']}",
        ]

    args.results.mkdir(parents=True, exist_ok=True)
    environment = {}
    for item in config.get("Env") or []:
        key, separator, value = item.partition("=")
        if separator:
            environment[key] = value
    source_paths = tuple(
        Path(entry)
        for entry in environment.get("PYTHONPATH", "").split(os.pathsep)
        if entry.startswith("/")
    )
    use_image_sglang = getattr(args, "use_image_sglang", False)
    dropped_source_roots: set[str] = set()
    for mount in source.get("Mounts", []):
        destination = mount["Destination"]
        if destination in {"/results", "/opt/netra"}:
            continue
        if use_image_sglang and any(
            path == Path(destination) or Path(destination) in path.parents
            for path in source_paths
        ):
            dropped_source_roots.add(destination.rstrip("/"))
            continue
        value = f"{mount['Source']}:{destination}"
        if not mount.get("RW", True):
            value += ":ro"
        command += ["--volume", value]
    command += ["--volume", f"{args.results.resolve()}:/results"]
    command += ["--volume", f"{args.bundle.resolve()}:/opt/netra:ro"]

    if use_image_sglang:
        environment.pop("PYTHONPATH", None)
        environment = {
            key: value
            for key, value in environment.items()
            if not any(
                value == root or value.startswith(f"{root}/")
                for root in dropped_source_roots
            )
        }
    environment["NETRA_BUNDLE"] = "/opt/netra"
    for key, value in sorted(environment.items()):
        command += ["--env", f"{key}={value}"]
    if config.get("WorkingDir"):
        command += ["--workdir", config["WorkingDir"]]
    if config.get("User"):
        command += ["--user", config["User"]]
    command.append(args.image)
    command.extend(config.get("Cmd") or [])
    return command


def main() -> int:
    args = _parser().parse_args()
    command = build_command(args)
    if args.dry_run:
        print(shlex.join(command))
        return 0
    result = subprocess.run(command, check=False)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
