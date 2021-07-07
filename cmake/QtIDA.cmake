# =============================================================================================== #
# Qt support                                                                                      #
# =============================================================================================== #

set(CMAKE_AUTOMOC True)
set(CMAKE_AUTORCC True)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(ida_qt_libs "Gui;Core;Widgets")

# Locate Qt.
find_package(Qt5Widgets 5.6 REQUIRED)

# On unixes, we link against the Qt libs that ship with IDA.
# On Windows with IDA versions >= 7.0, link against .libs in IDA SDK.
if (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin" OR ${CMAKE_SYSTEM_NAME} STREQUAL "Linux" OR
    (${CMAKE_SYSTEM_NAME} STREQUAL "Windows"))
        
    if (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
        set(ida_qt_glob_path "${IDA_INSTALL_DIR}/../Frameworks/Qt@QTLIB@")
    elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        set(ida_qt_glob_path "${IDA_INSTALL_DIR}/libQt5@QTLIB@.so*")
    elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
        set(ida_qt_glob_path "${IDA_SDK}/lib/x64_win_qt/Qt5@QTLIB@.lib")
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
        set_target_properties(
            "Qt5::${cur_lib}"
            PROPERTIES 
            ${lib_property} "${IDA_Qt${cur_lib}_LIBRARY}")
    endforeach()
endif ()
