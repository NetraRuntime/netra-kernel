#!/usr/bin/env python3
"""Build the curated, reviewable tables for the gfx950 Qwen3.6 retrospective.

This is deliberately separate from collect_gfx950_qwen36_retrospective.py.
The collector is exhaustive and mechanical; this file records human-reviewed
contract equivalence and decision semantics. Empty timing fields mean that the
underlying raw artifact was not available in this worktree, never zero.
"""

from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/retrospectives/gfx950-qwen36-20260821"
DATA = OUT / "data"


def write_csv(name: str, fields: list[str], rows: list[dict[str, object]]) -> None:
    path = OUT / name
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(
            f, fieldnames=fields, extrasaction="raise", lineterminator="\n"
        )
        writer.writeheader()
        writer.writerows(rows)


competitors = [
    dict(implementation="Netra", revision="netra-kernel:9c5940cceaecb00a26f157a4894d1a8edad4e0d4", target="gfx950", eligible_scope="Exact manifest-bound operations", attempt="Historical binaries and tracked summaries inventoried; current rebuild not run", result="historically_measured_current_host_unavailable", limitation="No /dev/kfd and no ROCm toolchain in analysis environment", adapter_contract_effect="none", evidence="data/environment-manifest.json"),
    dict(implementation="SGLang default", revision="a688682f4baf224ed0cf2d5ceb4d053a0fa01dfc", target="ROCm", eligible_scope="Framework serving baseline when exact launch configuration and checkpoint match", attempt="Pinned upstream; no current serving run", result="eligible_not_run", limitation="Locked historical container and checkpoint data unavailable", adapter_contract_effect="Configuration differences can change graphs, cache and speculative acceptance", evidence="https://github.com/sgl-project/sglang/tree/a688682f4baf224ed0cf2d5ceb4d053a0fa01dfc"),
    dict(implementation="AITER", revision="c7033306f348181d4470a85c40f9af253911dab7", target="gfx950", eligible_scope="CK/CK Tile/assembly GEMM, MoE and attention contracts selected by SGLang", attempt="285 historical dense candidates screened; tracked selected-kernel results retained", result="historically_measured_current_host_unavailable", limitation="Exact historical AITER revision is container-locked, not the current upstream pin", adapter_contract_effect="Must retain FP8 blockscale, preshuffle and cache layouts", evidence="docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md;https://github.com/ROCm/aiter/tree/c7033306f348181d4470a85c40f9af253911dab7"),
    dict(implementation="Composable Kernel / CK Tile", revision="3e86341ccbc2822b663b944e528f28e7bd49c91c", target="gfx950", eligible_scope="Blockscale GEMM and selected fused operations", attempt="Historical candidates exercised through AITER; direct current build not run", result="eligible_not_run_current", limitation="Repository moved into rocm-libraries; exact dispatch wrapper matters", adapter_contract_effect="Weight preshuffle or scale conversion must be included", evidence="https://github.com/ROCm/composable_kernel/tree/3e86341ccbc2822b663b944e528f28e7bd49c91c"),
    dict(implementation="hipBLASLt", revision="3a609b06926c8227e753b62087555e1f435bf2d4", target="gfx950", eligible_scope="Dense BF16 and supported FP8 matmul contracts", attempt="Historical BF16 and FP8 candidates measured; current isolated run not possible", result="historically_measured_current_host_unavailable", limitation="Does not cover recurrent attention, sampling, cache attention, or fused non-GEMM ABIs", adapter_contract_effect="Preshuffle/scale setup is integrated cost", evidence="https://github.com/ROCm/hipBLASLt/tree/3a609b06926c8227e753b62087555e1f435bf2d4"),
    dict(implementation="Triton", revision="1d2da15d2b1f1dfe8f64ddcc2acfe530ff406ffd", target="ROCm/gfx950", eligible_scope="Repository Triton oracles, attention, convolution and verification kernels", attempt="Historical exact comparisons retained; current compile not run", result="historically_measured_current_host_unavailable", limitation="Compiler/runtime revision and graph behavior must match", adapter_contract_effect="Layout/cache adapters are part of integrated cost", evidence="https://github.com/triton-lang/triton/tree/1d2da15d2b1f1dfe8f64ddcc2acfe530ff406ffd"),
    dict(implementation="PyTorch/ROCm", revision="19c6d265207cd17c6392a1f92217c54add2cb39b", target="ROCm", eligible_scope="Oracle and unfused primitive baselines", attempt="Historical argmax and framework operators measured; current run not possible", result="historically_measured_current_host_unavailable", limitation="Primitive composition may not share the fused numerical/layout contract", adapter_contract_effect="All casts, cats and synchronizations must be charged", evidence="https://github.com/pytorch/pytorch/tree/19c6d265207cd17c6392a1f92217c54add2cb39b"),
    dict(implementation="FlashAttention ROCm CK", revision="0251105a2fb19d2957484b7f023cd8c115286ced", target="MI200/MI250/MI300/MI355 class", eligible_scope="BF16/FP16 attention with supported head sizes", attempt="Support/docs inspected; no current compile", result="conditionally_eligible_not_run", limitation="Exact paged native-FP8 KV cache and Qwen D256 verification ABI not established equivalent", adapter_contract_effect="KV dequantization/repacking would change contract and must be timed", evidence="https://github.com/Dao-AILab/flash-attention/tree/0251105a2fb19d2957484b7f023cd8c115286ced"),
    dict(implementation="FlashInfer", revision="4927c0e15cb63a2abb6df09019c39a172222f0eb", target="CUDA", eligible_scope="none on ROCm in pinned official implementation", attempt="Official source and README inspected", result="ineligible", limitation="No official AMD/ROCm backend in pinned revision", adapter_contract_effect="A CUDA-only result cannot be an MI350X comparison", evidence="https://github.com/flashinfer-ai/flashinfer/tree/4927c0e15cb63a2abb6df09019c39a172222f0eb"),
    dict(implementation="HipKittens", revision="c26e33b67b0e7af05c20eb99b6173a5661cebc93", target="CDNA3/CDNA4/gfx950", eligible_scope="BF16 GEMM primitives and attention examples", attempt="Official source/docs inspected; no current compile", result="partially_eligible_not_run", limitation="Published attention quickstart covers D64/D128, not exact Qwen D256 paged FP8-KV ABI", adapter_contract_effect="A new D256/cache adapter is a new implementation, not drop-in baseline", evidence="https://github.com/HazyResearch/HipKittens/tree/c26e33b67b0e7af05c20eb99b6173a5661cebc93"),
    dict(implementation="rocWMMA", revision="97562d33167f5dda32fa319cc5b4f62815bdd9e3", target="gfx950", eligible_scope="Matrix-fragment primitive for a new implementation", attempt="Official support inspected; no operation-complete implementation found", result="building_block_not_comparable", limitation="Primitive library does not supply identical end-to-end Qwen operation ABIs", adapter_contract_effect="Would require authoring and validating a new kernel", evidence="https://github.com/ROCm/rocWMMA/tree/97562d33167f5dda32fa319cc5b4f62815bdd9e3"),
]


