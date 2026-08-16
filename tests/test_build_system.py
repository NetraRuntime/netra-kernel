from __future__ import annotations

import pathlib
import subprocess


REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
BUILD_DIR = REPO_ROOT / "tools" / "build"
PRODUCTION_BUILDER = BUILD_DIR / "build_production.sh"
PRODUCTION_PROFILE = BUILD_DIR / "profiles" / "gfx950_qwen36_dflash.sh"
COMPONENT_REGISTRY = BUILD_DIR / "components" / "gfx950"
GDN_VERIFY_COMPONENT = (
    COMPONENT_REGISTRY / "gdn-verify-b64-t12-h16-hv32-k128-v128-k0.sh"
)
VARIANT_LIBRARY = BUILD_DIR / "lib" / "gdn_variants.sh"


def _bash(command: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", "-c", command],
        check=False,
        text=True,
        capture_output=True,
    )


def test_production_bundle_has_one_ordered_component_list() -> None:
    result = subprocess.run(
        [str(PRODUCTION_BUILDER), "gfx950-qwen36-dflash", "list"],
        check=True,
        text=True,
        capture_output=True,
    )
    assert result.stdout.splitlines() == [
        "moe-decode-fp8-e4m3-h2048-i512-top9-block128-aiter",
        "router-bf16-k2048-n256",
        "attention-verify-gqa8-d256-fp8kv-m16",
        "gdn-verify-b64-t12-h16-hv32-k128-v128-k0",
        "gdn-replay-b64-t12-h16-hv32-k128-v128",
    ]


def test_production_gdn_contract_pins_promoted_settings() -> None:
    source = GDN_VERIFY_COMPONENT.read_text()
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
        "netra_gdn_core_variant_id packed-pair-interleaved m12; "
        "netra_gdn_core_variant_id fused-packed-exact m16; "
        "netra_gdn_precompute_variant_id triton-exact"
    )
    result = _bash(command)
    assert result.returncode == 0
    assert result.stdout.splitlines() == ["17", "13", "7"]

    rejected = _bash(
        f"source {VARIANT_LIBRARY}; "
        "netra_gdn_core_variant_id packed-pair-interleaved m16"
    )
    assert rejected.returncode == 2
    assert "not valid for M16" in rejected.stderr


def test_model_profile_is_data_only_and_uses_generic_contracts() -> None:
    source = PRODUCTION_PROFILE.read_text()
    assert "NETRA_PROFILE_COMPONENT_REGISTRY=gfx950" in source
    assert "NETRA_PROFILE_OUTPUT_NAMESPACE=gfx950-qwen36" in source
    assert "build_gfx950" not in source
    assert "netra_profile_build_component" not in source

    contracts = subprocess.run(
        [str(PRODUCTION_BUILDER), "gfx950-qwen36-dflash", "contracts"],
        check=True,
        text=True,
        capture_output=True,
    ).stdout.splitlines()
    assert contracts
    assert all("qwen" not in contract for contract in contracts)
    profile_contracts = subprocess.run(
        [str(PRODUCTION_BUILDER), "gfx950-qwen36-dflash", "list"],
        check=True,
        text=True,
        capture_output=True,
    ).stdout.splitlines()
    assert set(profile_contracts) <= set(contracts)
    assert not (BUILD_DIR / "build_gfx950_qwen36_production.sh").exists()
    assert not (BUILD_DIR / "lib" / "qwen36_gdn_variants.sh").exists()


def test_component_registry_is_drop_in_and_model_neutral() -> None:
    component_files = sorted(COMPONENT_REGISTRY.glob("*.sh"))
    assert component_files
    assert all("qwen" not in path.name for path in component_files)
    registered_contracts = subprocess.run(
        [str(PRODUCTION_BUILDER), "gfx950-qwen36-dflash", "contracts"],
        check=True,
        text=True,
        capture_output=True,
    ).stdout.splitlines()
    assert [path.stem for path in component_files] == registered_contracts
    for component_file in component_files:
        source = component_file.read_text()
        assert source.count("netra_register_component") == 1
    assert not (BUILD_DIR / "components" / "gfx950.sh").exists()

    retired_builders = [
        "build_gfx950_qwen36_fp8_raw.sh",
        "build_gfx950_qwen36_router_bf16.sh",
        "build_gfx950_qwen36_extend_attention_gqa8_fp8kv.sh",
        "build_gfx950_qwen36_gdn_verify_m12_batched.sh",
        "build_gfx950_qwen36_gdn_state_replay_m12.sh",
    ]
    assert not any((BUILD_DIR / filename).exists() for filename in retired_builders)


def test_gfx950_build_boilerplate_uses_shared_implementations() -> None:
    consumers = [
        "build_gfx950_moe_decode_fp8_e4m3_h2048_i512_top9_block128_aiter.sh",
        "build_gfx950_router_bf16_k2048_n256.sh",
        "build_gfx950_gdn_verify_b64_t12_h16_hv32_k128_v128_k0.sh",
        "build_gfx950_gdn_replay_b64_t12_h16_hv32_k128_v128.sh",
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
