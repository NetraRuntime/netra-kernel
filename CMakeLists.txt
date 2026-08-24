cmake_minimum_required(VERSION 3.21)
project(netra_engine VERSION 0.3.0 LANGUAGES CXX HIP)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

add_library(netra_engine SHARED runtime/gfx950/engine/netra_engine.hip)
target_compile_features(netra_engine PRIVATE cxx_std_17)
target_compile_definitions(netra_engine PRIVATE NETRA_ENGINE_BUILDING_LIBRARY=1)
target_include_directories(netra_engine
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
set_target_properties(netra_engine PROPERTIES
  VERSION ${PROJECT_VERSION}
  SOVERSION 1
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN YES
)

configure_file(cmake/netra-engine.pc.in netra-engine.pc @ONLY)
configure_package_config_file(
  cmake/netra-engine-config.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/netra-engine-config.cmake
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/netra-engine
)

install(TARGETS netra_engine
  EXPORT netra-engine-targets
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(EXPORT netra-engine-targets
  FILE netra-engine-targets.cmake
  NAMESPACE netra::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/netra-engine
)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/netra-engine-config.cmake
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/netra-engine
)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/netra-engine.pc
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)