comparisons = [
    # model, operation, shape, contract, graph, impl, rev, correctness, kernel, integrated, defaultspeed, competitorspeed, e2e, ci, status, evidence, availability
    ("35B","FP8 SiLU multiply + group quant","9 routes,N512","FP32 gate/up input; BF16 intermediate rounding; E4M3 per-128; FP32 scale","isolated eager harness","Netra raw fused assembly","9c5940c","0/4608 FP8 byte and 0/36 scale mismatch","2.782 us median","", "1.99x vs deployed-equivalent two-kernel harness", "1.99x vs measured non-Netra composition", "component of accepted M1 pipeline","","accepted component","docs/notes/gfx950-qwen36-fp8-results.json","five tracked run aggregates; per-iteration samples external"),
    ("35B","FP8 SiLU multiply + group quant","9 routes,N512","same","isolated eager harness","deployed-equivalent two HIP kernels","historical locked stack","reference","5.523 us median","","1.0x","1.0x","not evaluated alone","","eligible baseline","docs/notes/gfx950-qwen36-fp8-results.json","five tracked run aggregates"),
    ("35B","MoE M1 raw graph pipeline","M1,K2048,I512,top9","FP8 block128; BF16 output","piecewise replay","Netra three-stage raw pipeline","9c5940c","exact under recorded gates","","", "1.0694x", "", "148.014 to 158.288 output tok/s","","accepted graph path","docs/notes/gfx950-qwen36-fp8-results.json","tracked aggregate"),
    ("35B","shared-gate/skip-sort path","decode M1","BF16 router; exact route metadata","full/piecewise","Netra bridge","9c5940c","passed recorded shadow gates","","","","","+27.31% full; +27.08% piecewise output throughput","","accepted","docs/notes/gfx950-qwen36-fp8-kernels.md","tracked summary"),
    ("35B","router BF16","M1,K2048,N256","BF16 row-major","eager/full","Netra raw assembly","9c5940c","passed recorded checkpoint validation","6.24 us","","","","eager 25.797 to 48.984; full 156.335 to 195.491 output tok/s","","accepted full; piecewise rejected","docs/notes/gfx950-qwen36-fp8-kernels.md","tracked summary"),
    ("35B","dense FP8 decode","M1,K2048,N4096","E4M3 blockscale/preshuffled","graph","Netra assembly candidate","historical","exact","10.00 us","","1.792x vs AITER","1.792x","wall -4.51%; generation -4.73%","","rejected","docs/notes/gfx950-qwen36-fp8-kernels.md","tracked summary"),
    ("35B","dense FP8 decode","M1,K2048,N4096","same","graph","AITER","historical locked stack","reference","17.92 us","","1.0x","1.0x","production retained","","production winner","docs/notes/gfx950-qwen36-fp8-kernels.md","tracked summary"),
    ("35B","argmax","M16,N248320","contiguous FP32; PyTorch GreaterOrNan","full graph","Netra two-stage assembly","9c5940c","197/197 exact + shadow exact","7.949 us mean","12.306 us serving trace","7.083x raw; 6.058x trace","7.083x","verification-call latency 9.456968 to 9.392771 ms","","accepted exact scope","docs/notes/gfx950-qwen36-argmax-f32-results.json","tracked aggregate"),
    ("35B","argmax","M16,N248320","same","full graph","PyTorch reduction","historical locked stack","reference","56.304 us mean","74.550 us trace","1.0x","1.0x","control","","baseline","docs/notes/gfx950-qwen36-argmax-f32-results.json","tracked aggregate"),
    ("35B","GDN verification core","M16,H32,K128,V128,BV16","BF16 I/O; FP32 state/accum","piecewise replay","Netra assembly","9c5940c","bit exact all layers/replay","24.361 us combined","","","","short latency +2.32%; verify calls +3.52-3.69%","","accepted","docs/notes/gfx950-qwen36-gdn-verify-m16-results.json","tracked aggregate"),
    ("35B","GDN K0 core","M12,H32,K128,V128,BV16","BF16 I/O; FP32 state","graph replay","Netra assembly","9c5940c","recorded exact gate passed","119.1815 us","","1.5659x vs Triton","1.5659x","4445.627 vs reverse-order 4107.910 output tok/s","","accepted","docs/notes/gfx950-qwen36-gdn-m12-k0.md","tracked aggregate"),
    ("35B","GDN K0 core","same","same","graph replay","Triton","historical locked stack","reference","186.6225 us","","1.0x","1.0x","control","","baseline","docs/notes/gfx950-qwen36-gdn-m12-k0.md","tracked aggregate"),
    ("35B","GDN causal convolution","M12,QKV8192,width4","BF16 row-major","graph replay","Netra assembly","9c5940c","bit exact","21.700 us","","2.067x vs Triton","2.067x","accepted incremental path","","accepted","docs/notes/gfx950-qwen36-gdn-causal-conv-m12.md","tracked aggregate"),
    ("35B","GDN causal convolution","same","same","graph replay","Triton","historical locked stack","reference","44.860 us","","1.0x","1.0x","control","","baseline","docs/notes/gfx950-qwen36-gdn-causal-conv-m12.md","tracked aggregate"),
    ("35B","extend attention GQA4","M12,GQA4,D256,FP8 KV","BF16 Q/O; native E4M3 cache","graph replay","Netra assembly","9c5940c","recorded validation passed","145.442 us","","1.441x vs Triton","1.441x","control 3998.26; raw 4019.30; production 4075.41 tok/s","","accepted","docs/notes/gfx950-qwen36-extend-attention-gqa4.md","tracked aggregate"),
    ("35B","extend attention GQA4","same","same","graph replay","Triton","historical locked stack","reference","209.562 us","","1.0x","1.0x","control","","baseline","docs/notes/gfx950-qwen36-extend-attention-gqa4.md","tracked aggregate"),
    ("35B","target attention GQA8","M756,GQA8,D256,FP8 KV","BF16 Q/O; native E4M3 cache","piecewise replay","Netra assembly","9c5940c","28/3096576 BF16 mismatch; max abs .0009765625; cosine 1","84.081 us median","","2.209x vs Triton","2.209x","+8.406% output throughput","","accepted","docs/notes/gfx950-qwen36-target-attention-gqa8-fp8kv.md","tracked aggregate"),
    ("35B","target attention GQA8","same","same","piecewise replay","Triton","historical locked stack","reference","185.722 us median","","1.0x","1.0x","control","","baseline","docs/notes/gfx950-qwen36-target-attention-gqa8-fp8kv.md","tracked aggregate"),
    ("35B","MoE exact producer/reducer","M768,257 experts,top9,K2048,I512","FP8 producer; FP16 split-K2 workspace; BF16 out","piecewise replay","Netra modular assembly pair","9c5940c","byte-identical .text after modularization","","","","","five-process mean 11431.108 output tok/s; accuracy .9525","","accepted locked pair","docs/notes/gfx950-template-modularity-audit.md","tracked aggregate; no matched default in retained source"),
    ("35B","MoE non-M768 fallback","M8192,257 experts,top9","FP8 block128; BF16 out","piecewise","AITER FMoE block64","historical locked stack","exact","isolated +24.4% vs prior configuration","","","","matched serving +0.045%","","retained fallback; no promotion claim","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md","tracked summary"),
    ("27B","GDN QKVZ+conv","T8,QKV10240,QKVZ16384,width4","BF16 I/O","full replay","Netra assembly","9c5940c","bitwise eager/replay B1/32/128/256","33.941 us","","1.3005x vs Triton","1.3005x","3307.72 to 3206.81 FP32 / 3220.31 BF16 tok/s","","verified but rejected promotion","docs/notes/gfx950-qwen36-27b-fp8.md","tracked aggregate; raw external"),
    ("27B","GDN QKVZ+conv","same","same","full replay","Triton","historical locked stack","reference","44.141 us","","1.0x","1.0x","production retained","","production winner","docs/notes/gfx950-qwen36-27b-fp8.md","tracked aggregate"),
    ("27B","GDN BF16 recurrent state","T8,H48,K128,V128,BV16","BF16 state/storage; FP32 accumulation","full replay","Netra assembly core+replay","9c5940c","bitwise vs BF16-pool reference","","","","","five-process 3429.02 vs FP32 3287.81 tok/s; state 9.07 vs 18.14 GB","","accepted opt-in","docs/notes/gfx950-qwen36-27b-fp8.md","tracked aggregate; raw external"),
    ("27B","C192 serving profile","GSM8K 1319 x 10 processes","TP1/DP1,dFlash8,BF16 state,natural EOS","full graph","Netra locked C192","9c5940c","96.59% numeric accuracy; all requests complete","","","","","6381.33 vs C128 5710.44 tok/s; +11.75% [10.41,13.09]","95% paired CI 10.41-13.09%","accepted throughput profile","docs/notes/gfx950-qwen36-27b-fp8.md","tracked aggregate; raw external"),
    ("27B","prefill projection views","M8192 QKV materialization","BF16 exact views","eager prefill","Netra view candidate","historical removed","bitwise direct/conv/state/graph/replay","","","","","warmed wall +2.36%; natural C192 +0.026%","","rejected and removed","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md","tracked summary; raw external"),
    ("27B","dense M768 QKVZ","M768,K5120,N16384","FP8 blockscale/preshuffled","full graph","Netra candidate","historical removed","recorded correctness passed","110.121 us","","1.048x vs 115.441 control","","serving 7000.74 to 6552.87 tok/s (-6.40%)","","rejected","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md","tracked summary"),
    ("27B","GDN conv prefill","M8192,QKV10240,width4","BF16 row-major","eager","Netra candidate","historical removed","recorded correctness passed","90.321 us","","1.496x vs 135.161 control","","long serving -5.60%","","rejected","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md","tracked summary"),
]

