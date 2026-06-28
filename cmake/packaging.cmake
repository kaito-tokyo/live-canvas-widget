# SPDX-FileCopyrightText: 2026 Kaito Udagawa <umireon@kaito.tokyo>
#
# SPDX-License-Identifier: Apache-2.0

if(APPLE)
  set(
    MACOS_SIGNING_APPLICATION_IDENTITY
    "$ENV{MACOS_SIGNING_APPLICATION_IDENTITY}"
    CACHE STRING
    "Developer ID Application (macOS)"
  )
  set(
    MACOS_SIGNING_INSTALLER_IDENTITY
    "$ENV{MACOS_SIGNING_INSTALLER_IDENTITY}"
    CACHE STRING
    "Developer ID Installer (macOS)"
  )
endif()

function(packaging_add_pkg_targets OUTPUT_DIR BINARY_DIR INPUT_RESOURCES_DIR INPUT_DISTRIBUTION_FILE)
  add_custom_target(
    package_pkg_nosign
    DEPENDS "${CMAKE_PROJECT_NAME}" "${INPUT_DISTRIBUTION_FILE}"
    COMMAND rm -rf nosign
    COMMAND mkdir -p nosign/prefix "${OUTPUT_DIR}"
    COMMAND "${CMAKE_COMMAND}" --install "${BINARY_DIR}" --config "$<CONFIG>" --prefix nosign/prefix --strip
    COMMAND dot_clean -m "nosign/prefix"
    COMMAND xattr -cr "nosign/prefix"
    COMMAND
      pkgbuild --root "${BINARY_DIR}/nosign/prefix" --identifier "${PLUGIN_BUNDLE_ID}" --version "${PLUGIN_VERSION}"
      --install-location / "${BINARY_DIR}/nosign/component.pkg"
    COMMAND
      productbuild --distribution "${INPUT_DISTRIBUTION_FILE}" --package-path "${BINARY_DIR}/nosign" --resources
      "${INPUT_RESOURCES_DIR}"
      "${OUTPUT_DIR}/${PLUGIN_NAME}-${PLUGIN_VERSION}${PLUGIN_VERSION_SUFFIX}-macos-universal-nosign.pkg"
    WORKING_DIRECTORY "${BINARY_DIR}"
    VERBATIM
  )

  add_custom_target(
    package_pkg_signed
    DEPENDS "${CMAKE_PROJECT_NAME}" "${INPUT_DISTRIBUTION_FILE}"
    COMMAND rm -rf signed
    COMMAND mkdir -p signed/prefix "${OUTPUT_DIR}"
    COMMAND "${CMAKE_COMMAND}" --install "${BINARY_DIR}" --config "$<CONFIG>" --prefix signed/prefix --strip
    COMMAND dot_clean -m signed/prefix
    COMMAND xattr -cr signed/prefix
    COMMAND /bin/sh -c "[ -z \"$(xattr -lr signed/prefix)\" ]"
    COMMAND
      codesign -s "${MACOS_SIGNING_APPLICATION_IDENTITY}" -f --deep --options runtime --timestamp
      "${BINARY_DIR}/signed/prefix/Library/Application Support/obs-studio/plugins/${PLUGIN_NAME}.plugin"
    COMMAND
      pkgbuild --root "${BINARY_DIR}/signed/prefix" --identifier "${PLUGIN_BUNDLE_ID}" --version "${PLUGIN_VERSION}"
      --install-location / "${BINARY_DIR}/signed/component.pkg"
    COMMAND
      productbuild --sign "${MACOS_SIGNING_INSTALLER_IDENTITY}" --distribution "${INPUT_DISTRIBUTION_FILE}"
      --package-path "${BINARY_DIR}/signed" --resources "${INPUT_RESOURCES_DIR}"
      "${OUTPUT_DIR}/${PLUGIN_NAME}-${PLUGIN_VERSION}${PLUGIN_VERSION_SUFFIX}-macos-universal.pkg"
    WORKING_DIRECTORY "${BINARY_DIR}"
    VERBATIM
  )
endfunction()
