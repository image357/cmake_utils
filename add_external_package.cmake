include(CMakeParseArguments)

function(add_external_package)
    # argument parsing
    set(_add_external_package_opt EXACT FORCE)
    set(_add_external_package_sval VERSION SOURCE_DIR)
    set(_add_external_package_mval CMAKE_ARGS)
    cmake_parse_arguments(
            _add_external_package_arg
            "${_add_external_package_opt}"
            "${_add_external_package_sval}"
            "${_add_external_package_mval}"
            ${ARGN}
    )

    list(LENGTH _add_external_package_arg_UNPARSED_ARGUMENTS _add_external_package_ualen)
    if (NOT "${_add_external_package_ualen}" EQUAL 1)
        message(FATAL_ERROR "argument error in add_external_package")
    endif ()
    set(_add_external_package_arg_NAME "${_add_external_package_arg_UNPARSED_ARGUMENTS}")

    if ("${_add_external_package_arg_SOURCE_DIR}" STREQUAL "")
        set(
                _add_external_package_arg_SOURCE_DIR
                "${CMAKE_CURRENT_SOURCE_DIR}/external/${_add_external_package_arg_NAME}"
        )
    endif ()

    set(
            _add_external_package_arg_BUILD_DIR
            "${CMAKE_CURRENT_BINARY_DIR}/_external/${_add_external_package_arg_NAME}"
    )

    # check if package is already installed
    if (NOT "${_add_external_package_arg_FORCE}")
        if (${_add_external_package_arg_EXACT})
            find_package(${_add_external_package_arg_NAME} ${_add_external_package_arg_VERSION} EXACT QUIET)
        else ()
            find_package(${_add_external_package_arg_NAME} ${_add_external_package_arg_VERSION} QUIET)
        endif ()

        if ("${${_add_external_package_arg_NAME}_FOUND}")
            message(STATUS "Using global installation of ${_add_external_package_arg_NAME}")
            return()
        endif ()
    endif ()
    message(STATUS "Preparing local installation of ${_add_external_package_arg_NAME}")

    # check if install config is present
    IF (NOT EXISTS "${_add_external_package_arg_SOURCE_DIR}/CMakeLists.txt")
        message(FATAL_ERROR "Cannot find ${_add_external_package_arg_SOURCE_DIR}/CMakeLists.txt")
    endif ()

    # make build directory
    file(MAKE_DIRECTORY "${_add_external_package_arg_BUILD_DIR}")

    # prepare CMAKE_PREFIX_PATH
    if (NOT "${CMAKE_INSTALL_PREFIX}" IN_LIST CMAKE_PREFIX_PATH)
        list(PREPEND CMAKE_PREFIX_PATH "${CMAKE_INSTALL_PREFIX}")
    endif ()

    # Configure the external package
    execute_process(
            COMMAND
            "${CMAKE_COMMAND}"
            ${_add_external_package_arg_CMAKE_ARGS}
            "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
            "-DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}"
            "-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
            "-G"
            "${CMAKE_GENERATOR}"
            "${_add_external_package_arg_SOURCE_DIR}"
            WORKING_DIRECTORY
            "${_add_external_package_arg_BUILD_DIR}"
            RESULT_VARIABLE
            _add_external_package_configure_result
    )
    if (NOT ${_add_external_package_configure_result} EQUAL 0)
        message(FATAL_ERROR "Cannot configure external package")
    endif ()

    # Build the external package
    execute_process(
            COMMAND
            "${CMAKE_COMMAND}"
            "--build"
            "${_add_external_package_arg_BUILD_DIR}"
            RESULT_VARIABLE
            _add_external_package_build_result
    )
    if (NOT ${_add_external_package_build_result} EQUAL 0)
        message(FATAL_ERROR "Cannot build external package")
    endif ()

    # Install the external package
    execute_process(
            COMMAND
            "${CMAKE_COMMAND}"
            "--install"
            "${_add_external_package_arg_BUILD_DIR}"
            RESULT_VARIABLE
            _add_external_package_install_result
    )
    if (NOT ${_add_external_package_install_result} EQUAL 0)
        message(FATAL_ERROR "Cannot install external package")
    endif ()

    # done
    set("${_add_external_package_arg_NAME}_ROOT" "${CMAKE_INSTALL_PREFIX}" PARENT_SCOPE)
    message(STATUS "Local installation of ${_add_external_package_arg_NAME} - done")
endfunction()
