function(get_version_from_file VERSION_VAR)
    # argument parsing
    set(options NO_OVERWRITE)
    set(oneValueArgs FILEPATH)
    set(multiValueArgs "")
    cmake_parse_arguments(
            arg
            "${options}"
            "${oneValueArgs}"
            "${multiValueArgs}"
            ${ARGN}
    )

    list(LENGTH arg_UNPARSED_ARGUMENTS ualen)
    if (NOT ("${ualen}" EQUAL 0))
        message(FATAL_ERROR "argument error in get_version_from_file")
    endif ()

    # check if parent scope already has version info
    set(VERSION_VALUE "${${VERSION_VAR}}")
    if (("${VERSION_VALUE}" STREQUAL "") OR ("${VERSION_VALUE}" STREQUAL "0.0.0") OR ("${VERSION_VALUE}" STREQUAL "0.0") OR ("${VERSION_VALUE}" STREQUAL "0"))
        set(PARENT_VERSION_IS_SET FALSE)
    else ()
        set(PARENT_VERSION_IS_SET TRUE)
    endif ()

    if (${PARENT_VERSION_IS_SET} AND (NOT ${arg_NO_OVERWRITE}))
        message(WARNING "${VERSION_VAR} has value which will be overwritten in get_version_from_file(...)")
    endif ()

    # check filepath
    if ("${arg_FILEPATH}" STREQUAL "")
        set(arg_FILEPATH "${CMAKE_SOURCE_DIR}/VERSION")
    endif ()

    # read file
    file(READ "${arg_FILEPATH}" VERSION_VALUE)
    string(REGEX MATCH "^v?([0-9]+\\.[0-9]+\\.[0-9]+)" _ "${VERSION_VALUE}")
    set(VERSION_VALUE "${CMAKE_MATCH_1}")

    # set version
    if ((NOT ${arg_NO_OVERWRITE}) OR (NOT ${PARENT_VERSION_IS_SET}))
        set(${VERSION_VAR} "${VERSION_VALUE}")
        set(${VERSION_VAR} "${VERSION_VALUE}" PARENT_SCOPE)
    endif ()

    # check SemVer compliance
    string(REPLACE "." ";" VERSION_LIST "${${VERSION_VAR}}")
    list(LENGTH VERSION_LIST VERSION_LENGTH)
    if (NOT (${VERSION_LENGTH} EQUAL 3))
        message(FATAL_ERROR "get_version_from_file: ${VERSION_VALUE} is not SemVer 2.0.0 compliant")
    endif ()
endfunction()


