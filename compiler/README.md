# Netra Compiler package

This directory contains the installable `netra-compiler` Python package.

```bash
python3 -m pip install -e ./compiler
netra-compile list-tactics --target gfx950 --library-root .
```

Schemas, tactic catalogs, model manifests, profiles, and assembly templates are
versioned as the Netra kernel library outside the Python wheel. Pass
`--library-root` (or the corresponding Python argument) explicitly when the
package is not running from a source checkout. This keeps installed compiler
code relocatable without silently selecting machine-local resources.

The compiler core has no mandatory third-party runtime dependencies.
