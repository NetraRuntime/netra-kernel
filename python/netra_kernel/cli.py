"""Command line interface for packaging and auditing SGLang deployments."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

from netra_kernel.bundle import (
    BUNDLE_ENV,
    BundleError,
    activate_bundle,
    available_profiles,
    build_bundle,
    load_bundle,
    shlex_quote,
    validate_bundle,
)
from netra_kernel.sglang.compat import probe
from netra_kernel.sglang.integration import IntegrationError, integrate
from netra_kernel.source import build_source, source_environment, validate_source


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="netra-sglang")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("profiles", help="list packaged deployment profiles")
    bundle = sub.add_parser("bundle", help="create a relocatable, hash-locked bundle")
    bundle.add_argument("--profile", required=True)
    bundle.add_argument("--artifact-root", action="append", type=Path, required=True)
    bundle.add_argument("--output", type=Path, required=True)
    bundle.add_argument("--copy", action="store_true", help="copy instead of hardlinking")
    bundle.add_argument("--runtime-root", default="/opt/netra")
    validate = sub.add_parser("validate", help="verify all files in a bundle")
    validate.add_argument("bundle", type=Path)
    doctor = sub.add_parser("doctor", help="audit SGLang and an optional bundle")
    doctor.add_argument("--bundle", type=Path)
    doctor.add_argument("--json", action="store_true")
    env = sub.add_parser("env", help="print a bundle environment")
    env.add_argument("bundle", type=Path)
    env.add_argument("--format", choices=("shell", "docker"), default="shell")
    run = sub.add_parser("run", help="run a command with a bundle activated")
    run.add_argument("--bundle", type=Path, required=True)
    run.add_argument("argv", nargs=argparse.REMAINDER)
    integration = sub.add_parser(
        "integrate", help="preflight or apply a source overlay to base SGLang"
    )
    integration.add_argument("--sglang-root", type=Path, required=True)
    integration.add_argument("--target", choices=("gfx1151",), default="gfx1151")
    integration.add_argument(
        "--apply", action="store_true", help="apply after the disposable-worktree preflight"
    )
    source = sub.add_parser(
        "source", help="materialize an accepted SGLang source snapshot"
    )
    source.add_argument("--profile", required=True)
    source.add_argument("--output", type=Path, required=True)
    source_validate = sub.add_parser(
        "source-validate", help="verify a materialized SGLang source snapshot"
    )
    source_validate.add_argument("source", type=Path)
    source_env = sub.add_parser(
        "source-env", help="print the environment for an accepted source snapshot"
    )
    source_env.add_argument("source", type=Path)
    source_env.add_argument("--format", choices=("shell", "docker"), default="shell")
    return parser


def _doctor(bundle_path: Path | None) -> dict:
    required: tuple[str, ...] = ()
    expected_source_snapshot = None
    bundle_result = None
    if bundle_path is not None:
        payload = load_bundle(bundle_path)
        required = tuple(payload.get("required_sglang_modules", ()))
        expected_source_snapshot = payload.get("sglang_source_snapshot")
        bundle_result = validate_bundle(bundle_path)
    compatibility = probe(required)
    source_result = None
    if compatibility.source_root is not None:
        source_root = Path(compatibility.source_root).parent
        if (source_root / "netra-source.json").is_file():
            source_result = validate_source(source_root)
            if (
                expected_source_snapshot is not None
                and source_result.get("snapshot") != expected_source_snapshot
            ):
                source_result["ok"] = False
                source_result["errors"].append("bundle/source snapshot mismatch")
    return {
        "ok": (
            compatibility.usable
            and (bundle_result is None or bundle_result["ok"])
            and (source_result is None or source_result["ok"])
        ),
        "sglang": compatibility.to_dict(),
        "bundle": bundle_result,
        "source": source_result,
    }


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "profiles":
            print("\n".join(available_profiles()))
        elif args.command == "bundle":
            path = build_bundle(
                args.profile,
                args.artifact_root,
                args.output,
                mode="copy" if args.copy else "hardlink",
                runtime_root=args.runtime_root,
            )
            print(path)
        elif args.command == "validate":
            result = validate_bundle(args.bundle)
            print(json.dumps(result, indent=2, sort_keys=True))
            return 0 if result["ok"] else 2
        elif args.command == "doctor":
            result = _doctor(args.bundle)
            if args.json:
                print(json.dumps(result, indent=2, sort_keys=True))
            else:
                state = "ready" if result["ok"] else "not ready"
                print(f"Netra SGLang: {state}")
                print(json.dumps(result, indent=2, sort_keys=True))
            return 0 if result["ok"] else 2
        elif args.command == "env":
            payload = load_bundle(args.bundle)
            root = args.bundle.expanduser().resolve()
            runtime_root = payload.get("runtime_root", "/opt/netra")
            if args.format == "docker":
                print(f"{BUNDLE_ENV}={runtime_root}")
                for key, value in sorted(payload["environment"].items()):
                    print(f"{key}={value}")
            else:
                print(f"export {BUNDLE_ENV}={shlex_quote(str(root))}")
                for key, value in sorted(payload["environment"].items()):
                    host_value = value.replace(runtime_root, str(root))
                    print(f"export {key}={shlex_quote(host_value)}")
        elif args.command == "run":
            command = args.argv[1:] if args.argv[:1] == ["--"] else args.argv
            if not command:
                raise BundleError("run requires a command after --")
            activate_bundle(args.bundle)
            return subprocess.run(command, env=os.environ.copy()).returncode
        elif args.command == "integrate":
            report = integrate(args.sglang_root, apply=args.apply)
            print(json.dumps(report.to_dict(), indent=2, sort_keys=True))
        elif args.command == "source":
            print(build_source(args.profile, args.output))
        elif args.command == "source-validate":
            result = validate_source(args.source)
            print(json.dumps(result, indent=2, sort_keys=True))
            return 0 if result["ok"] else 2
        elif args.command == "source-env":
            environment = source_environment(args.source)
            for key, value in environment.items():
                if args.format == "docker":
                    print(f"{key}={value}")
                elif key == "PYTHONPATH":
                    print(
                        f"export {key}={shlex_quote(value)}"
                        "${PYTHONPATH:+:${PYTHONPATH}}"
                    )
                else:
                    print(f"export {key}={shlex_quote(value)}")
        return 0
    except (BundleError, IntegrationError, OSError, ValueError) as error:
        print(f"netra-sglang: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
