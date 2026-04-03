#!/usr/bin/env bash
# Build SunellSDK.framework from the Xcode project and package SunellSDK.xcframework for SwiftPM (root Package.swift).
#
# Output (default Release): Distribution/SunellSDK/SunellSDK.xcframework
#   - Device: generic/platform=iOS (typically ios-arm64)
#   - Simulator (default): **x86_64** only (Intel simulator slice: ios-x86_64-simulator).
#     Matches SunellBaseSDK.a / SunellP2PSDK.a (device + Intel sim only); v1 has **no arm64-simulator** (Apple Silicon host simulator).
#     When vendor libs add M-sim support: set SIMULATOR_ARCHS=arm64 or build both and merge.
#
# If you already built Release-iphoneos / Release-iphonesimulator frameworks in Xcode, use:
#   ./scripts/merge_release_frameworks_to_xcframework.sh
#
# Usage: from repo root ./scripts/build_sunell_xcframework.sh
# Optional env: SCHEME CONFIGURATION PROJECT OUTPUT_DIR BUILD_DIR SIMULATOR_ARCHS

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

SCHEME="${SCHEME:-SunellSDK}"
CONFIGURATION="${CONFIGURATION:-Release}"
PROJECT="${PROJECT:-${ROOT_DIR}/SunellSDK.xcodeproj}"
BUILD_DIR="${BUILD_DIR:-${ROOT_DIR}/build/xcframework}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT_DIR}/Distribution/SunellSDK}"
FRAMEWORK_NAME="SunellSDK"
# Simulator: x86_64 only to avoid arm64-simulator linking device arm64 static libs (v1: no Apple Silicon simulator).
SIMULATOR_ARCHS="${SIMULATOR_ARCHS:-x86_64}"

IOS_ARCHIVE="${BUILD_DIR}/${FRAMEWORK_NAME}-ios.xcarchive"
SIM_ARCHIVE="${BUILD_DIR}/${FRAMEWORK_NAME}-sim.xcarchive"
XCFRAMEWORK_OUT="${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"

echo "==> [${CONFIGURATION}] Archiving ${SCHEME} for iOS device…"
xcodebuild archive \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "generic/platform=iOS" \
  -archivePath "${IOS_ARCHIVE}" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=NO

IOS_FW="${IOS_ARCHIVE}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
if [[ ! -d "${IOS_FW}" ]]; then
  echo "error: iOS device framework not found: ${IOS_FW}" >&2
  exit 1
fi

HAVE_SIM=0
echo "==> [${CONFIGURATION}] Archiving ${SCHEME} for iOS Simulator (ARCHS=${SIMULATOR_ARCHS}, v1: Intel simulator)…"
if xcodebuild archive \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "${SIM_ARCHIVE}" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=YES \
  ARCHS="${SIMULATOR_ARCHS}" \
  VALID_ARCHS="${SIMULATOR_ARCHS}"
then
  SIM_FW="${SIM_ARCHIVE}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
  if [[ -d "${SIM_FW}" ]]; then
    HAVE_SIM=1
  fi
else
  echo "" >&2
  echo "warning: Simulator archive failed (build limited to x86_64 for prebuilt static libs)." >&2
  echo "warning: Output will be **device-only** xcframework. See: ./scripts/inspect_precompiled_a_platform.sh" >&2
  echo "" >&2
fi

rm -rf "${XCFRAMEWORK_OUT}"

if [[ "${HAVE_SIM}" -eq 1 ]]; then
  SIM_FW="${SIM_ARCHIVE}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
  echo "==> Creating xcframework (device + Intel simulator x86_64; v1: no arm64-simulator)…"
  xcodebuild -create-xcframework \
    -framework "${IOS_FW}" \
    -framework "${SIM_FW}" \
    -output "${XCFRAMEWORK_OUT}"
else
  echo "==> Creating xcframework (device only)…"
  xcodebuild -create-xcframework \
    -framework "${IOS_FW}" \
    -output "${XCFRAMEWORK_OUT}"
fi

echo "==> Slices:"
/usr/bin/find "${XCFRAMEWORK_OUT}" -maxdepth 2 -type d \( -name "ios-*" -o -name "ios-*-simulator" \) 2>/dev/null | sort || ls -la "${XCFRAMEWORK_OUT}"

echo "==> Done: ${XCFRAMEWORK_OUT}"
echo "    SPM: root Package.swift (binaryTarget path above); commit xcframework or use url+checksum."
