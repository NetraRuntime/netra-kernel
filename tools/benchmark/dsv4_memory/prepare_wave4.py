# SPDX-License-Identifier: MIT
"""Replicate independent waves; handwritten computation is unchanged."""
import pathlib, sys
source, out = map(pathlib.Path, sys.argv[1:])
for p in source.glob('*.s'):
    s = p.read_text().replace('netra_dsv4_' + p.stem, 'netra_dsv4_' + p.stem + '_w4')
    s = s.replace('    s_waitcnt lgkmcnt(0)\n', '''    s_waitcnt lgkmcnt(0)
    // Each wave owns one row. Producer and consumer readlane delays are required.
    v_lshrrev_b32 v23, 6, v0
    s_nop 4
    v_readfirstlane_b32 s62, v23
    s_nop 4
    v_and_b32 v0, 63, v0
    s_lshl_b32 s2, s2, 2
    s_add_u32 s2, s2, s62
    s_cmp_ge_u32 s2, s51
    s_cbranch_scc1 .Ldone
''', 1).replace('.max_flat_workgroup_size: 64', '.max_flat_workgroup_size: 256')
    (out / (p.stem + '_w4.s')).write_text(s)
