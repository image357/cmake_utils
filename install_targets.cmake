# INFO: example usage
# ----------------------------------------------------------------------------------------------------
## this is mandatory
#set(INSTALL_TARGETS local_target1 local_target2)
## this is optional - default include dir will be ${CMAKE_SOURCE_DIR}/include
#set(
#        INSTALL_INCLUDEDIR
#        "src" # copy all headers in src to ${CMAKE_INSTALL_INCLUDEDIR}
#        "some/path -> another/path" # copy all headers in some/path to ${CMAKE_INSTALL_INCLUDEDIR}/another/path
#)
## this is optional
#set(
#        INSTALL_INCLUDEFILE
#        "some/path/to/file.h" # install file.h to ${CMAKE_INSTALL_INCLUDEDIR}/file.h
#        "another/path/to/file.h -> foo/bar" # install file.h to ${CMAKE_INSTALL_INCLUDEDIR}/foo/bar/file.h
#)
## this is mandatory - execute script on the defined variables
#include(install_targets.cmake)
# ----------------------------------------------------------------------------------------------------

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# prepare INSTALL_INCLUDEDIR
if (NOT DEFINED INSTALL_INCLUDEDIR)
    set(INSTALL_INCLUDEDIR "include")
endif ()

# write package and target configs
write_basic_package_version_file(
        "${CMAKE_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
        "${CMAKE_SOURCE_DIR}/cmake/installConfig.in.cmake"
        "${CMAKE_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}-${PROJECT_VERSION}
)

install(
        FILES
        "${CMAKE_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        "${CMAKE_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}-${PROJECT_VERSION}
)

install(
        TARGETS ${INSTALL_TARGETS}
        EXPORT installTargets
)

install(
        EXPORT installTargets
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}-${PROJECT_VERSION}
        NAMESPACE ${PROJECT_NAME}::
)

# install header directories
foreach (INCDIR ${INSTALL_INCLUDEDIR})
    # split on seperator
    string(REPLACE "->" ";" INCDIR "${INCDIR}")
    list(LENGTH INCDIR INCDIR_LEN)

    # prepare install destination path
    set(INCLUDE_DESTINATION_SUBPATH "")
    if (INCDIR_LEN EQUAL 2)
        list(GET INCDIR 1 INCLUDE_DESTINATION_SUBPATH)
        string(STRIP "${INCLUDE_DESTINATION_SUBPATH}" INCLUDE_DESTINATION_SUBPATH)
    endif ()
    cmake_path(SET INCLUDE_DESTINATION NORMALIZE "${CMAKE_INSTALL_INCLUDEDIR}/${INCLUDE_DESTINATION_SUBPATH}")
    string(REGEX REPLACE "/$" "" INCLUDE_DESTINATION "${INCLUDE_DESTINATION}")

    # prepare install source path
    list(GET INCDIR 0 INCDIR)
    string(STRIP "${INCDIR}" INCDIR)
    cmake_path(SET INCDIR NORMALIZE "${INCDIR}/")

    # install directories
    install(
            DIRECTORY "${INCDIR}"
            DESTINATION "${INCLUDE_DESTINATION}"
            FILES_MATCHING PATTERN "*.hpp"
    )

    install(
            DIRECTORY "${INCDIR}"
            DESTINATION "${INCLUDE_DESTINATION}"
            FILES_MATCHING PATTERN "*.h"
    )
endforeach ()

# install specific headers
foreach (INCFILE ${INSTALL_INCLUDEFILE})
    # split on seperator
    string(REPLACE "->" ";" INCFILE "${INCFILE}")
    list(LENGTH INCFILE INCFILE_LEN)

    # prepare install destination path
    set(INCLUDE_DESTINATION_SUBPATH "")
    if (INCFILE_LEN EQUAL 2)
        list(GET INCFILE 1 INCLUDE_DESTINATION_SUBPATH)
        string(STRIP "${INCLUDE_DESTINATION_SUBPATH}" INCLUDE_DESTINATION_SUBPATH)
    endif ()
    cmake_path(SET INCLUDE_DESTINATION NORMALIZE "${CMAKE_INSTALL_INCLUDEDIR}/${INCLUDE_DESTINATION_SUBPATH}")
    string(REGEX REPLACE "/$" "" INCLUDE_DESTINATION "${INCLUDE_DESTINATION}")

    # prepare install source path
    list(GET INCFILE 0 INCFILE)
    string(STRIP "${INCFILE}" INCFILE)
    cmake_path(SET INCFILE NORMALIZE "${INCFILE}")

    install(
            FILES
            "${INCFILE}"
            DESTINATION "${INCLUDE_DESTINATION}"
    )
endforeach ()
