#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
destination="${SOBERCONTROL_DESTINATION:-platform=iOS Simulator,name=iPhone 18 Pro}"
xcodebuild test \
  -project SoberControl.xcodeproj \
  -scheme SoberControl \
  -destination "$destination" \
  -parallel-testing-enabled NO \
  -derivedDataPath "${SOBERCONTROL_DERIVED_DATA:-build/DerivedData}" \
  CODE_SIGNING_ALLOWED=NO
