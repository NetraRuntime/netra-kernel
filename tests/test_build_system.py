from __future__ import annotations

import pathlib
import subprocess


REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
BUILD_DIR = REPO_ROOT / "tools" / "build"
PRODUCTION_BUILDER = BUILD_DIR / "build_gfx950_qwen36_production.sh"
VARIANT_LIBRARY = BUILD_DIR / "lib" / "qwen36_gdn_variants.sh"


def _bash(command: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", "-c", command],
        check=False,
        text=True,
        capture_output=True,
    )


def test_production_bundle_has_one_ordered_component_list() -> None:
    result = subprocess.run(
        [str(PRODUCTION_BUILDER), "list"],
        check=True,
        text=True,
        capture_output=True,
    )
    assert result.stdout.splitlines() == [
        "fp8-decode",
        "router-bf16",
        "target-attention-gqa8-fp8kv",
        "gdn-verify-m12-k0",
        "gdn-state-replay-m12",
    ]


def test_production_gdn_contract_pins_promoted_settings() -> None:
    source = PRODUCTION_BUILDER.read_text()
    required = [
        "NETRA_GDN_CORE_VARIANT=packed-pair-interleaved",
        "NETRA_GDN_PRECOMPUTE_VARIANT=triton-exact",
        "NETRA_GDN_K0_NO_INTERMEDIATE=1",
        "NETRA_GDN_WAVES_PER_WORKGROUP=1",
        "NETRA_GDN_SHARE_QK=1",
        "NETRA_GDN_DYNAMIC_WAVEGROUPS=1",
    ]
    assert all(setting in source for setting in required)


def test_gdn_variant_ids_are_centralized_and_contract_checked() -> None:
    command = (
        f"source {VARIANT_LIBRARY}; "
        "netra_qwen36_gdn_core_variant_id packed-pair-interleaved m12; "
        "netra_qwen36_gdn_core_variant_id fused-packed-exact m16; "
        "netra_qwen36_gdn_precompute_variant_id triton-exact"
    )
    result = _bash(command)
    assert result.returncode == 0
    assert result.stdout.splitlines() == ["17", "13", "7"]

    rejected = _bash(
        f"source {VARIANT_LIBRARY}; "
        "netra_qwen36_gdn_core_variant_id packed-pair-interleaved m16"
    )
    assert rejected.returncode == 2
    assert "not valid for M16" in rejected.stderr


def test_gfx950_build_boilerplate_uses_shared_implementations() -> None:
    consumers = [
        "build_gfx950_qwen36_fp8_raw.sh",
        "build_gfx950_qwen36_router_bf16.sh",
        "build_gfx950_qwen36_gdn_verify_m12_batched.sh",
        "build_gfx950_qwen36_gdn_state_replay_m12.sh",
        "build_gfx950_qwen36_gdn_verify_m16.sh",
        "build_gfx950_qwen36_full_attention_verify_m16.sh",
    ]
    for filename in consumers:
        source = (BUILD_DIR / filename).read_text()
        assert 'source "${script_dir}/lib/gfx950_assembly.sh"' in source
        assert "netra_gfx950_build_" in source
        assert "build_kernel()" not in source


def test_generated_argmax_artifacts_do_not_live_at_repository_root() -> None:
    generated = [
        REPO_ROOT / "libqwen36_argmax_f32_bridge.so",
        REPO_ROOT / "qwen36_argmax_f32_gfx950",
        REPO_ROOT / "qwen36_argmax_f32_gfx950.hsaco",
        REPO_ROOT / "qwen36_argmax_f32_gfx950.o",
        REPO_ROOT / "sha256sums.txt",
    ]
    assert not any(path.exists() for path in generated)
