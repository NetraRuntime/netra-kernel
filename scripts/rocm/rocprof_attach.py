#!/root/venv1151/bin/python3
"""Missing rocprof-attach frontend for the PyTorch ROCm SDK wheel.

Implements the official ROCm rocAttach CLI contract using the ABI-matched
librocprofiler-sdk-rocattach bundled with the wheel.
"""
from __future__ import annotations

import argparse
import ctypes
import os
import signal
import sys
import time

DEFAULT_LIBRARY = (
    "/root/venv1151/lib/python3.12/site-packages/_rocm_sdk_core/"
    "lib/librocprofiler-sdk-rocattach.so.1"
)


def env_bool(name: str, default: bool) -> bool:
    value = os.environ.get(name)
    if value is None:
        return default
    return value.lower() not in ("0", "false", "no", "off")


def parse_bool(value: str) -> bool:
    return value.lower() not in ("0", "false", "no", "off")

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--pid", "--attach", type=int,
                        default=os.environ.get("ROCPROF_ATTACH_PID"))
    parser.add_argument("-t", "--attach-tool-library",
                        default=os.environ.get("ROCPROF_ATTACH_TOOL_LIBRARY"))
    parser.add_argument("-d", "--attach-duration-msec", type=int,
                        default=os.environ.get("ROCPROF_ATTACH_DURATION"))
    parser.add_argument("--attach-children", type=parse_bool,
                        default=env_bool("ROCPROF_ATTACH_CHILDREN", True))
    parser.add_argument("--attach-library",
                        default=os.environ.get("ROCPROF_ATTACH_LIBRARY", DEFAULT_LIBRARY))
    args = parser.parse_args()
    if args.pid is None or not args.attach_tool_library:
        raise SystemExit("rocprof-attach requires a PID and tool library")
    for path in args.attach_tool_library.split(":"):
        if not os.path.exists(path):
            raise SystemExit(f"tool library does not exist: {path}")

    os.environ["ROCPROF_ATTACH_TOOL_LIBRARY"] = args.attach_tool_library
    lib = ctypes.CDLL(args.attach_library)
    for name in ("rocattach_attach", "rocattach_attach_tree",
                 "rocattach_detach", "rocattach_detach_tree"):
        function = getattr(lib, name)
        function.restype = ctypes.c_int
        function.argtypes = [ctypes.c_int]
    attach = lib.rocattach_attach_tree if args.attach_children else lib.rocattach_attach
    detach = lib.rocattach_detach_tree if args.attach_children else lib.rocattach_detach
    status = attach(args.pid)
    if status:
        raise SystemExit(f"rocattach attach failed with status {status}")
    print(f"attached rocprofiler to PID {args.pid}", flush=True)

    def finish(*_: object) -> None:
        detach_status = detach(args.pid)
        if detach_status:
            raise SystemExit(f"rocattach detach failed with status {detach_status}")
        print(f"detached rocprofiler from PID {args.pid}", flush=True)

    signal.signal(signal.SIGINT, finish)
    if args.attach_duration_msec is None:
        input("Press Enter to detach...")
    else:
        time.sleep(args.attach_duration_msec / 1000.0)
    finish()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