comparison_fields = ["model","operation","shape","dtype_layout","graph_mode","implementation","version_commit","correctness_result","kernel_latency","integrated_latency","speedup_over_default_sglang","speedup_over_fastest_eligible_non_netra","end_to_end_serving_effect","confidence_interval","acceptance_status","evidence_path","evidence_availability"]
comparison_rows = [dict(zip(comparison_fields, row)) for row in comparisons]


samples = []
for state, values, source in [
    ("27B FP32-state C128", [3246.51,3257.92,3309.78,3316.49,3308.34], "docs/notes/gfx950-qwen36-27b-fp8.md"),
    ("27B BF16-state C128", [3375.76,3425.77,3445.78,3457.64,3440.14], "docs/notes/gfx950-qwen36-27b-fp8.md"),
]:
    for i, value in enumerate(values, 1):
        samples.append(dict(model="27B", experiment=state, metric="output_tokens_per_second", unit="tok/s", process=i, order="fresh process; original arm order not retained", value=value, raw_artifact_available="false", evidence=source))

aggregates = [
    dict(model="27B",experiment="FP32-state C128 five-process",metric="output_tokens_per_second",unit="tok/s",n=5,mean=3287.81,median="",minimum=3246.51,maximum=3316.49,p5="",p95="",stddev=32.88,cv="",confidence_interval="",correctness="mean acceptance about 3.1",source="docs/notes/gfx950-qwen36-27b-fp8.md",availability="tracked aggregate and five values"),
    dict(model="27B",experiment="BF16-state C128 five-process",metric="output_tokens_per_second",unit="tok/s",n=5,mean=3429.02,median="",minimum=3375.76,maximum=3457.64,p5="",p95="",stddev=31.90,cv="",confidence_interval="",correctness="1920/1920 requests passed; mean acceptance 3.1464",source="docs/notes/gfx950-qwen36-27b-fp8.md",availability="tracked aggregate and five values"),
    dict(model="27B",experiment="C128/C192 paired GSM8K",metric="relative_output_throughput",unit="percent",n=5,mean=11.75,median="",minimum="",maximum="",p5="",p95="",stddev="",cv="",confidence_interval="95% 10.41 to 13.09",correctness="13190 requests; accuracy interval crossed zero",source="docs/notes/gfx950-qwen36-27b-fp8.md",availability="tracked aggregate; raw summary external"),
    dict(model="27B",experiment="locked C192 five-process",metric="output_tokens_per_second",unit="tok/s",n=5,mean=6500.89,median="",minimum=6430.39,maximum=6562.83,p5="",p95="",stddev=52.07,cv="",confidence_interval="",correctness="6595 requests; 96.25% numeric accuracy",source="docs/notes/gfx950-qwen36-27b-fp8.md",availability="tracked aggregate and five values in prose"),
    dict(model="35B",experiment="locked modular M768 five-process",metric="output_tokens_per_second",unit="tok/s",n=5,mean=11431.1078,median="",minimum=11386.687,maximum=11474.461,p5="",p95="",stddev=42.012,cv="",confidence_interval="",correctness="accuracy .9525",source="docs/compiler/gfx950-moe-prefill-m768-equivalence-20260821.json",availability="tracked aggregate; process samples external"),
    dict(model="35B",experiment="Netra C64 in cross-system comparison",metric="output_tokens_per_second",unit="tok/s",n="",mean=3284.8467,median="",minimum="",maximum="",p5="",p95="",stddev="",cv="",confidence_interval="",correctness="480/512 outputs differ across engines; not a quality-equivalent kernel baseline",source="netra-server:docs/mi350x-gfx950/notes/20260802_c64_apples_to_apples.json",availability="tracked aggregate; graph/dFlash configurations differ"),
]

