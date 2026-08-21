from __future__ import annotations

import hashlib
import json
import shutil
from collections.abc import Mapping
from pathlib import Path
from typing import Any

from .backends.gfx950.codegen import emit_specialized_candidates
from .contracts import FixedKernelContract
from .errors import ValidationError
from .frontends import load_model
from .layouts import plan_scale_layout, plan_weight_layout
from .library import KernelLibrary
from .memory import BufferRequest, checked_mul, plan_buffers
from .planner import Plan, plan_graph
from .profiles import ShapeProfile, load_profile_registry
from .tactics import gfx950_registry
from .types import canonical_json, stable_hash, write_json


FORMAT_VERSION = "netra-engine-1"
COMPILER_VERSION = "0.2.0"


def _compiler_source_hash(repo_root: Path, template_hashes: dict[str, str]) -> str:
    # Hash the actually imported package, not an assumed checkout-relative
    # copy.  The logical labels deliberately exclude installation paths.
    package_root = Path(__file__).resolve().parent
    sources = {
        path.relative_to(package_root).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(package_root.rglob("*.py"))
    }
    return stable_hash({
        "compiler_version": COMPILER_VERSION,
        "python_sources": sources,
        "tactics": [tactic.to_dict() for tactic in gfx950_registry()],
        "templates": template_hashes,
    })


def _profile(repo_root: Path, target: str, name: str, tensor_parallel: int) -> ShapeProfile:
    profiles = {
        profile.name: profile
        for profile in load_profile_registry(repo_root, target, tensor_parallel)
    }
    if name not in profiles:
        raise ValidationError(f"unknown profile {name!r}; choose from {', '.join(sorted(profiles))}")
    return profiles[name]


def _memory_plan(plan: Plan) -> dict[str, object]:
    requests: list[BufferRequest] = []
    dtype_bytes = {
        "fp8_e4m3": 1,
        "fp16": 2,
        "bf16": 2,
        "fp32": 4,
        "int32": 4,
    }
    temporary_storage: dict[str, set[str]] = {}
    for operation in plan.graph.operations:
        artifact = operation.attributes.get("golden_artifact", {})
        for argument in artifact.get("arguments", ()):
            tensor = argument.get("tensor") or {}
            if tensor.get("role") != "temporary":
                continue
            name = str(tensor.get("name", argument["name"]))
            temporary_storage.setdefault(name, set()).add(
                str(argument.get("runtime_storage", "workspace"))
            )
        if operation.kind == "fixed_kernel":
            for argument in operation.attributes.get("arguments", ()):
                tensor_name = argument.get("tensor")
                if (
                    argument.get("kind") == "pointer"
                    and argument.get("source", "binding") == "binding"
                    and isinstance(tensor_name, str)
                ):
                    temporary_storage.setdefault(tensor_name, set()).add(
                        "caller_binding"
                    )
    for name, storage in temporary_storage.items():
        if len(storage) != 1:
            raise ValidationError(
                f"temporary tensor {name} has inconsistent runtime storage"
            )
        if next(iter(storage)) not in {"workspace", "caller_binding"}:
            raise ValidationError(
                f"temporary tensor {name} has unsupported runtime storage"
            )
    caller_bound_temporaries = {
        name for name, storage in temporary_storage.items()
        if storage == {"caller_binding"}
    }
    profile_guards = dict(plan.profile.guards)
    alias_views: dict[str, set[str]] = {}
    for tensor in plan.graph.tensors:
        if tensor.alias_of is not None:
            alias_views.setdefault(tensor.alias_of, set()).add(tensor.name)
    for tensor in plan.graph.tensors:
        if tensor.role != "temporary":
            continue
        if tensor.name in caller_bound_temporaries:
            continue
        resolved_shape: list[int] = []
        for dimension in tensor.shape:
            if isinstance(dimension, int):
                resolved_shape.append(dimension)
                continue
            guard = profile_guards.get(dimension.lower())
            if guard is None or guard.minimum != guard.maximum:
                raise ValidationError(
                    f"temporary tensor {tensor.name} dimension {dimension!r} "
                    "is not fixed by its profile"
                )
            resolved_shape.append(guard.minimum)
        storage_names = {tensor.name, *alias_views.get(tensor.name, ())}
        uses = [
            index for index, operation in enumerate(plan.graph.operations)
            if storage_names.intersection((*operation.inputs, *operation.outputs))
        ]
        if not uses:
            continue
        size = checked_mul(
            dtype_bytes[tensor.dtype.value],
            *resolved_shape,
        )
        requests.append(BufferRequest(
            tensor.name,
            size,
            256,
            min(uses),
            max(uses),
            graph_stable=True,
            alias_of=tensor.alias_of,
        ))
    for index, op in enumerate(plan.graph.operations):
        planned = plan.operations[index]
        workspace = getattr(planned.contract, "workspace", None)
        if workspace and workspace.bytes:
            requests.append(BufferRequest(
                f"{op.name}.workspace",
                workspace.bytes,
                workspace.alignment,
                index,
                index,
            ))
    return plan_buffers(tuple(requests))


