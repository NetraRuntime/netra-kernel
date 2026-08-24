from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .backends.gfx950.build import build_sources
from .backends.gfx950.catalog import load_fixed_tactic_catalog
from .engine import compile_engine
from .errors import NetraCompilerError
from .tactics import gfx950_registry
from .types import canonical_json
from .validation import validate_engine_directory


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="netra_compiler", description="Compile fixed-contract Netra engines")
    sub = parser.add_subparsers(dest="command", required=True)
    tactics = sub.add_parser("list-tactics"); tactics.add_argument("--target", required=True)
    tactics.add_argument("--library-root", type=Path)
    compile_p = sub.add_parser("compile")
    compile_p.add_argument("--model", type=Path, required=True); compile_p.add_argument("--target", required=True)
    compile_p.add_argument("--profile", required=True); compile_p.add_argument("--output", type=Path, required=True)
    compile_p.add_argument("--checkpoint-hash"); compile_p.add_argument("--allow-experimental", action="store_true")
    compile_p.add_argument("--library-root", type=Path)
    compile_p.add_argument(
        "--golden-artifact-root", type=Path,
        help="directory containing accepted HSACOs; hashes must match the manifest",
    )
    for name in ("inspect", "explain"):
        p = sub.add_parser(name); p.add_argument("--engine", type=Path, required=True)
    validate = sub.add_parser("validate"); validate.add_argument("--engine", type=Path, required=True)
    validate.add_argument("--library-root", type=Path)
    validate.add_argument("--static", action="store_true"); validate.add_argument("--build", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "list-tactics":
            if args.target != "gfx950": raise NetraCompilerError("only gfx950 is registered")
            from .library import KernelLibrary
            repo_root = KernelLibrary.discover(args.library_root).root
            registered = [t.to_dict() for t in gfx950_registry()]
            registered.extend(t.to_dict() for t in load_fixed_tactic_catalog(repo_root, args.target))
            registered.sort(key=lambda tactic: tactic["name"])
            print(canonical_json({"target": args.target, "tactics": registered}), end="")
        elif args.command == "compile":
            engine = compile_engine(args.model, args.target, args.profile, args.output,
                                    checkpoint_hash=args.checkpoint_hash,
                                    allow_experimental=args.allow_experimental,
                                    golden_artifact_root=args.golden_artifact_root,
                                    library_root=args.library_root)
            print(canonical_json({"engine": str(args.output), "engine_id": engine["engine_id"],
                                  "validation_status": engine["validation_status"]}), end="")
        elif args.command == "inspect":
            print((args.engine / "engine.json").read_text(encoding="utf-8"), end="")
        elif args.command == "explain":
            print((args.engine / "explain.json").read_text(encoding="utf-8"), end="")
        elif args.command == "validate":
            result = validate_engine_directory(args.engine, library_root=args.library_root)
            if args.build: result["built"] = build_sources(args.engine)
            print(canonical_json(result), end="")
        return 0
    except (NetraCompilerError, OSError, ValueError) as exc:
        print(f"netra_compiler: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