rejected = [
    ("35B","raw M1 MoE eager integration","raw kernels individually correct/fast","serving -6.01%","Python/dispatch overhead outside graph erased kernel gain","rejected","docs/notes/gfx950-qwen36-fp8-results.json"),
    ("35B","router BF16 piecewise path","eager/full gains","control correctness failed","upstream control/graph semantics differed","rejected; full path retained","docs/notes/gfx950-qwen36-fp8-kernels.md"),
    ("35B","dense M1 assembly","10.00 vs AITER 17.92 us","wall -4.51%; generation -4.73%","launch/graph/dataflow interaction dominated isolated GEMM","rejected","docs/notes/gfx950-qwen36-fp8-kernels.md"),
    ("35B","Gemma add-RMSNorm assembly","raw/AITER latency ratio .98016","serving throughput -0.1639%","sub-threshold isolated win did not survive serving noise/gate","rejected","netra-server:docs/mi350x-gfx950/notes/20260730_gemma_add_rmsnorm_raw_negative.md"),
    ("35B","full-state GDN M12 variant","correct","wrote about 805 MiB and slowed serving","state traffic dominated","rejected","docs/notes/gfx950-qwen36-gdn-m12-k0.md"),
    ("35B","FMoE block64 fallback","isolated +24.4%","serving +0.045%","operation was not decisive at natural C64 / integration costs remained","rejected promotion","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md"),
    ("35B","historical raw M64 MoE pipeline","236.423 us","AITER deployed 226.843 us","raw pipeline 4.22% slower","rejected","netra-server:docs/mi350x-gfx950/notes/20260801_qwen36_fmoe_m64_paired_raw_pipeline.json"),
    ("35B","target attention two-head grouping","correctness/performance experiment","inferior retained candidate","less KV reuse than four-query-head grouping","superseded","docs/notes/gfx950-qwen36-target-attention-gqa8-fp8kv.md"),
    ("35B","broad M<=16 attention dispatch","fast on target","incorrectly selected extension-only piecewise prefill","dispatch predicate violated semantic contract","rejected","docs/notes/gfx950-qwen36-target-attention-gqa8-fp8kv.md"),
    ("27B","QKVZ+conv T8 assembly","33.941 vs 44.141 us","serving -1.05/-1.45% acceptance-normalized","fusion changed downstream timing/dataflow despite exact replay","verified; promotion rejected","docs/notes/gfx950-qwen36-27b-fp8.md"),
    ("27B","projection-view elimination","warmed long request +2.36%","natural C192 +0.026%","48 cats removed but natural workload bottleneck mix masked gain","rejected and code removed","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md"),
    ("27B","dense M768 QKVZ assembly","115.441 to 110.121 us","serving -6.40%","local kernel win disrupted end-to-end schedule/critical path","rejected","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md"),
    ("27B","M8192 causal convolution","135.161 to 90.321 us","long serving -5.60%","layout/materialization and pipeline interactions dominated","rejected","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md"),
    ("27B","frozen dense verification assembly","correct","matched ABBA -0.94%","no serving benefit","rejected","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md"),
    ("27B/35B","custom AITER compute-source tiles","not run","architecture-ineligible","source family did not target gfx950 exact environment","ineligible","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md"),
    ("both","compare_scalar 338.8 ms attribution","profiler event","excluded","host synchronization overlapped later same-stream kernels; not GPU work attribution","measurement artifact","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md"),
]

