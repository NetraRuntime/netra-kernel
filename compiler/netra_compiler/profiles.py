from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

from .errors import ValidationError


@dataclass(frozen=True)
class DimensionGuard:
    minimum: int
    maximum: int

    def __post_init__(self) -> None:
        if self.minimum < 0 or self.maximum < self.minimum:
            raise ValidationError("invalid bounded dimension guard")

    @classmethod
    def exact(cls, value: int) -> "DimensionGuard":
        return cls(value, value)

    def matches(self, value: int) -> bool:
        return self.minimum <= value <= self.maximum

    def to_dict(self) -> dict[str, int]:
        return {"min": self.minimum, "max": self.maximum}


@dataclass(frozen=True)
class ShapeProfile:
    name: str
    guards: tuple[tuple[str, DimensionGuard], ...]
    quantization: str = "fp8_block128"
    tensor_parallel: int = 1
    priority: int = 0

    def __post_init__(self) -> None:
        if self.tensor_parallel <= 0:
            raise ValidationError("tensor parallel degree must be positive")
        if len({k for k, _ in self.guards}) != len(self.guards):
            raise ValidationError("duplicate profile guard")

    def matches(self, dimensions: Mapping[str, int], *, quantization: str,
                tensor_parallel: int) -> bool:
        return (
            quantization == self.quantization
            and tensor_parallel == self.tensor_parallel
            and all(k in dimensions and guard.matches(dimensions[k]) for k, guard in self.guards)
        )

    def to_dict(self) -> dict[str, object]:
        return {
            "name": self.name,
            "guards": {k: v.to_dict() for k, v in self.guards},
            "quantization": self.quantization,
            "tensor_parallel": self.tensor_parallel,
            "priority": self.priority,
        }


@dataclass(frozen=True)
class ProfileSelection:
    supported: bool
    profile: ShapeProfile | None
    reason: str


def select_profile(profiles: tuple[ShapeProfile, ...], dimensions: Mapping[str, int],
                   *, quantization: str, tensor_parallel: int) -> ProfileSelection:
    ordered = sorted(profiles, key=lambda p: (-p.priority, p.name))
    for profile in ordered:
        if profile.matches(dimensions, quantization=quantization,
                           tensor_parallel=tensor_parallel):
            return ProfileSelection(True, profile, "all exact/bounded guards matched")
    return ProfileSelection(False, None, "unsupported contract/profile; framework fallback required")


def standard_profiles(tensor_parallel: int = 1) -> tuple[ShapeProfile, ...]:
    """Compatibility helper for callers that do not own a repository registry."""
    common = (("batch", DimensionGuard(1, 64)), ("sequence", DimensionGuard(0, 1 << 20)))
    return (
        ShapeProfile("decode_m1", (("m", DimensionGuard.exact(1)),) + common,
                     tensor_parallel=tensor_parallel, priority=30),
        ShapeProfile("verify_m12", (("m", DimensionGuard.exact(12)),) + common,
                     tensor_parallel=tensor_parallel, priority=25),
        ShapeProfile("verify_m16", (("m", DimensionGuard.exact(16)),) + common,
                     tensor_parallel=tensor_parallel, priority=20),
        ShapeProfile("small_prefill_m64", (("m", DimensionGuard.exact(64)),) + common,
                     tensor_parallel=tensor_parallel, priority=10),
    )


def load_profile_registry(
    library_root: Path, target: str, tensor_parallel: int
) -> tuple[ShapeProfile, ...]:
    """Load deterministic target profiles and bind deployment-local constraints.

    Profiles are data, not frontend logic. ``tensor_parallel: deployment`` keeps
    a reusable shape profile tied to the exact TP degree recorded by the model
    manifest instead of silently accepting a different deployment.
    """
    profile_root = library_root / "manifests" / target / "profiles"
    if not profile_root.is_dir():
        raise ValidationError(f"missing profile registry for target {target!r}")
    profiles: list[ShapeProfile] = []
    for path in sorted(profile_root.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise ValidationError(f"cannot read profile manifest {path}: {exc}") from exc
        if data.get("format") != "netra-profile-1":
            raise ValidationError(f"invalid profile format in {path}")
        raw_guards = data.get("guards")
        if not isinstance(raw_guards, Mapping) or not raw_guards:
            raise ValidationError(f"profile {path} must define nonempty guards")
        guards: list[tuple[str, DimensionGuard]] = []
        for name, bounds in sorted(raw_guards.items()):
            if not isinstance(name, str) or not isinstance(bounds, Mapping):
                raise ValidationError(f"invalid guard in profile {path}")
            try:
                guard = DimensionGuard(int(bounds["min"]), int(bounds["max"]))
            except (KeyError, TypeError, ValueError) as exc:
                raise ValidationError(f"invalid bounds for guard {name!r} in {path}") from exc
            guards.append((name, guard))
        raw_tp = data.get("tensor_parallel", "deployment")
        if raw_tp == "deployment":
            bound_tp = tensor_parallel
        elif isinstance(raw_tp, int) and not isinstance(raw_tp, bool):
            bound_tp = raw_tp
        else:
            raise ValidationError(f"invalid tensor_parallel constraint in {path}")
        profile = ShapeProfile(
            name=str(data.get("name", "")),
            guards=tuple(guards),
            quantization=str(data.get("quantization", "")),
            tensor_parallel=bound_tp,
            priority=int(data.get("priority", 0)),
        )
        profiles.append(profile)
    if not profiles:
        raise ValidationError(f"profile registry for target {target!r} is empty")
    names = [profile.name for profile in profiles]
    if len(names) != len(set(names)):
        raise ValidationError(f"duplicate profile name in target {target!r}")
    return tuple(sorted(profiles, key=lambda profile: profile.name))
