# Reference inference-engine consumer

This intentionally contains no SGLang or PyTorch code. It demonstrates the
entire native dependency surface required by another inference engine:
`<netra/engine.h>` and the exported `netra::netra_engine` CMake target.

```sh
cmake -S . -B build -DCMAKE_PREFIX_PATH=/opt/netra
cmake --build build
./build/netra-reference-engine
```

An engine binds its own device pointers by numeric operation/argument index
and passes its native HIP stream as `netra_stream_t`. The Python equivalent is
`netra_kernel.Engine`; bundle activation is separately extensible through the
`netra.inference_engines` entry-point group.