winners = [
    ("35B","M1 MoE graph pipeline","M1,K2048,I512,top9","Netra raw three-stage pipeline","accepted","serving-gated","docs/notes/gfx950-qwen36-fp8-results.json"),
    ("35B","dense FP8 decode","M1,K2048,N4096","AITER","production retained","Netra faster only in isolation","docs/notes/gfx950-qwen36-fp8-kernels.md"),
    ("35B","argmax","M16,N248320 FP32","Netra two-stage assembly","accepted","exact","docs/notes/gfx950-qwen36-argmax-f32-accepted.md"),
    ("35B","GDN verification","M16,H32,K/V128","Netra assembly","accepted","exact/replay","docs/notes/gfx950-qwen36-gdn-verify-m16-results.json"),
    ("35B","GDN K0 core","M12,H32,K/V128,BV16","Netra assembly","accepted","serving-gated","docs/notes/gfx950-qwen36-gdn-m12-k0.md"),
    ("35B","GDN causal convolution","M12,QKV8192,width4","Netra assembly","accepted","exact","docs/notes/gfx950-qwen36-gdn-causal-conv-m12.md"),
    ("35B","extend attention","M12,GQA4,D256,FP8 KV","Netra assembly","accepted","serving-gated","docs/notes/gfx950-qwen36-extend-attention-gqa4.md"),
    ("35B","target attention","M756,GQA8,D256,FP8 KV","Netra assembly","accepted","bounded tolerance","docs/notes/gfx950-qwen36-target-attention-gqa8-fp8kv.md"),
    ("35B","MoE exact producer/reducer","M768","Netra modular assembly pair","accepted locked","byte-locked","docs/notes/gfx950-template-modularity-audit.md"),
    ("35B","MoE non-M768 fallback","M8192","AITER FMoE block64","production retained","serving-flat candidate","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md"),
    ("35B","dense long prefill","M8192 five contracts","AITER selected CK/CK Tile","production retained","285-candidate screen","docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md"),
    ("27B","GDN QKVZ+conv","T8,QKV10240","Triton/framework","production retained","Netra micro-win failed serving","docs/notes/gfx950-qwen36-27b-fp8.md"),
    ("27B","GDN recurrent state","T8,H48,BV16","Netra BF16-state core/replay","accepted opt-in","memory+serving gated","docs/notes/gfx950-qwen36-27b-fp8.md"),
    ("27B","dense projections","observed M1/M16/M80/M256/M768/M3840/M8192","AITER exact selected CK/CK Tile","production retained","model-neutral table","docs/notes/gfx950-qwen36-27b-fp8.md"),
    ("27B","C192 serving","TP1/DP1,dFlash8,BF16 state","Netra locked C192 profile","throughput winner","latency tradeoff explicit","docs/notes/gfx950-qwen36-27b-fp8.md"),
]

