@PACKAGE_INIT@

include(CMakeFindDependencyMacro)
#find_dependency(Boost COMPONENTS system)

# add search path
if (NOT "${CMAKE_CURRENT_LIST_DIR}" IN_LIST CMAKE_MODULE_PATH)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
endif ()

# include targets
include("${CMAKE_CURRENT_LIST_DIR}/installTargets.cmake")
check_required_components("@PROJECT_NAME@")

# status message
if (NOT DEFINED @PROJECT_NAME@_FOUND)
set(@PROJECT_NAME@_ROOT "${CMAKE_CURRENT_LIST_DIR}/..")
cmake_path(NORMAL_PATH @PROJECT_NAME@_ROOT)
string(REGEX REPLACE "/$" "" @PROJECT_NAME@_ROOT "${@PROJECT_NAME@_ROOT}")
message(STATUS "Found @PROJECT_NAME@: ${@PROJECT_NAME@_ROOT} (found version \"@PROJECT_VERSION@\")")
endif ()
