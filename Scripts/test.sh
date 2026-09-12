#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p Artifacts
swift test
riverlab_result_bundle="Artifacts/UITests-$(date +%Y%m%d-%H%M%S).xcresult"
xcodebuild \
  -project RiverLab.xcodeproj \
  -scheme RiverLab \
  -destination "${RIVERLAB_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}" \
  -derivedDataPath .derivedData \
  -parallel-testing-enabled NO \
  -resultBundlePath "$riverlab_result_bundle" \
  CODE_SIGNING_ALLOWED=NO \
  test > Artifacts/ui-tests.log 2>&1
tail -n 8 Artifacts/ui-tests.log