coverage = []
for model, required in {
    "27B": ["input16","input1K","input8K","M8","M12","C1","C128","C192","C256","TP1/DP1","dFlash8","BF16-state","eager","graph-capture","graph-replay"],
    "35B": ["input16","input1K","input8K","M16","M768","natural-C64","TP1/DP1","dFlash12","piecewise-capture","piecewise-replay","non-M768-fallback"],
}.items():
    documented = {"27B": {"input16","input8K","M8","M12","C128","C192","C256","TP1/DP1","dFlash8","BF16-state","eager","graph-capture","graph-replay"}, "35B": {"input16","input8K","M16","M768","natural-C64","TP1/DP1","dFlash12","piecewise-capture","piecewise-replay","non-M768-fallback"}}[model]
    for case in required:
        status = "historical_tracked_summary" if case in documented else "missing"
        coverage.append(dict(model=model,required_case=case,current_campaign_execution="not_run_no_gfx950",historical_evidence=status,raw_samples_available="false",gap="Current host has no /dev/kfd or ROCm; /data artifacts absent" if status != "missing" else "No retained evidence found and current host cannot execute",evidence="docs/notes/gfx950-qwen36-prefill-profile-2026-08-21.md;docs/notes/gfx950-qwen36-27b-fp8.md"))

prior_art = [
    ("Numerical/layout contract as reuse key","Established compiler/library practice","MLIR Linalg makes payload semantics and layout transformations explicit; vendor libraries dispatch on exact descriptors","Netra's model-neutral manifest keys are an engineering combination","https://mlir.llvm.org/docs/Dialects/Linalg/"),
    ("Profile/tactic selection","Established industry practice","TensorRT optimization profiles and tactics select implementations for bounded shapes","Evidence-locked gfx950 catalog is an internal implementation","https://docs.nvidia.com/deeplearning/tensorrt/latest/performance/optimization.html"),
    ("Byte-locked deployable engines","Established reproducibility practice","TensorRT engines serialize selected tactics and are platform/version scoped","Netra adds source/text/workspace hash checks tailored to raw AMD kernels","https://docs.nvidia.com/deeplearning/tensorrt/latest/inference-library/capabilities.html"),
    ("Graph-safe fixed ABI","Established graph practice","HIP graphs capture and replay fixed work while avoiding repeated launch construction","Netra's no-allocation/no-lookup launch bridge is a disciplined application","https://rocm.docs.amd.com/projects/HIP/en/latest/how-to/hip_runtime_api/hipgraph.html"),
    ("IO-aware attention","Established research","FlashAttention identifies memory traffic as the dominant attention design concern","Netra GQA grouping/native FP8-cache specialization is shape/ABI-specific engineering","https://arxiv.org/abs/2205.14135"),
    ("Paged KV cache","Established research/serving practice","PagedAttention/vLLM virtualizes KV-cache allocation","Netra does not claim novelty for paging","https://arxiv.org/abs/2309.06180"),
    ("Automated schedule search","Established research","Ansor searches tensor-program schedules","Netra's measured tactic tables are evidence-driven but not a new autotuning theory","https://arxiv.org/abs/2006.06762"),
    ("AMD multi-backend kernel library","Established vendor practice","AITER provides CK, Triton and assembly paths on gfx950","Netra's contribution is exact-contract specialization and integration","https://github.com/ROCm/aiter"),
    ("Producer/reducer shared workspace contract","Useful combination; possibly distinctive engineering","Split-K and staged reductions are established; exact paired ABI is common systems technique","Byte-identical modular M768 pair plus manifest lock is defensible internal novelty, not research novelty","docs/notes/gfx950-template-modularity-audit.md"),
    ("Serving gates override microbenchmarks","Strong internal engineering contribution","End-to-end validation is standard benchmarking discipline","The systematic negative-result ledger and removal of local wins is unusually rigorous but not research-novel","rejected-superseded-experiments.csv"),
    ("BF16 recurrent-state pool with FP32 accumulation","Useful combination of known precision/storage ideas","Mixed precision storage/accumulation is established","Exact dFlash T8 ABI, replay semantics, and measured memory-throughput trade are repository-specific","docs/notes/gfx950-qwen36-27b-fp8.md"),
    ("Model frontend to model-neutral operations","Established compiler architecture, useful repository combination","MLIR and graph compilers lower frontends to operation IRs","Netra's manifests/tactics are a practical implementation, not defensible research novelty alone","docs/compiler/architecture.md"),
]

