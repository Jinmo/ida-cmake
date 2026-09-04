# IDA plugin CMake build-script

This repository holds **CMake** build scripts and a Python helper allowing
compilation of C++ IDA plugins for Windows, macOS and Linux without
much user effort.

Targets **IDA SDK 9.4** (IDA 9.x, x64 and arm64). Requires CMake >= 3.21 and,
for `build.py`, Python 3.13+. Architecture (x64 vs arm64) is detected at
configure time from the toolchain; pass `-DIDA_ARCH=` only to override.

## Simple plugin example usage

### Create plugin repo

```bash
git init myplugin
cd myplugin
git submodule add https://github.com/jinmo/ida-cmake.git ida-cmake
mkdir src
touch src/myplugin.cpp CMakeLists.txt
```

### CMakeLists.txt

```CMake
cmake_minimum_required(VERSION 3.21)
project(myplugin)

include("ida-cmake/cmake/IDA.cmake")

set(sources "src/myplugin.cpp")
add_ida_plugin(${CMAKE_PROJECT_NAME} ${sources})
```

Qt-based plugins additionally `include("ida-cmake/cmake/QtIDA.cmake")` before
`IDA.cmake` and use `add_ida_qt_plugin()`. On Windows this links against the
Qt import libraries shipped in the SDK (`<arch>_win_qt`), which is also why
the build type must be `Release`.

### src/myplugin.cpp

```cpp
#include <ida.hpp>
#include <idp.hpp>
#include <loader.hpp>

static plugmod_t* idaapi init()
{
    msg("Hello, IDA plugin world!\n");
    return PLUGIN_KEEP;
}

static bool idaapi run(size_t /*arg*/) { return true; }

static void idaapi term() {}

plugin_t PLUGIN =
{
    IDP_INTERFACE_VERSION,
    0,                       // flags
    init,
    term,
    run,
    "My plugin description", // comment
    "My plugin help",        // help
    "My plugin name",        // wanted_name (menu entry text)
    nullptr,                 // wanted_hotkey, e.g. "Ctrl-Shift-A"
};
```

### Building and installing the plugin

Run from an environment where your compiler is available (on Windows: the
x64 or ARM64 Native Tools prompt of Visual Studio — the prompt's target
architecture decides what gets built):

```bash
ida-cmake/build.py -i <ida-sdk-path> --ida-install-dir <ida-install-dir>
```

Substitute `<ida-sdk-path>` with the IDA SDK 9.4 directory (the one holding
`include/` and `lib/`) and `<ida-install-dir>` with your IDA installation.
Extra arguments after the options are passed to CMake verbatim.

## Contributors

* [Jinmo][02]
* [Blue DeviL // SCT][03]

## Authors

* [Joel Höner][01]

## License

[MIT][04]

[01]: https://github.com/athre0z
[02]: https://github.com/jinmo
[03]: https://github.com/blue-devil
[04]: ./LICENSE
