# Installable SGLang deployment

Netra's SGLang integration has two layers:

1. A `netra-kernel` wheel supplies the `netra-sglang` command, the
   `sglang.srt.plugins` entry point, compatibility probes, the gfx1151
   framework adapter, and an accepted gfx950 SGLang source snapshot.
2. A small, relocatable bundle supplies the exact accepted `.hsaco` and `.so`
   artifacts for one deployment profile.

The wheel does not embed machine code for every GPU/profile. Deployment
bundles remain hash-locked, auditable, and independently rebuildable. The
compressed source snapshot is 5.8 MB and expands to a separate 32 MB tree; it
never overwrites a user's checkout.

## Install

From a checkout:

```bash
python -m pip install '.[sglang]'
netra-sglang profiles
```

The package registers the `netra` entry point in `sglang.srt.plugins`. SGLang
loads it in the launcher, scheduler, engine, and worker processes. Nothing is
enabled unless `NETRA_BUNDLE` is set.

## Build one gfx950 bundle

Pass one or more roots containing built artifacts. Candidates are selected by
both basename and the profile's accepted SHA-256; an older file with the same
name cannot be selected accidentally.

```bash
netra-sglang bundle \
  --profile qwen36-35b-current-best \
  --artifact-root /path/to/netra-kernel/build \
  --output /srv/netra/qwen36-35b

netra-sglang validate /srv/netra/qwen36-35b
```

The output contains:

- `bundle.json`: profile, artifact provenance, hashes, and SGLang environment;
- `artifacts/`: the resolved bridges and code objects;
- `docker.env`: container paths rooted at `/opt/netra`;
- `env.sh`: host paths rooted at the bundle's actual location.

`--copy` produces a fully independent directory. The default tries hardlinks
first and falls back to copying, which is useful when assembling a bundle next
to a build tree.

## Use a compatible SGLang fork

Install the wheel in the same environment as a compatible fork, then run the
doctor before loading a model:

```bash
NETRA_BUNDLE=/srv/netra/qwen36-35b \
  netra-sglang doctor --bundle /srv/netra/qwen36-35b --json

NETRA_BUNDLE=/srv/netra/qwen36-35b \
  python -m sglang.launch_server ...
```

The gfx950 profiles intentionally fail closed when the fork lacks a required
model-level adapter. Those boundaries include Qwen routing, GDN state replay,
and target/draft attention; silently enabling only part of that path would be
incorrect and can regress performance. A fork may change unrelated code as
long as the doctor finds the required SGLang plugin API and Netra adapter
modules.

Build the wheel-only image when the fork already contains those modules:

Build a thin image that installs only the wheel:

```bash
docker build \
  --build-arg SGLANG_BASE_IMAGE=lmsysorg/sglang:your-tag \
  -f docker/sglang/Dockerfile.plugin \
  -t my-sglang-with-netra \
  /directory/containing/the/netra_kernel-wheel
```

Mount the compatible SGLang source fork as usual, plus one read-only bundle:

```bash
docker run ... \
  --env PYTHONPATH=/my-sglang/python \
  --env NETRA_BUNDLE=/opt/netra \
  --volume /path/to/my-sglang:/my-sglang:ro \
  --volume /srv/netra/qwen36-35b:/opt/netra:ro \
  my-sglang-with-netra \
  python -m sglang.launch_server ...
```

This is the validated gfx950 mode: the heavyweight base image remains
unchanged apart from the small wheel, while users retain control of their own
SGLang fork. The plugin makes `NETRA_BUNDLE` authoritative over stale
per-artifact variables inherited from an image or launcher.

## Use stock/base SGLang

The accepted profile can materialize the exact SGLang source and AITER tuning
tables used by the performance gate:

```bash
netra-sglang source \
  --profile qwen36-35b-20260817-best \
  --output /srv/netra/sglang-source

netra-sglang source-validate /srv/netra/sglang-source

eval "$(netra-sglang source-env /srv/netra/sglang-source)"
NETRA_BUNDLE=/srv/netra/qwen36-35b \
  python -m sglang.launch_server ...
```

The snapshot is commit
`c131cc0a1044ddf3a30b2e5096d56000e629993d`, contains its Apache-2.0
license, and is checked as 2,753 archive-controlled files. Runtime bytecode
caches are ignored by validation, but any source or tuning-table change fails
the aggregate tree hash.

For a stock SGLang container, `Dockerfile.base` performs those steps during
the image build and sets all three required paths:

```bash
docker build \
  --build-arg SGLANG_BASE_IMAGE=lmsysorg/sglang:your-tag \
  -f docker/sglang/Dockerfile.base \
  -t my-stock-sglang-with-netra \
  /directory/containing/the/netra_kernel-wheel

docker run ... \
  --env NETRA_BUNDLE=/opt/netra \
  --volume /srv/netra/qwen36-35b:/opt/netra:ro \
  my-stock-sglang-with-netra \
  python -m sglang.launch_server ...
```

No SGLang source mount is needed. The stock image keeps its ROCm, PyTorch,
AITER, and compiled dependencies; Python resolves the separately embedded,
performance-accepted source tree first. The validated stock base was SGLang
0.5.16 at commit `fdebc938f7f4d16fe6b9f55dcd9a767cf0899ea1`.

Stock SGLang without either this source snapshot or equivalent adapter modules
is deliberately reported as incompatible and remains on the framework path.

## Integrate the pinned gfx1151 base source

The complete existing gfx1151 overlay is packaged in the wheel. Its source
contract is SGLang commit `1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4`.
Install the wheel in the Python environment that will run the patched SGLang,
then run a read-only preflight from that same environment:

```bash
python -m pip install /path/to/netra-kernel
netra-sglang integrate --target gfx1151 --sglang-root /path/to/sglang
```

The command creates a disposable worktree and applies all 15 patches there.
Only after that succeeds should the user explicitly request the mutation:

```bash
netra-sglang integrate \
  --target gfx1151 \
  --sglang-root /path/to/sglang \
  --apply
```

Dirty SGLang checkouts are refused. A nearby fork may work through Git's
three-way application, but the full preflight must pass. The generated source
shim imports the adapter from the installed `netra-kernel` package. Running the
patched SGLang from an environment without that wheel now fails with a direct
installation error instead of an ambiguous missing-module traceback. This
eliminates the former manual copy of a 1,300-line Python file while keeping one
canonical adapter implementation.

## Reproduce the serving gate

`tools/benchmark/run_bundle_gate_from_inspect.py` clones an audited Docker
deployment while changing only the image, container name, results directory,
and Netra artifact mount. It preserves devices, security options, environment,
model mounts, and the exact server command.

Pass `--use-image-sglang` for `Dockerfile.base`; it removes the recorded
SGLang source mount and all environment values rooted there so the image's
validated source and tuning tables are actually exercised.

The August 23 validation used five fresh processes, 384 requests per process,
1,024 input tokens, 1,024 forced output tokens, and concurrency 128 on one
MI350X. The bundle mean was 10,157.13 output tokens/s, 1.52% above the accepted
10,004.95 tokens/s baseline. Every run completed all requests with exact token
counts and zero nonempty errors. See the
[machine-readable result](notes/sglang-plugin-gfx950-benchmark-20260823.json).

The final stock-base audit then used one fresh process with no SGLang source
mount. It completed all 384 requests and exact 1,024/1,024 token lengths at
10,316.86 output tokens/s, 3.12% above the same locked baseline. The result,
image, wheel, source archive, bundle, and container-inspect hashes are recorded
in the same machine-readable evidence.
