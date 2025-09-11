cmake_minimum_required(VERSION 3.18)

project(rpath_probe LANGUAGES C CXX)

# Try to enable CUDA if available, but it is optional for this probe.
include(CheckLanguage)
check_language(CUDA)
if(CMAKE_CUDA_COMPILER)
  enable_language(CUDA)
endif()

# Print variables that influence install-time RPATH decisions and implicit dirs.
message(STATUS "CMAKE_INSTALL_RPATH='${CMAKE_INSTALL_RPATH}'")
message(STATUS "CMAKE_INSTALL_RPATH_USE_LINK_PATH='${CMAKE_INSTALL_RPATH_USE_LINK_PATH}'")
message(STATUS "CMAKE_SKIP_INSTALL_RPATH='${CMAKE_SKIP_INSTALL_RPATH}'")
message(STATUS "CMAKE_BUILD_WITH_INSTALL_RPATH='${CMAKE_BUILD_WITH_INSTALL_RPATH}'")

foreach(lang IN ITEMS C CXX CUDA)
  if(DEFINED CMAKE_${lang}_IMPLICIT_LINK_DIRECTORIES)
    message(STATUS "CMAKE_${lang}_IMPLICIT_LINK_DIRECTORIES='${CMAKE_${lang}_IMPLICIT_LINK_DIRECTORIES}'")
  endif()
  if(DEFINED CMAKE_${lang}_IMPLICIT_LINK_LIBRARIES)
    message(STATUS "CMAKE_${lang}_IMPLICIT_LINK_LIBRARIES='${CMAKE_${lang}_IMPLICIT_LINK_LIBRARIES}'")
  endif()
endforeach()

add_executable(rpath-probe main.c)

# Intentionally add a non-toolchain rpath at link time to observe install behavior.
# This uses the build directory's lib folder to avoid external deps.
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/shimlib)
add_library(shim SHARED ${CMAKE_CURRENT_SOURCE_DIR}/shim.c)
set_target_properties(shim PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/shimlib)

target_link_directories(rpath-probe PRIVATE ${CMAKE_BINARY_DIR}/shimlib)
target_link_libraries(rpath-probe PRIVATE shim)

# Add link-time rpath to the directory with our shim to see if install wipes it.
target_link_options(rpath-probe PRIVATE -Wl,-rpath,${CMAKE_BINARY_DIR}/shimlib)

install(TARGETS rpath-probe RUNTIME DESTINATION bin)

