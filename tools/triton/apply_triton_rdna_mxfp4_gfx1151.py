#!/usr/bin/env python3
"""Apply the published RDNA manual-dequant graft to a Triton kernels tree."""

import argparse
import py_compile
import sys
from pathlib import Path


def patch(path, edits, marker):
    text = path.read_text()
    if marker in text:
        print(f"already patched: {path}")
        return
    for old, new in edits:
        if old not in text:
            raise RuntimeError(f"anchor not found in {path}: {old[:100]!r}")
        text = text.replace(old, new, 1)
    path.write_text(text)
    py_compile.compile(str(path), doraise=True)
    print(f"patched: {path}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("triton_kernels")
    args = parser.parse_args()
    root = Path(args.triton_kernels)

    layout = root / "tensor_details/layout.py"
    patch(
        layout,
        [
            (
                "from .layout_details.cdna4_scale import CDNA4MXScaleLayout\n",
                "from .layout_details.cdna4_scale import CDNA4MXScaleLayout\n"
                "from .layout_details.rdna_value import RDNAMXValueLayout\n",
            ),
            (
                '    "CDNA4MXScaleLayout",\n',
                '    "CDNA4MXScaleLayout",\n    "RDNAMXValueLayout",\n',
            ),
        ],
        "RDNAMXValueLayout",
    )

    kernel = root / "matmul_ogs_details/_matmul_ogs.py"
    patch(
        kernel,
        [
            (
                "from triton_kernels.tensor_details.layout_details.cdna4_scale "
                "import unswizzle_mx_scale_cdna4",
                "from triton_kernels.tensor_details.layout_details.cdna4_scale "
                "import unswizzle_mx_scale_cdna4\n"
                "from triton_kernels.tensor_details.layout_details.rdna_value "
                "import mxfp4_dequant_rdna",
            ),
            (
                'tl.static_assert(SWIZZLE_MX_VALUE == "HOPPER_VALUE" or '
                'SWIZZLE_MX_VALUE is None, "Only Hopper swizzling is supported '
                'for values")',
                'tl.static_assert(SWIZZLE_MX_VALUE == "HOPPER_VALUE" or '
                'SWIZZLE_MX_VALUE == "RDNA_VALUE" or SWIZZLE_MX_VALUE is None, '
                '"Only Hopper and RDNA swizzling is supported for values")',
            ),
            (
                """            W_K_DIVISOR: tl.constexpr = 1
            W_K_MULTIPLIER: tl.constexpr = 2
            W_N_DIVISOR: tl.constexpr = 4
        else:""",
                """            W_K_DIVISOR: tl.constexpr = 1
            W_K_MULTIPLIER: tl.constexpr = 2
            W_N_DIVISOR: tl.constexpr = 4
        elif SWIZZLE_MX_VALUE == "RDNA_VALUE":
            tl.static_assert(is_mxfp4, "Only mxfp4 is supported for RDNA dequant")
            tl.static_assert(not is_x_microscaled)
            W_K_DIVISOR: tl.constexpr = 2
            W_K_MULTIPLIER: tl.constexpr = 1
            W_N_DIVISOR: tl.constexpr = 1
        else:""",
            ),
            (
                """                acc = tl.dot(w, x, acc, max_num_imprecise_acc=MAX_NUM_IMPRECISE_ACC, allow_tf32=ALLOW_TF32)
                acc = acc.trans()
            else:
                rhs_k_pack: tl.constexpr = W_TRANSPOSE or not is_w_microscaled or W_K_DIVISOR != 2""",
                """                acc = tl.dot(w, x, acc, max_num_imprecise_acc=MAX_NUM_IMPRECISE_ACC, allow_tf32=ALLOW_TF32)
                acc = acc.trans()
            elif SWIZZLE_MX_VALUE == "RDNA_VALUE":
                rdna_out_type: tl.constexpr = x.dtype
                w_dequant = mxfp4_dequant_rdna(w, w_scales, mx_axis=1, OUT_DTYPE=rdna_out_type)
                acc = tl.dot(x, w_dequant, acc, max_num_imprecise_acc=MAX_NUM_IMPRECISE_ACC, allow_tf32=ALLOW_TF32)
            else:
                rhs_k_pack: tl.constexpr = W_TRANSPOSE or not is_w_microscaled or W_K_DIVISOR != 2""",
            ),
        ],
        'SWIZZLE_MX_VALUE == "RDNA_VALUE"',
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(exc, file=sys.stderr)
        raise