function(enforce_git_version_consistency VERSION)
    # argument parsing
    set(options NO_FORCE)
    set(oneValueArgs RESULT_VAR)
    set(multiValueArgs "")
    cmake_parse_arguments(
            arg
            "${options}"
            "${oneValueArgs}"
            "${multiValueArgs}"
            ${ARGN}
    )

    list(LENGTH arg_UNPARSED_ARGUMENTS ualen)
    if (NOT ("${ualen}" EQUAL 0))
        message(FATAL_ERROR "argument error in enforce_git_version_consistency")
    endif ()

    # read git branches
    execute_process(
            COMMAND git rev-parse --abbrev-ref HEAD
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            OUTPUT_VARIABLE BRANCH_NAMES
            RESULT_VARIABLE retval
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if (NOT ("${retval}" EQUAL 0))
        message(FATAL_ERROR "Cannot read git branch name in enforce_git_version_consistency(...)")
    endif ()

    # read git tags
    execute_process(
            COMMAND git tag --points-at HEAD
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            OUTPUT_VARIABLE TAG_NAMES
            RESULT_VARIABLE retval
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if (NOT ("${retval}" EQUAL 0))
        message(FATAL_ERROR "Cannot read git tags in enforce_git_version_consistency(...)")
    endif ()
    string(REPLACE "\n" ";" TAG_NAMES "${TAG_NAMES}")

    # check if branches or tags are releases
    set(GIT_RELEASE_VERSIONS "")
    foreach (gitversion IN LISTS BRANCH_NAMES TAG_NAMES)
        string(REGEX MATCH "^(release/)?v?([0-9]+\\.?[0-9]*\\.?[0-9]*)" _ "${gitversion}")
        set(gitversion "${CMAKE_MATCH_2}")
        if (NOT ("${gitversion}" STREQUAL ""))
            list(APPEND GIT_RELEASE_VERSIONS "${gitversion}")
        endif ()
    endforeach ()

    # loop over versions and check compatability
    set(GIT_RELEASE_VERSIONS_COMPATIBLE "")
    foreach (gitversion IN LISTS GIT_RELEASE_VERSIONS)
        check_version_compatability("${VERSION}" "${gitversion}" VERSION_COMPATIBLE)
        list(APPEND GIT_RELEASE_VERSIONS_COMPATIBLE "${VERSION_COMPATIBLE}")
    endforeach ()

    # check if one version was not compatible
    list(FIND GIT_RELEASE_VERSIONS_COMPATIBLE "FALSE" FIND_RESULT)
    if (NOT ("${arg_RESULT_VAR}" STREQUAL ""))
        if ("${FIND_RESULT}" EQUAL -1)
            set("${arg_RESULT_VAR}" TRUE PARENT_SCOPE)
        else ()
            set("${arg_RESULT_VAR}" FALSE PARENT_SCOPE)
        endif ()
    endif ()

    # enforce
    if (${arg_NO_FORCE})
        message(WARNING "enforce_git_version_consistency: git branch or tag version is not compatible with ${VERSION}")
    else ()
        message(FATAL_ERROR "enforce_git_version_consistency: git branch or tag version is not compatible with ${VERSION}")
    endif ()
endfunction()


function(check_version_compatability VERSION1 VERSION2 RESULT_VAR)
    string(REPLACE "." ";" VERSION_LIST1 "${VERSION1}")
    string(REPLACE "." ";" VERSION_LIST2 "${VERSION2}")
    list(LENGTH VERSION_LIST1 VERSION_LENGTH1)
    list(LENGTH VERSION_LIST2 VERSION_LENGTH2)

    # check major version
    list(GET VERSION_LIST1 0 VERSION_MAJOR1)
    list(GET VERSION_LIST2 0 VERSION_MAJOR2)

    if ("${VERSION_MAJOR1}" EQUAL "${VERSION_MAJOR2}")
        set(VERSION_MAJOR_COMPATIBLE TRUE)
    else ()
        set(VERSION_MAJOR_COMPATIBLE FALSE)
    endif ()

    # check minor version
    if ("${VERSION_LENGTH1}" GREATER_EQUAL 2)
        list(GET VERSION_LIST1 1 VERSION_MINOR1)
    else ()
        set(VERSION_MINOR1 "")
    endif ()
    if ("${VERSION_LENGTH2}" GREATER_EQUAL 2)
        list(GET VERSION_LIST2 1 VERSION_MINOR2)
    else ()
        set(VERSION_MINOR2 "")
    endif ()

    if (("${VERSION_MINOR1}" EQUAL "${VERSION_MINOR2}") OR ("${VERSION_MINOR1}" STREQUAL "") OR ("${VERSION_MINOR2}" STREQUAL ""))
        set(VERSION_MINOR_COMPATIBLE TRUE)
    else ()
        set(VERSION_MINOR_COMPATIBLE FALSE)
    endif ()

    # check patch version
    if ("${VERSION_LENGTH1}" GREATER_EQUAL 3)
        list(GET VERSION_LIST1 2 VERSION_PATCH1)
    else ()
        set(VERSION_PATCH1 "")
    endif ()
    if ("${VERSION_LENGTH2}" GREATER_EQUAL 3)
        list(GET VERSION_LIST2 2 VERSION_PATCH2)
    else ()
        set(VERSION_PATCH2 "")
    endif ()

    if (("${VERSION_PATCH1}" EQUAL "${VERSION_PATCH2}") OR ("${VERSION_PATCH1}" STREQUAL "") OR ("${VERSION_PATCH2}" STREQUAL ""))
        set(VERSION_PATCH_COMPATIBLE TRUE)
    else ()
        set(VERSION_PATCH_COMPATIBLE FALSE)
    endif ()

    # generate result
    if (NOT ("${RESULT_VAR}" STREQUAL ""))
        if (${VERSION_MAJOR_COMPATIBLE} AND ${VERSION_MINOR_COMPATIBLE} AND ${VERSION_PATCH_COMPATIBLE})
            set("${RESULT_VAR}" TRUE PARENT_SCOPE)
        else ()
            set("${RESULT_VAR}" FALSE PARENT_SCOPE)
        endif ()
    endif ()
endfunction()

get_version_from_file(TEXT_VERSION)
set(
        VERSION
        ${TEXT_VERSION}
        CACHE
        STRING
        "Version number of this project. Usually read from \"VERSION\" file in the root of this project."
)