write_csv("competitor-eligibility.csv", list(competitors[0]), competitors)
write_csv("kernel-comparison-matrix.csv", comparison_fields, comparison_rows)
write_csv("benchmark-samples.csv", ["model","experiment","metric","unit","process","order","value","raw_artifact_available","evidence"], samples)
write_csv("benchmark-aggregates.csv", ["model","experiment","metric","unit","n","mean","median","minimum","maximum","p5","p95","stddev","cv","confidence_interval","correctness","source","availability"], aggregates)
write_csv("rejected-superseded-experiments.csv", ["model","experiment","kernel_only_result","end_to_end_result","decision_reason","status","evidence"], [dict(zip(["model","experiment","kernel_only_result","end_to_end_result","decision_reason","status","evidence"], r)) for r in rejected])
write_csv("performance-winners.csv", ["model","operation","exact_contract","winner","status","basis","evidence"], [dict(zip(["model","operation","exact_contract","winner","status","basis","evidence"], r)) for r in winners])
write_csv("benchmark-coverage.csv", list(coverage[0]), coverage)
write_csv("prior-art-novelty.csv", ["idea","classification","prior_art","netra_assessment","primary_source"], [dict(zip(["idea","classification","prior_art","netra_assessment","primary_source"], r)) for r in prior_art])

# Preserve every mechanically identified tracked numeric sample and aggregate
# in dedicated CSVs. JSON paths are retained and units are not guessed.
with (DATA / "historical-benchmark-metrics.csv").open(newline="") as f:
    historical_metrics = list(csv.DictReader(f))
metric_fields = ["repository","evidence_path","evidence_sha256","json_path","value","classification"]
write_csv("benchmark-samples-exhaustive.csv", metric_fields, [r for r in historical_metrics if r["classification"] == "sample"])
write_csv("benchmark-aggregates-exhaustive.csv", metric_fields, [r for r in historical_metrics if r["classification"] == "aggregate_or_metric"])

# Enrich the exhaustive commit chronology with a decision-oriented ledger. A
# row may still say "not retained" where the repository lacks an exact field;
# that is preferable to guessing. The evidence commit is the latest relevant
# commit that touched/referenced the retained evidence path, not necessarily
# the first experimental code commit.
with (DATA / "evidence-inventory.csv").open(newline="") as f:
    evidence_rows = list(csv.DictReader(f))
with (DATA / "chronological-optimization-ledger.csv").open(newline="") as f:
    chronology_rows = list(csv.DictReader(f))
evidence_index = {(r["repository"], r["path"]): r for r in evidence_rows}


def resolve_evidence(raw: str) -> tuple[str, str, str, str, str]:
    first = raw.split(";")[0]
    if first.startswith("http"):
        return first, "external", "", "", ""
    repository = "netra-kernel"
    path = first
    if first.startswith("netra-server:"):
        repository, path = "netra-server", first.split(":", 1)[1]
    item = evidence_index.get((repository, path), {})
    touches = [r for r in chronology_rows if r["repository"] == repository and path in r["relevant_paths"].split(";")]
    touch = touches[-1] if touches else {}
    return first, repository, item.get("sha256", ""), touch.get("commit", ""), touch.get("refs", "")


decision_fields = [
    "date","evidence_commit","refs","model","operation","shape","dtype_layout_quantization",
    "batch_concurrency","graph_mode","baseline_implementation","candidate_implementation",
    "kernel_only_result","integrated_end_to_end_result","correctness_criteria_result","decision",
    "decision_reason","evidence_path","evidence_sha256","record_completeness",
]
decision_rows = []
for r in comparison_rows:
    evidence_path, repository, evidence_sha, commit, refs = resolve_evidence(str(r["evidence_path"]))
    history = [x for x in chronology_rows if x["repository"] == repository and x["commit"] == commit]
    date = history[0]["date"] if history else ""
    baseline = "default SGLang / named control in evidence"
    if r["acceptance_status"] in {"baseline", "eligible baseline"}:
        baseline = str(r["implementation"])
    decision_rows.append(dict(
        date=date, evidence_commit=commit, refs=refs, model=r["model"], operation=r["operation"],
        shape=r["shape"], dtype_layout_quantization=r["dtype_layout"], batch_concurrency="embedded in exact shape/profile; see evidence",
        graph_mode=r["graph_mode"], baseline_implementation=baseline, candidate_implementation=r["implementation"],
        kernel_only_result=r["kernel_latency"], integrated_end_to_end_result=r["end_to_end_serving_effect"],
        correctness_criteria_result=r["correctness_result"], decision=r["acceptance_status"],
        decision_reason="Serving gate controls promotion; see comparison and rejection ledgers",
        evidence_path=evidence_path, evidence_sha256=evidence_sha,
        record_completeness="reviewed; blank metrics were not retained in tracked evidence",
    ))
