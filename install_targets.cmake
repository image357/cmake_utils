include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# prepare INSTALL_INCLUDEDIR
if (NOT DEFINED INSTALL_INCLUDEDIR)
    set(INSTALL_INCLUDEDIR "include")
endif ()

# write package and target configs
write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
        ${CMAKE_CURRENT_LIST_DIR}/installConfig.in.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
        INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}-${PROJECT_VERSION}
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

install(
        FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}-${PROJECT_VERSION}
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
    message(STATUS ${INCLUDE_DESTINATION})

    # prepare install source path
    list(GET INCDIR 0 INCDIR)
    string(STRIP "${INCDIR}" INCDIR)
    cmake_path(SET INCDIR NORMALIZE "${INCDIR}/")
    message(STATUS ${INCDIR})

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
