@PACKAGE_INIT@

include(CMakeFindDependencyMacro)
# find_dependency(SomeDependency)

include("${CMAKE_CURRENT_LIST_DIR}/installTargets.cmake")
check_required_components("@PROJECT_NAME@")
message(STATUS "Found @PROJECT_NAME@: ${CMAKE_CURRENT_LIST_FILE} (found version \"@PROJECT_VERSION@\")")