for model, experiment, kernel_result, e2e_result, reason, status, evidence in rejected:
    evidence_path, repository, evidence_sha, commit, refs = resolve_evidence(evidence)
    history = [x for x in chronology_rows if x["repository"] == repository and x["commit"] == commit]
    date = history[0]["date"] if history else ""
    decision_rows.append(dict(
        date=date, evidence_commit=commit, refs=refs, model=model, operation=experiment, shape="see evidence",
        dtype_layout_quantization="see evidence", batch_concurrency="see evidence", graph_mode="see evidence",
        baseline_implementation="named control in evidence", candidate_implementation=experiment,
        kernel_only_result=kernel_result, integrated_end_to_end_result=e2e_result,
        correctness_criteria_result="see evidence", decision=status, decision_reason=reason,
        evidence_path=evidence_path, evidence_sha256=evidence_sha,
        record_completeness="decision reviewed; exact contract fields not repeated when absent from retained summary",
    ))
decision_rows.sort(key=lambda r: (r["date"], r["model"], r["operation"], r["candidate_implementation"]))
write_csv("optimization-decision-ledger.csv", decision_fields, decision_rows)

summary = {
    "schema_version": "netra-gfx950-qwen36-retrospective-1",
    "as_of": "2026-08-21",
    "scope": ["Qwen3.6-27B-FP8", "Qwen3.6-35B-A3B-FP8", "AMD MI350X/gfx950"],
    "revisions": {
        "kernel_anchor_and_latest_main": "9c5940cceaecb00a26f157a4894d1a8edad4e0d4",
        "server_anchor_and_latest_main": "fae2865d9b3096c2cc518aa16d3797ac828f77cc",
    },
    "evidence_counts": json.loads((DATA / "evidence-summary.json").read_text()),
    "current_execution": {
        "gpu_benchmarks_run": False,
        "reason": "No /dev/kfd, ROCm runtime/toolchain, Docker daemon, or archived /data/netra artifacts on this host.",
        "policy": "Historical values are reported only where present in tracked evidence; missing values remain null/empty.",
    },
    "curated_counts": {
        "operations": sum(1 for _ in csv.DictReader((OUT / "operation-inventory.csv").open())),
        "comparison_rows": len(comparison_rows),
        "retained_process_samples": len(samples),
        "aggregate_rows": len(aggregates),
        "exhaustive_tracked_aggregate_fields": sum(r["classification"] == "aggregate_or_metric" for r in historical_metrics),
        "exhaustive_tracked_sample_fields": sum(r["classification"] == "sample" for r in historical_metrics),
        "negative_results": len(rejected),
        "competitor_records": len(competitors),
        "reviewed_decision_rows": len(decision_rows),
    },
    "validation": {
        "kernel_tools_ci_check": "passed: 97 tests plus repository, tactic-library, and example-compilation checks",
        "server_dependency_free_unittest": "passed: 17 tests in test_qwen36_exact_cases.py",
        "server_pytest_suite": "not run: pytest is absent from the audit host",
        "gpu_tests": "not run: no /dev/kfd or ROCm runtime",
    },
    "strongest_conclusions": [
        "Netra wins come from exact operation contracts, gfx950-specialized kernels, graph-safe integration, and deployment locking together; isolated kernel speed is insufficient.",
        "The most reproducible accepted mechanisms reduce cache traffic, state traffic, launch/dispatch work, or materialization at exact serving shapes.",
        "AITER remains the production winner for several dense and fallback paths because locally faster Netra candidates failed serving gates.",
        "The negative-result ledger is central evidence: at least four sizable microbenchmark wins were flat or negative in matched serving.",
    ],
    "novelty": {
        "research_novel_claims": [],
        "defensible_internal_engineering": [
            "Byte-locked modular raw-kernel templates plus operation manifests and graph-safe bridges on gfx950.",
            "Exact producer/reducer workspace contracts and evidence-locked tactic selection integrated into SGLang serving.",
            "Systematic serving-gated promotion with retained negative results across kernel, graph, and natural-EOS tests.",
        ],
    },
    "uncertain_claims": [
        "No current-run comparison against pinned upstream competitors was possible.",
        "Raw /data samples, profiler databases, and several cited code objects could not be rehashed.",
        "Input-1K coverage and a complete matched metric set (TTFT, TPOT, p50/p95, memory) are not retained in tracked evidence.",
        "No potentially research-novel claim is asserted without a broader literature and implementation search plus reproducible current measurements.",
    ],
}
(OUT / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote curated retrospective tables to {OUT}")