def _layout_plan(plan: Plan) -> dict[str, object]:
    bindings = []
    for op in plan.graph.operations:
        if op.kind != "dense":
            continue
        checkpoint = op.attributes.get("checkpoint_layout", op.attributes["weight_layout"])
        binding = plan_weight_layout(
            op.inputs[2],
            checkpoint,
            op.attributes["weight_layout"],
            checkpoint_tensors=tuple(op.attributes.get("checkpoint_tensors", ())),
        ).to_dict()
        checkpoint_scales = tuple(op.attributes.get("checkpoint_scale_tensors", ()))
        if checkpoint_scales:
            binding["scale"] = plan_scale_layout(
                op.inputs[3],
                checkpoint_scales,
                checkpoint_dtype=str(
                    op.attributes.get("checkpoint_scale_dtype", "bf16")
                ),
                kernel_dtype=str(op.attributes.get("kernel_scale_dtype", "fp32")),
                block=tuple(int(value) for value in op.attributes["weight_scale_block"]),
            ).to_dict()
        bindings.append(binding)
    return {"format": "netra-layout-plan-1", "bindings": sorted(bindings, key=lambda b: b["tensor"])}


def _operation_dependencies(plan: Plan) -> tuple[tuple[int, ...], ...]:
    """Derive deterministic RAW/WAR/WAW dependencies from typed tensor edges."""

    storage_name = {
        tensor.name: tensor.alias_of or tensor.name for tensor in plan.graph.tensors
    }
    last_writer: dict[str, int] = {}
    readers: dict[str, set[int]] = {}
    dependencies: list[tuple[int, ...]] = []
    for index, operation in enumerate(plan.graph.operations):
        current: set[int] = set()
        input_storage = tuple(storage_name[name] for name in operation.inputs)
        output_storage = tuple(storage_name[name] for name in operation.outputs)
        for name in input_storage:
            writer = last_writer.get(name)
            if writer is not None:
                current.add(writer)
        for name in output_storage:
            writer = last_writer.get(name)
            if writer is not None:
                current.add(writer)
            current.update(readers.get(name, ()))
        dependencies.append(tuple(sorted(current)))
        for name in input_storage:
            readers.setdefault(name, set()).add(index)
        for name in output_storage:
            last_writer[name] = index
            readers[name] = set()
    return tuple(dependencies)


