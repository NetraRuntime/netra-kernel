#!/usr/bin/env python3
"""Relaunch a recorded Docker container with isolated GPU/result overrides.

The input is the JSON emitted by ``docker inspect``.  The script deliberately
preserves the recorded image ID, environment, mounts, devices, IPC/network
mode, and command while allowing only the fields needed for an isolated
benchmark replay to change.
"""

from __future__ import annotations

import argparse
import json
import shlex
import subprocess
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inspect_json_positional", type=Path, nargs="?")
    parser.add_argument("--inspect-json", type=Path)
    parser.add_argument("--name", required=True)
    parser.add_argument("--gpu", type=int, required=True)
    parser.add_argument("--results", "--results-dir", dest="results", type=Path, required=True)
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--nccl-port", type=int)
    parser.add_argument(
        "--env-override",
        action="append",
        default=[],
        metavar="KEY=VALUE",
    )
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    if args.inspect_json is not None and args.inspect_json_positional is not None:
        parser.error("provide the inspect JSON positionally or with --inspect-json, not both")
    args.inspect_json = args.inspect_json or args.inspect_json_positional
    if args.inspect_json is None:
        parser.error("an inspect JSON is required")
    return args


def replace_option(command: list[str], option: str, value: str) -> None:
    try:
        index = command.index(option)
    except ValueError as exc:
        raise ValueError(f"recorded command has no {option}") from exc
    if index + 1 >= len(command):
        raise ValueError(f"recorded command has no value after {option}")
    command[index + 1] = value


def main() -> None:
    args = parse_args()
    if args.gpu < 0:
        raise ValueError("--gpu must be non-negative")
    if not 1 <= args.port <= 65535:
        raise ValueError("--port must be in [1, 65535]")
    args.results.mkdir(parents=True, exist_ok=True)

    records = json.loads(args.inspect_json.read_text(encoding="utf-8"))
    if not isinstance(records, list) or len(records) != 1:
        raise ValueError("expected one docker-inspect record")
    record = records[0]
    config = record["Config"]
    host = record["HostConfig"]

    env: dict[str, str] = {}
    for item in config.get("Env") or []:
        key, separator, value = item.partition("=")
        if not separator:
            raise ValueError(f"malformed recorded environment entry: {item!r}")
        env[key] = value
    # ROCR performs the physical-device isolation and remaps the selected GPU
    # to logical device zero inside the container.  HIP must therefore select
    # logical zero; setting both variables to the physical index hides every
    # accelerator for indices greater than zero.
    env["HIP_VISIBLE_DEVICES"] = "0"
    env["ROCR_VISIBLE_DEVICES"] = str(args.gpu)
    for item in args.env_override:
        key, separator, value = item.partition("=")
        if not separator or not key:
            raise ValueError(f"malformed --env-override: {item!r}")
        env[key] = value

    command = list(config.get("Cmd") or [])
    replace_option(command, "--port", str(args.port))
    if args.nccl_port is not None:
        if not 1 <= args.nccl_port <= 65535:
            raise ValueError("--nccl-port must be in [1, 65535]")
        replace_option(command, "--nccl-port", str(args.nccl_port))

    docker = ["docker", "run", "--detach", "--name", args.name]
    if host.get("NetworkMode"):
        docker.extend(("--network", host["NetworkMode"]))
    if host.get("IpcMode"):
        docker.extend(("--ipc", host["IpcMode"]))
    if host.get("ShmSize"):
        docker.extend(("--shm-size", str(host["ShmSize"])))
    for capability in host.get("CapAdd") or []:
        docker.extend(("--cap-add", capability))
    for capability in host.get("CapDrop") or []:
        docker.extend(("--cap-drop", capability))
    for security_option in host.get("SecurityOpt") or []:
        docker.extend(("--security-opt", security_option))
    if host.get("Runtime") and host["Runtime"] != "runc":
        docker.extend(("--runtime", host["Runtime"]))
    if host.get("Privileged"):
        docker.append("--privileged")
    if host.get("ReadonlyRootfs"):
        docker.append("--read-only")
    for group in host.get("GroupAdd") or []:
        docker.extend(("--group-add", str(group)))
    for limit in host.get("Ulimits") or []:
        docker.extend(
            (
                "--ulimit",
                f'{limit["Name"]}={limit["Soft"]}:{limit["Hard"]}',
            )
        )
    for device in host.get("Devices") or []:
        value = f'{device["PathOnHost"]}:{device["PathInContainer"]}'
        if device.get("CgroupPermissions"):
            value += f':{device["CgroupPermissions"]}'
        docker.extend(("--device", value))
    for bind in host.get("Binds") or []:
        fields = bind.split(":")
        if len(fields) >= 2 and fields[1] == "/results":
            fields[0] = str(args.results.resolve())
            bind = ":".join(fields)
        docker.extend(("--volume", bind))
    for key, value in sorted(env.items()):
        docker.extend(("--env", f"{key}={value}"))
    if config.get("WorkingDir"):
        docker.extend(("--workdir", config["WorkingDir"]))
    docker.append(record.get("Image") or config["Image"])
    docker.extend(command)

    printable = list(docker)
    for index, item in enumerate(printable[:-1]):
        if item != "--env":
            continue
        key, separator, _ = printable[index + 1].partition("=")
        if separator and any(word in key.upper() for word in ("TOKEN", "PASSWORD", "SECRET", "API_KEY")):
            printable[index + 1] = f"{key}=<redacted>"
    print(shlex.join(printable))
    if args.execute:
        subprocess.run(docker, check=True)


if __name__ == "__main__":
    main()
