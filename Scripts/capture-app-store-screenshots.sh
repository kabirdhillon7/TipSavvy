#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULT_BUNDLE="${PROJECT_ROOT}/build/AppStoreScreenshots.xcresult"
ATTACHMENTS_DIR="${PROJECT_ROOT}/build/AppStoreScreenshotAttachments"
DESTINATION="${1:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest}"
OUTPUT_DIR="${PROJECT_ROOT}/AppStoreScreenshots/${2:-iPhone-17-Pro-Max}"

cd "${PROJECT_ROOT}"

rm -rf "${RESULT_BUNDLE}" "${ATTACHMENTS_DIR}" "${OUTPUT_DIR}"
mkdir -p "${ATTACHMENTS_DIR}" "${OUTPUT_DIR}"

xcodebuild test \
  -project Tippy.xcodeproj \
  -scheme Tippy \
  -destination "${DESTINATION}" \
  -only-testing:TippyUITests/AppStoreScreenshotTests \
  -resultBundlePath "${RESULT_BUNDLE}" \
  CODE_SIGNING_ALLOWED=NO

xcrun xcresulttool export attachments \
  --path "${RESULT_BUNDLE}" \
  --output-path "${ATTACHMENTS_DIR}"

awk '
  /"exportedFileName"/ {
    exported = $3
    gsub(/[",]/, "", exported)
  }
  /"suggestedHumanReadableName"/ {
    suggested = $3
    gsub(/[",]/, "", suggested)
    print exported "\t" suggested
  }
' "${ATTACHMENTS_DIR}/manifest.json" |
  while IFS=$'\t' read -r exported suggested; do
    case "${suggested}" in
      01-calculator-ready-to-split*) cp "${ATTACHMENTS_DIR}/${exported}" "${OUTPUT_DIR}/01-calculator-ready-to-split.png" ;;
      02-saved-tips-library*) cp "${ATTACHMENTS_DIR}/${exported}" "${OUTPUT_DIR}/02-saved-tips-library.png" ;;
      03-saved-tip-details*) cp "${ATTACHMENTS_DIR}/${exported}" "${OUTPUT_DIR}/03-saved-tip-details.png" ;;
      04-settings-and-privacy*) cp "${ATTACHMENTS_DIR}/${exported}" "${OUTPUT_DIR}/04-settings-and-privacy.png" ;;
    esac
  done

echo "Screenshots exported to ${OUTPUT_DIR}"