def _operation_records(plan: Plan, memory_plan: dict[str, object]) -> list[dict[str, Any]]:
    offsets = {
        str(buffer["name"]): int(buffer["offset"])
        for buffer in memory_plan["buffers"]
        if buffer["offset"] is not None
    }
    records = []
    for position, planned in enumerate(plan.operations):
        contract = planned.contract
        tactic = planned.tactic
        operation_workspace = f"{planned.operation.name}.workspace"
        workspace_offset = None
        workspace = getattr(contract, "workspace", None)
        launch = getattr(contract, "launch", None)
        if workspace and workspace.bytes:
            if operation_workspace not in offsets:
                raise ValidationError(
                    f"missing planned workspace allocation for {planned.operation.name}"
                )
            workspace_offset = offsets[operation_workspace]
        record = {
            "index": position, "name": planned.operation.name,
            "kind": planned.operation.kind,
            "contract_id": contract.stable_id if contract else None,
            "tactic": tactic.name if tactic else None,
            "maturity": tactic.maturity.value if tactic else None,
            "execution": planned.execution,
            "kernel_symbol": (
                getattr(contract, "symbol", getattr(tactic, "symbol", None))
                if contract and planned.execution == "kernel"
                else None
            ),
            "launch": ({"grid": list(launch.grid), "block": list(launch.block),
                        "lds_bytes": launch.lds_bytes,
                        "dynamic_lds_bytes": launch.dynamic_lds_bytes}
                       if launch else None),
            "workspace_offset": workspace_offset,
            "fallback": planned.fallback,
            "bindings": {"inputs": list(planned.operation.inputs), "outputs": list(planned.operation.outputs)},
            "artifact_kind": tactic.artifact_kind if tactic else None,
        }
        if tactic and tactic.artifact_kind == "golden_external_hsaco":
            artifact = planned.operation.attributes["golden_artifact"]
            record["hsaco"] = f"hsaco/{artifact['hsaco_name']}"
            record["hsaco_sha256"] = artifact["hsaco_sha256"]
            record["kernarg_size"] = artifact["kernarg_size"]
            arguments = []
            for argument in artifact["arguments"]:
                emitted = {
                    key: value for key, value in argument.items()
                    if key not in {"tensor", "runtime_storage"}
                }
                tensor = argument.get("tensor")
                tensor_name = str(tensor.get("name", argument["name"])) if tensor else None
                if (
                    argument["kind"] == "pointer"
                    and argument.get("runtime_storage") == "caller_binding"
                ):
                    emitted["source"] = "binding"
                elif argument["kind"] == "pointer" and tensor_name in offsets:
                    emitted["source"] = "workspace"
                    emitted["workspace_offset"] = offsets[tensor_name]
                elif argument["kind"] == "pointer":
                    emitted["source"] = "binding"
                arguments.append(emitted)
            record["arguments"] = arguments
        if isinstance(contract, FixedKernelContract):
            raw_arguments = planned.operation.attributes.get("arguments")
            if not isinstance(raw_arguments, (list, tuple)) or not raw_arguments:
                raise ValidationError(
                    f"fixed kernel {planned.operation.name} requires typed arguments"
                )
            arguments = []
            for index, argument in enumerate(raw_arguments):
                if not isinstance(argument, Mapping):
                    raise ValidationError(
                        f"fixed kernel {planned.operation.name} argument {index} must be an object"
                    )
                kind = argument.get("kind")
                if kind not in {"pointer", "u32_constant"}:
                    raise ValidationError(
                        f"fixed kernel {planned.operation.name} argument {index} has invalid kind"
                    )
                emitted = dict(argument)
                if kind == "pointer":
                    source = emitted.setdefault("source", "binding")
                    if source == "workspace":
                        if not contract.workspace.bytes or workspace_offset is None:
                            raise ValidationError(
                                f"fixed kernel {planned.operation.name} has a workspace "
                                "argument without a workspace contract"
                            )
                        relative_offset = emitted.get("workspace_offset", 0)
                        if (
                            not isinstance(relative_offset, int)
                            or isinstance(relative_offset, bool)
                            or relative_offset < 0
                            or relative_offset >= contract.workspace.bytes
                        ):
                            raise ValidationError(
                                f"fixed kernel {planned.operation.name} workspace argument "
                                "offset is outside its contract"
                            )
                        emitted["workspace_offset"] = workspace_offset + relative_offset
                    elif source != "binding":
                        raise ValidationError(
                            f"fixed kernel {planned.operation.name} has unsupported "
                            f"pointer source {source!r}"
                        )
                elif not isinstance(emitted.get("value"), int):
                    raise ValidationError(
                        f"fixed kernel {planned.operation.name} argument {index} lacks u32 value"
                    )
                arguments.append(emitted)
            record["arguments"] = arguments
            record["kernarg_size"] = contract.kernarg_size
            record["hsaco"] = f"hsaco/{contract.symbol}.hsaco"
        if planned.operation.kind == "server_fallback":
            record["external_contract"] = dict(planned.operation.attributes)
        return_record = record
        records.append(return_record)
    return records


