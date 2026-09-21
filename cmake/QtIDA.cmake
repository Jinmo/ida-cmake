# ============================================================================ #
# Qt support                                                                   #
# ============================================================================ #

set(CMAKE_AUTOMOC True)
set(CMAKE_AUTORCC True)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(ida_qt_libs "Gui;Core;Widgets")

# Target architecture / OS detection for the SDK's directory layout. Included
# here as well as in IDA.cmake because this file is usually included first.
include("${CMAKE_CURRENT_LIST_DIR}/IDAArch.cmake")

# Locate Qt.
find_package(Qt6Widgets 6.8 REQUIRED)

# On unixes, we link against the Qt libs that ship with IDA.
# On Windows with IDA versions >= 7.0, link against .libs in IDA SDK.
if (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin" OR ${CMAKE_SYSTEM_NAME} STREQUAL "Linux" OR
    (${CMAKE_SYSTEM_NAME} STREQUAL "Windows"))
        
    if (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
        set(ida_qt_glob_path "${IDA_INSTALL_DIR}/../Frameworks/Qt@QTLIB@")
    elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        set(ida_qt_glob_path "${IDA_INSTALL_DIR}/libQt6@QTLIB@.so*")
    elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
        # x64_win_qt, arm64_win_qt, ... - derived from the target, not hardcoded.
        ida_sdk_qt_lib_dir(ida_qt_lib_dir)
        if (NOT ida_qt_lib_dir)
            message(FATAL_ERROR
                "No Qt import libraries for ${IDA_ARCH}_${IDA_OS} under ${IDA_SDK}/lib. "
                "An IDA plugin has to link against the Qt that IDA itself ships, so "
                "this SDK cannot build a ${IDA_ARCH} plugin.")
        endif ()
        set(ida_qt_glob_path "${ida_qt_lib_dir}/Qt6@QTLIB@.lib")
    endif ()

    foreach(cur_lib ${ida_qt_libs})
        string(REPLACE "@QTLIB@" ${cur_lib} cur_glob_path ${ida_qt_glob_path})
        file(GLOB_RECURSE qtlibpaths ${cur_glob_path})
        # On some platforms, we will find more than one libfile here. 
        # Either one is fine, just pick the first.
        foreach(p ${qtlibpaths})
            set(IDA_Qt${cur_lib}_LIBRARY ${p} CACHE FILEPATH "Path to IDA's Qt${cur_lib}")
            break()
        endforeach()
    endforeach()

    # On Windows, we hack Qt's "IMPLIB"s, on unix the .so location.
    if (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
        set(lib_property "IMPORTED_IMPLIB_RELEASE")
    else ()
        set(lib_property "IMPORTED_LOCATION_RELEASE")
    endif ()

    foreach (cur_lib ${ida_qt_libs})
        # Fail loudly here: an empty property silently drops the library from the
        # link line and surfaces much later as unresolved Qt symbols.
        if (NOT IDA_Qt${cur_lib}_LIBRARY)
            message(FATAL_ERROR
                "Could not locate IDA's Qt${cur_lib} for ${IDA_ARCH}_${IDA_OS}. "
                "Searched '${ida_qt_glob_path}'. "
                "Pass -DIDA_Qt${cur_lib}_LIBRARY=<path> to override.")
        endif ()
        set_target_properties(
            "Qt6::${cur_lib}"
            PROPERTIES
            ${lib_property} "${IDA_Qt${cur_lib}_LIBRARY}")
    endforeach()
endif ()
