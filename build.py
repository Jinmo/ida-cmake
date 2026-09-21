#!/usr/bin/env python3

"""
    The MIT License (MIT)

    Copyright (c) 2017 Joel Hoener <athre0z@zyantific.com>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
"""

# Helper for building C++ IDA plugins against IDA SDK 9.4.
# Requires Python 3.13+ and CMake >= 3.21.

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def run(cmd: list[str], cwd: Path) -> None:
    print(" ".join(f"'{x}'" if " " in x else x for x in cmd))
    # check=False: the exit code is inspected here, with a friendlier message
    # than a CalledProcessError traceback.
    if subprocess.run(cmd, cwd=cwd, check=False).returncode != 0:
        sys.exit("[-] Command failed, giving up.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Configure, build and install an IDA plugin (IDA SDK 9.4)."
    )
    parser.add_argument(
        "--ida-sdk", "-i", required=True,
        help="Path to the IDA SDK (the directory holding include/ and lib/)")
    parser.add_argument(
        "--ida-install-dir", "--idaq-path", dest="ida_install_dir",
        help="IDA installation directory; used for installing the plugin, "
             "and required on Linux/macOS for linking against IDA's own libraries")
    parser.add_argument(
        "--build-dir", default="build", help="Build directory (default: build)")
    parser.add_argument(
        "--gen", "-G", help="CMake generator (default: Ninja if available)")
    parser.add_argument(
        "--skip-install", action="store_true", help="Do not run the install step")
    parser.add_argument(
        "cmake_args", nargs=argparse.REMAINDER,
        help="Additional arguments passed to CMake verbatim")
    args = parser.parse_args()

    cmake = shutil.which("cmake")
    if not cmake:
        sys.exit("[-] Unable to find CMake binary")
    if sys.platform != "win32" and not args.ida_install_dir:
        sys.exit("[-] On Linux/macOS, --ida-install-dir is required.")

    build_dir = Path(args.build_dir)
    build_dir.mkdir(parents=True, exist_ok=True)

    # Release is required: QtIDA.cmake redirects the Qt6::* targets to IDA's
    # own Qt libraries via *_RELEASE properties only.
    cmd = [
        cmake, str(Path.cwd()),
        "-DCMAKE_BUILD_TYPE=Release",
        f"-DIDA_SDK={args.ida_sdk}",
    ]
    gen = args.gen or ("Ninja" if shutil.which("ninja") else None)
    if gen:
        cmd += ["-G", gen]
    if args.ida_install_dir:
        cmd += [f"-DIDA_INSTALL_DIR={args.ida_install_dir}",
                f"-DCMAKE_INSTALL_PREFIX={args.ida_install_dir}"]
    cmd += args.cmake_args

    run(cmd, cwd=build_dir)
    run([cmake, "--build", ".", "--parallel"], cwd=build_dir)
    if not args.skip_install and args.ida_install_dir:
        run([cmake, "--build", ".", "--target", "install"], cwd=build_dir)

    print("[+] Done!")


if __name__ == "__main__":
    main()
