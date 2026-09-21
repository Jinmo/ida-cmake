#
# The MIT License (MIT)
#
# Copyright (c) 2026 Blue DeviL // SCT <bluedevil.SCT@proton.me>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

#
# Architecture / platform detection for the IDA SDK's directory layout.
#
# The SDK names its library directories  <arch>_<os>_<ea>[_s]  for example:
#
#   x64_win_64      arm64_win_64    : x86_win_32_s
#   x64_linux_64    arm64_linux_64
#   x64_mac_64      arm64_mac_64
#   x64_win_qt      arm64_win_qt    : Qt import libraries, Windows only
#
# SDK 8.x and older inserted a toolchain infix on Windows (x64_win_vc_64), so
# every lookup here tries a list of candidates and takes the first that exists.
# That keeps one source tree working across SDK generations.
#
# Nothing in this file may be hardcoded to a single architecture: this project
# is built for win/linux/mac on both x64 and arm64.
#

include_guard(GLOBAL)

# ============================================================================ #
# Architecture token                                                           #
# ============================================================================ #

# On Apple, CMAKE_SYSTEM_PROCESSOR reports the host, not the target, so an
# explicit -DCMAKE_OSX_ARCHITECTURES always wins when one was given.
if (APPLE AND CMAKE_OSX_ARCHITECTURES)
    list(LENGTH CMAKE_OSX_ARCHITECTURES _ida_osx_arch_count)
    if (_ida_osx_arch_count GREATER 1)
        message(FATAL_ERROR
            "The IDA SDK ships per-architecture libraries, not universal "
            "ones, so a fat binary cannot be linked. Configure one "
            "architecture at a time, e.g. -DCMAKE_OSX_ARCHITECTURES=arm64")
    endif ()
    set(_ida_raw_arch "${CMAKE_OSX_ARCHITECTURES}")
elseif (CMAKE_SYSTEM_PROCESSOR)
    set(_ida_raw_arch "${CMAKE_SYSTEM_PROCESSOR}")
else ()
    set(_ida_raw_arch "${CMAKE_HOST_SYSTEM_PROCESSOR}")
endif ()

string(TOLOWER "${_ida_raw_arch}" _ida_raw_arch)

# MSVC says ARM64/AMD64, gcc says aarch64/x86_64, Apple says arm64/x86_64.
if (_ida_raw_arch MATCHES "^(arm64|arm64e|aarch64)$")
    set(IDA_ARCH "arm64")
elseif (_ida_raw_arch MATCHES "^(x64|x86_64|amd64)$")
    set(IDA_ARCH "x64")
elseif (_ida_raw_arch MATCHES "^(x86|i[3-6]86|win32)$")
    set(IDA_ARCH "x86")
else ()
    message(FATAL_ERROR
        "Cannot map target processor '${_ida_raw_arch}' onto an IDA SDK "
        "architecture. Expected one of arm64/aarch64, x86_64/amd64/x64, "
        "or x86/i386. Pass -DIDA_ARCH=<arm64|x64|x86> to override this "
        "detection.")
endif ()

# A 32-bit pointer model always wins over the processor name: a 32-bit build
# hosted on an x86_64 machine can still report AMD64 on some generators.
if (DEFINED CMAKE_SIZEOF_VOID_P AND CMAKE_SIZEOF_VOID_P EQUAL 4
        AND IDA_ARCH STREQUAL "x64")
    set(IDA_ARCH "x86")
endif ()

# ============================================================================ #
# OS token                                                                     #
# ============================================================================ #

if (WIN32)
    set(IDA_OS "win")
elseif (APPLE)
    set(IDA_OS "mac")
elseif (UNIX)
    set(IDA_OS "linux")
else ()
    message(FATAL_ERROR "Unsupported target system '${CMAKE_SYSTEM_NAME}'.")
endif ()

# Cached so an explicit -DIDA_ARCH= survives, and so the tokens are visible to
# both IDA.cmake and QtIDA.cmake regardless of which one is included first.
set(IDA_ARCH "${IDA_ARCH}" CACHE STRING "IDA SDK architecture token (arm64/x64/x86)")
set(IDA_OS   "${IDA_OS}"   CACHE STRING "IDA SDK os token (win/linux/mac)")

message(STATUS "IDA SDK target: ${IDA_ARCH}_${IDA_OS} (detected from '${_ida_raw_arch}')")

# ============================================================================ #
# Directory lookup helpers                                                     #
# ============================================================================ #

# ida_sdk_lib_dir(<out_var> <ea_bits>)
#   Locates the SDK library directory holding ida.lib / libida for this target.
function (ida_sdk_lib_dir out_var ea_bits)
    set(_candidates
        "${IDA_SDK}/lib/${IDA_ARCH}_${IDA_OS}_${ea_bits}"
        "${IDA_SDK}/lib/${IDA_ARCH}_${IDA_OS}_vc_${ea_bits}"  # SDK <= 8.x on Windows
        "${IDA_SDK}/lib/${IDA_ARCH}_${IDA_OS}_${ea_bits}_s"   # static CRT variant
    )
    foreach (_candidate ${_candidates})
        if (EXISTS "${_candidate}")
            set(${out_var} "${_candidate}" PARENT_SCOPE)
            return()
        endif ()
    endforeach ()

    set(${out_var} "" PARENT_SCOPE)
    message(WARNING
        "No IDA SDK library directory for ${IDA_ARCH}_${IDA_OS}_${ea_bits} "
        "under ${IDA_SDK}/lib. Tried: ${_candidates}")
endfunction ()

# ida_sdk_qt_lib_dir(<out_var>)
#   Locates the SDK directory holding IDA's own Qt import libraries.
#   Windows only; on Linux/macOS the Qt libraries are taken from the IDA
#   installation itself rather than from the SDK.
function (ida_sdk_qt_lib_dir out_var)
    set(_candidates
        "${IDA_SDK}/lib/${IDA_ARCH}_${IDA_OS}_qt"
    )
    foreach (_candidate ${_candidates})
        if (EXISTS "${_candidate}")
            set(${out_var} "${_candidate}" PARENT_SCOPE)
            return()
        endif ()
    endforeach ()

    set(${out_var} "" PARENT_SCOPE)
endfunction ()
