#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p Artifacts
xcodebuild \
  -project RiverLab.xcodeproj \
  -scheme RiverLab \
  -destination "${RIVERLAB_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}" \
  -derivedDataPath .derivedData \
  CODE_SIGNING_ALLOWED=NO \
  build > Artifacts/build.log 2>&1
tail -n 5 Artifacts/build.log
