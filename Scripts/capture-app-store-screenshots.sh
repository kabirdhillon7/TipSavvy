#!/usr/bin/env bash
# Captures the raw App Store screenshots on one simulator.
#
#   Scripts/capture-app-store-screenshots.sh <device> [simulator name]
#
# <device> is the raw folder the captures land in, and must match a device in
# AppStoreScreenshots/source/devices.json:
#   iphone   iPhone 6.9" (default simulator: iPhone 18 Pro Max)
#   ipad     iPad 13"    (default simulator: iPad Pro 13-inch (M5))
#   duo-outer / duo-inner  iPhone Duo: fold or unfold it in Xcode's Device Hub
#            first, then pass the Duo simulator's name.
#
# Output: AppStoreScreenshots/raw/<device>/01-enter-the-bill.png … 04-save-it.png
# Then run Scripts/render-app-store-screenshots.sh to build the final PNGs.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE="${1:-iphone}"

case "${DEVICE}" in
  iphone) DEFAULT_SIM="iPhone 18 Pro Max" ;;
  ipad) DEFAULT_SIM="iPad Pro 13-inch (M5)" ;;
  duo-outer|duo-inner) DEFAULT_SIM="iPhone Duo" ;;
  *) echo "Unknown device '${DEVICE}'. Use iphone, ipad, duo-outer or duo-inner." >&2; exit 1 ;;
esac
SIMULATOR="${2:-${DEFAULT_SIM}}"

RESULT_BUNDLE="${PROJECT_ROOT}/build/AppStoreScreenshots-${DEVICE}.xcresult"
ATTACHMENTS_DIR="${PROJECT_ROOT}/build/AppStoreScreenshotAttachments-${DEVICE}"
OUTPUT_DIR="${PROJECT_ROOT}/AppStoreScreenshots/raw/${DEVICE}"

cd "${PROJECT_ROOT}"

rm -rf "${RESULT_BUNDLE}" "${ATTACHMENTS_DIR}"
mkdir -p "${ATTACHMENTS_DIR}" "${OUTPUT_DIR}"

# Light mode for the App Store set. Shot 1 also needs the on-screen keypad: if it
# comes out without one, turn on the simulator's on-screen keyboard (Device Hub,
# or ask Claude to) while the device stays booted, then run this again.
xcrun simctl boot "${SIMULATOR}" 2>/dev/null || true
xcrun simctl ui "${SIMULATOR}" appearance "${APPEARANCE:-light}"

# On an unfolded Duo, XCUIScreen.main is still the outer screen; ask the test for the inner one.
if [[ "${DEVICE}" == "duo-inner" ]]; then
  export TEST_RUNNER_SCREENSHOT_SCREEN=largest
fi

xcodebuild test \
  -project Tippy.xcodeproj \
  -scheme Tippy \
  -destination "platform=iOS Simulator,name=${SIMULATOR},OS=latest" \
  -only-testing:TippyUITests/AppStoreScreenshotTests \
  -parallel-testing-enabled NO \
  -resultBundlePath "${RESULT_BUNDLE}" \
  CODE_SIGNING_ALLOWED=NO

xcrun xcresulttool export attachments \
  --path "${RESULT_BUNDLE}" \
  --output-path "${ATTACHMENTS_DIR}"

# manifest.json maps each exported file to the name the test gave its attachment.
SHOTS="01-enter-the-bill 02-pick-the-tip 03-split-it-fairly 04-save-it"
/usr/bin/python3 - "${ATTACHMENTS_DIR}" "${OUTPUT_DIR}" ${SHOTS} <<'PY'
import json, shutil, sys, pathlib
attachments, output, shots = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3:]
found = {}
for test in json.loads((attachments / "manifest.json").read_text()):
    for item in test.get("attachments", []):
        name = item.get("suggestedHumanReadableName", "")
        for shot in shots:
            if name.startswith(shot):
                found[shot] = attachments / item["exportedFileName"]
for shot in shots:
    if shot in found:
        shutil.copy(found[shot], output / f"{shot}.png")
        print(f"  {shot}.png")
    else:
        print(f"  MISSING {shot}", file=sys.stderr)
if len(found) != len(shots):
    sys.exit(1)
PY

# XCUITest hands back the Duo inner screen turned 180°; put it upright.
if [[ "${DEVICE}" == "duo-inner" ]]; then
  for f in "${OUTPUT_DIR}"/*.png; do sips --rotate 180 "$f" >/dev/null; done
fi

echo "Raw captures saved to ${OUTPUT_DIR}"