def _materialize_golden_artifacts(
    operations: list[dict[str, Any]], output: Path, artifact_root: Path | None
) -> list[dict[str, Any]]:
    artifacts: dict[str, dict[str, Any]] = {}
    for operation in operations:
        if operation.get("artifact_kind") != "golden_external_hsaco":
            continue
        if "hsaco" not in operation:
            continue
        relative = str(operation["hsaco"])
        expected = str(operation["hsaco_sha256"])
        existing = artifacts.get(relative)
        if existing and existing["sha256"] != expected:
            raise ValidationError(f"conflicting hashes for golden artifact {relative}")
        artifacts[relative] = {
            "path": relative,
            "sha256": expected,
            "materialized": False,
        }
    if artifact_root is None:
        return [artifacts[key] for key in sorted(artifacts)]
    for relative, record in artifacts.items():
        source = artifact_root / Path(relative).name
        if not source.is_file():
            raise ValidationError(f"golden artifact is missing: {source}")
        actual = hashlib.sha256(source.read_bytes()).hexdigest()
        if actual != record["sha256"]:
            raise ValidationError(
                f"golden artifact hash mismatch for {source}: expected "
                f"{record['sha256']}, got {actual}"
            )
        destination = output / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        record["materialized"] = True
    return [artifacts[key] for key in sorted(artifacts)]


