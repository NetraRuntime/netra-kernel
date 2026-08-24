"""Framework-neutral Netra deployment CLI."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

from .bundle import (
    BUNDLE_ENV,
    BundleError,
    available_profiles,
    build_bundle,
    integration_configuration,
    integration_environment,
    load_bundle,
    shlex_quote,
    validate_bundle,
)
from .integrations import (
    IntegrationError,
    activate_integration,
    available_integrations,
    check_integration,
)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="netra-kernel")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("profiles", help="list accepted deployment profiles")
    sub.add_parser("integrations", help="list installed inference-engine adapters")
    bundle = sub.add_parser("bundle", help="create a relocatable hash-locked bundle")
    bundle.add_argument("--profile", required=True)
    bundle.add_argument("--artifact-root", action="append", type=Path, required=True)
    bundle.add_argument("--output", type=Path, required=True)
    bundle.add_argument("--copy", action="store_true")
    bundle.add_argument("--runtime-root", default="/opt/netra")
    validate = sub.add_parser("validate", help="verify every artifact digest")
    validate.add_argument("bundle", type=Path)
    check = sub.add_parser("check", help="check one engine adapter")
    check.add_argument("bundle", type=Path)
    check.add_argument("--integration", required=True)
    env = sub.add_parser("env", help="print one adapter's environment")
    env.add_argument("bundle", type=Path)
    env.add_argument("--integration", required=True)
    env.add_argument("--format", choices=("shell", "docker"), default="shell")
    run = sub.add_parser("run", help="run a command with one adapter activated")
    run.add_argument("--bundle", type=Path, required=True)
    run.add_argument("--integration", required=True)
    run.add_argument("argv", nargs=argparse.REMAINDER)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "profiles":
            print("\n".join(available_profiles()))
        elif args.command == "integrations":
            print("\n".join(available_integrations()))
        elif args.command == "bundle":
            print(build_bundle(
                args.profile, args.artifact_root, args.output,
                mode="copy" if args.copy else "hardlink",
                runtime_root=args.runtime_root,
            ))
        elif args.command == "validate":
            result = validate_bundle(args.bundle)
            print(json.dumps(result, indent=2, sort_keys=True))
            return 0 if result["ok"] else 2
        elif args.command == "check":
            result = check_integration(args.bundle, args.integration)
            print(json.dumps(result, indent=2, sort_keys=True))
            return 0 if result["ok"] else 2
        elif args.command == "env":
            payload = load_bundle(args.bundle)
            root = args.bundle.expanduser().resolve()
            environment = integration_environment(root, args.integration)
            if args.format == "docker":
                print(f"{BUNDLE_ENV}={payload.get('runtime_root', '/opt/netra')}")
                configuration = integration_configuration(root, args.integration)
                for key, value in sorted(configuration.get("environment", {}).items()):
                    print(f"{key}={value}")
            else:
                print(f"export {BUNDLE_ENV}={shlex_quote(str(root))}")
                for key, value in sorted(environment.items()):
                    print(f"export {key}={shlex_quote(value)}")
        elif args.command == "run":
            command = args.argv[1:] if args.argv[:1] == ["--"] else args.argv
            if not command:
                raise BundleError("run requires a command after --")
            activate_integration(args.bundle, args.integration, overwrite=True)
            return subprocess.run(command, env=os.environ.copy()).returncode
        return 0
    except (BundleError, IntegrationError, OSError, ValueError) as error:
        print(f"netra-kernel: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
