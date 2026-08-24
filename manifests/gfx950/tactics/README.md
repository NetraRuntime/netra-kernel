# gfx950 tactic catalogs

Each `*.json` file with format `netra-fixed-tactic-catalog-1` contributes
model-independent, fixed-contract assembly tactics. The compiler scans the
directory in lexical order and rejects duplicate tactic IDs. Adding a Gemma,
Llama, or other model tactic therefore does not require modifying the Qwen
deployment lock or Python registry code.

Every tactic must close its semantic contract and all assembler-time constants.
Unknown semantics or constants reject the tactic instead of being ignored.
`rank` is an explicit measured preference: lower wins, and equal-rank compatible
tactics are rejected as ambiguous. Experimental tactics require an explicit
compiler opt-in; rejected tactics are never selected.

Model compatibility names and locked deployable artifact hashes belong under
`manifests/gfx950/deployments/`. They are not part of a tactic's computational
identity. Generated `.s`, object, HSACO, metadata, and disassembly files belong
under ignored `build/` directories only.