def compile_engine(model_path: Path, target: str, profile_name: str, output: Path,
                   *, checkpoint_hash: str | None = None,
                   allow_experimental: bool = False,
                   golden_artifact_root: Path | None = None,
                   library_root: Path | None = None) -> dict[str, Any]:
    if target != "gfx950":
        raise ValidationError("the first Netra engine backend is gfx950 only")
    library = KernelLibrary.discover(library_root, anchors=(model_path,))
    repo_root = library.root
    graph, model = load_model(model_path, library=library)
    tensor_parallel = int(model.get("configuration", {}).get("tensor_parallel", 1))
    profile = _profile(repo_root, target, profile_name, tensor_parallel)
    plan = plan_graph(
        graph,
        profile,
        target,
        allow_experimental=allow_experimental,
        library_root=repo_root,
    )
    output.mkdir(parents=True, exist_ok=True)
    candidates = emit_specialized_candidates(plan, output, repo_root)

    contract_map = {
        p.contract.stable_id: p.contract.to_dict() for p in plan.operations if p.contract is not None
    }
    memory_plan = _memory_plan(plan)
    operations = _operation_records(plan, memory_plan)
    golden_artifacts = _materialize_golden_artifacts(
        operations, output, golden_artifact_root
    )
    layout_plan = _layout_plan(plan)
    dependencies = _operation_dependencies(plan)
    graph_recipe = {
        "format": "netra-graph-recipe-1", "profile": profile.name,
        "capture_at_initialization": True,
        "portable_serialized_hip_graph": False,
        "operations": [
            {"index": op["index"], "depends_on": list(dependencies[op["index"]]),
             "execution": op["execution"], "kernel_symbol": op["kernel_symbol"],
             "launch": op["launch"], "bindings": op["bindings"],
             "workspace_offset": op["workspace_offset"]}
            for op in operations
        ],
    }
    selected_symbols = {op["kernel_symbol"] for op in operations if op["kernel_symbol"]}
    candidate_symbols = {c["symbol"] for c in candidates if c["symbol"]}
    symbols = {
        "selected": sorted(selected_symbols),
        "candidates": sorted(candidate_symbols - selected_symbols),
    }
    validation_plan = {
        "format": "netra-validation-plan-1",
        "static": "pending", "cross_assembly": "not_run", "hardware": "not_run",
        "real_checkpoint_correctness": "not_run", "graph_replay": "not_run",
        "matched_server_ab": "not_run", "promotion_eligible": False,
        "candidates": candidates,
        "golden_artifacts": golden_artifacts,
        "commands": [
            "bash tools/compiler/build_engine_gfx950.sh ENGINE_DIR",
            "python3 -m netra_compiler.cli validate --engine ENGINE_DIR --static --library-root LIBRARY_ROOT",
        ],
    }
    explanation = {
        "profile": profile.to_dict(),
        "operations": [{"name": p.operation.name, "selected": p.tactic.name if p.tactic else None,
                        "execution": p.execution, "fallback": p.fallback,
                        "candidates": list(p.explanation)} for p in plan.operations],
    }
    model_hash = stable_hash(model)
    configuration = model.get("configuration", {})
    guard_fields = (
        "architecture", "model_type", "checkpoint", "checkpoint_repository",
        "checkpoint_revision", "checkpoint_config_sha256", "hidden_size",
        "intermediate_size", "layers", "layer_types", "full_attention_interval",
        "num_attention_heads", "num_key_value_heads", "head_dim",
        "linear_num_key_heads", "linear_key_head_dim", "linear_num_value_heads",
        "linear_value_head_dim", "linear_conv_kernel_dim", "vocab_size",
        "max_position_embeddings", "attention_output_gate", "mtp_layers",
        "quantization_method", "quantization_format",
        "activation_quantization", "checkpoint_activation_scheme",
        "weight_scale_block", "checkpoint_scale_dtype",
        "kernel_scale_dtype", "tensor_parallel", "data_parallel_workers",
        "deployment_graph_mode", "cuda_graph_batch_sizes",
        "piecewise_cuda_graph_tokens", "speculative_algorithm",
        "speculative_num_steps", "speculative_eagle_topk",
        "speculative_num_draft_tokens", "dflash_enabled", "dflash_block_size",
        "dflash_checkpoint", "dflash_checkpoint_repository",
        "dflash_checkpoint_revision", "dflash_checkpoint_config_sha256",
        "dflash_checkpoint_weights_sha256", "dflash_draft_window_size",
        "dflash_mamba_cache_steps", "mamba_ssm_dtype",
        "required_environment",
    )
    deployment_guards = {
        key: configuration[key] for key in guard_fields if key in configuration
    }
    template_hashes = {
        relative: digest
        for candidate in candidates
        for relative, digest in candidate.get("template_files", {}).items()
    }
    source_hash = _compiler_source_hash(repo_root, template_hashes)
    engine = {
        "format_version": FORMAT_VERSION, "target": target, "wave_size": 64,
        "required_rocm": {"minimum": "7.0", "code_object_version": 6},
        "model_configuration_hash": model_hash, "checkpoint_hash": checkpoint_hash,
        "deployment_guards": deployment_guards,
        "tensor_parallel": tensor_parallel, "profiles": [profile.to_dict()],
        "operations": operations,
        "selected_tactics": sorted({op["tactic"] for op in operations if op["tactic"]}),
        "kernel_symbols": symbols["selected"],
        "workspace_bytes": memory_plan["workspace_bytes"],
        "fallbacks": {op["name"]: op["fallback"] for op in operations if op["execution"] != "kernel"},
        "layout_plan": "layout_plan.json", "graph_recipe": "graph_recipe.json",
        "memory_plan": "memory_plan.json",
        "validation_status": "static_only_not_promoted",
        "compiler": {"name": "netra-compiler", "version": COMPILER_VERSION,
                     "source_hash": source_hash},
        "golden_artifacts": golden_artifacts,
        "artifact_files": ["contracts.json", "graph.json", "graph_recipe.json", "memory_plan.json",
                           "layout_plan.json", "symbols.json", "validation_plan.json", "explain.json"],
    }
    engine["engine_id"] = "ne_" + stable_hash(engine)[:24]
    write_json(output / "contracts.json", {"format": "netra-contract-set-1", "contracts": [contract_map[k] for k in sorted(contract_map)]})
    write_json(output / "graph.json", graph.to_dict())
    write_json(output / "graph_recipe.json", graph_recipe)
    write_json(output / "memory_plan.json", memory_plan)
    write_json(output / "layout_plan.json", layout_plan)
    write_json(output / "symbols.json", symbols)
    write_json(output / "validation_plan.json", validation_plan)
    write_json(output / "explain.json", explanation)
    write_json(output / "engine.json", engine)
    return engine


def semantic_file_hashes(engine_dir: Path) -> dict[str, str]:
    result = {}
    for path in sorted(engine_dir.rglob("*")):
        if path.is_file() and path.suffix not in {".hsaco", ".o", ".dis"}:
            result[path.relative_to(engine_dir).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result
