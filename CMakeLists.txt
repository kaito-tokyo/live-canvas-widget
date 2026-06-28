# SPDX-FileCopyrightText: 2026 Kaito Udagawa <umireon@kaito.tokyo>
#
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.28)

### Options
set(PLUGIN_DISPLAY_NAME "Live Canvas Widget" CACHE STRING "Plugin display name")
set(PLUGIN_AUTHOR "Kaito Udagawa" CACHE STRING "Plugin author")
set(PLUGIN_EMAIL "umireon@kaito.tokyo" CACHE STRING "Plugin email")
set(PLUGIN_BUILD_NUMBER "1" CACHE STRING "Plugin build number")
set(PLUGIN_BUNDLE_ID "tokyo.kaito.live-canvas-widget" CACHE STRING "Plugin bundle ID (macOS)")
set(PLUGIN_VERSION_SUFFIX "-SNAPSHOT" CACHE STRING "Version suffix")

### Project
block(PROPAGATE PLUGIN_VERSION)
  file(READ "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" VERSION_CONTENT)
  string(STRIP "${VERSION_CONTENT}" PLUGIN_VERSION)
endblock()

project(live-canvas-widget VERSION "${PLUGIN_VERSION}" LANGUAGES C CXX)
set(PLUGIN_NAME "${CMAKE_PROJECT_NAME}" CACHE STRING "Plugin name" FORCE)

include(GNUInstallDirs)

### Global configurations
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS FALSE)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS FALSE)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(MSVC)
  add_compile_definitions(NOMINMAX WIN32_LEAN_AND_MEAN UNICODE _UNICODE)
  add_compile_options(
    /utf-8
    /Zc:preprocessor
    $<$<COMPILE_LANGUAGE:CXX>:/permissive->
    $<$<COMPILE_LANGUAGE:CXX>:/Zc:__cplusplus>
  )
else()
  add_compile_options(-fno-omit-frame-pointer -fstack-protector-strong)
endif()

set(CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO RelWithDebInfo Release)

### Configure paths
if(DEFINED ENV{PLUGIN_BUILD_DIR})
  set(PLUGIN_BUILD_DIR "$ENV{PLUGIN_BUILD_DIR}")
else()
  set(PLUGIN_BUILD_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
endif()

if(APPLE)
  list(
    PREPEND CMAKE_PREFIX_PATH
    "${PLUGIN_BUILD_DIR}/.deps/obs-deps-prebuilt"
    "${PLUGIN_BUILD_DIR}/.deps/obs-deps-qt6"
    "${PLUGIN_BUILD_DIR}/obs_installed"
    "${PLUGIN_BUILD_DIR}/obs_installed/Frameworks"
  )
endif()

### Package dependencies
find_package(libobs REQUIRED)
find_package(obs-frontend-api REQUIRED)

### Plugin main
add_library(${CMAKE_PROJECT_NAME}_options INTERFACE)
target_compile_definitions(
  ${CMAKE_PROJECT_NAME}_options
  INTERFACE PLUGIN_VERSION="${PLUGIN_VERSION}" PLUGIN_VERSION_SUFFIX="${PLUGIN_VERSION_SUFFIX}"
)

if(NOT MSVC)
  target_compile_definitions(${CMAKE_PROJECT_NAME}_options INTERFACE SIMDE_ENABLE_OPENMP)
  target_compile_options(${CMAKE_PROJECT_NAME}_options INTERFACE -fopenmp-simd -Wall -Wextra -Werror)
endif()

add_library(${CMAKE_PROJECT_NAME} MODULE)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_PROJECT_NAME}_options OBS::libobs OBS::obs-frontend-api)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

target_sources(${CMAKE_PROJECT_NAME} PRIVATE src/plugin-main.cpp)

### Hide symbols
if(MSVC)
  target_sources(${CMAKE_PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src/exported/windows.def")
elseif(APPLE)
  target_link_options(
    ${CMAKE_PROJECT_NAME}
    PRIVATE "-Wl,-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/src/exported/macos.txt"
  )
else()
  target_link_options(
    ${CMAKE_PROJECT_NAME}
    PRIVATE "-Wl,--version-script,${CMAKE_CURRENT_SOURCE_DIR}/src/exported/linux.map" "-Wl,-Bsymbolic"
  )
endif()

### Install configurations
if(APPLE)
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/distribution/macos/Info.plist.in"
    "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
    @ONLY
  )

  set(DATA_ROOT_FILES data/manifest.json data/REUSE.toml)

  set_target_properties(
    ${CMAKE_PROJECT_NAME}
    PROPERTIES BUNDLE ON BUNDLE_EXTENSION "plugin" MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
  )
  set_source_files_properties(${DATA_ROOT_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
  target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${DATA_ROOT_FILES})

  install(
    TARGETS ${CMAKE_PROJECT_NAME}
    BUNDLE DESTINATION "Library/Application Support/obs-studio/plugins"
    LIBRARY DESTINATION "Library/Application Support/obs-studio/plugins"
  )
else()
  message("Installing on this platform is not supported.")
endif()

### Packaging
include(cmake/packaging.cmake)

if(APPLE)
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/distribution/macos/Distribution.xml.in"
    "${CMAKE_CURRENT_BINARY_DIR}/Distribution"
    @ONLY
  )

  packaging_add_pkg_targets(
    "${PLUGIN_BUILD_DIR}/release"
    "${CMAKE_CURRENT_BINARY_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_BINARY_DIR}/Distribution"
  )
endif()
