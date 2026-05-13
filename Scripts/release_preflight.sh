#!/bin/bash

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_DIR="$ROOT_DIR/Tippy/Assets.xcassets/AppIcon.appiconset"
INFO_PLIST="$ROOT_DIR/Tippy/Info.plist"
README="$ROOT_DIR/README.md"
GOOGLE_SERVICE_PLIST="$ROOT_DIR/GoogleService-Info.plist"
GOOGLE_SERVICE_EXAMPLE="$ROOT_DIR/GoogleService-Info.plist.example"
COMPROMISED_GOOGLE_API_KEY="AIzaSyCcHuamnEEhy3jd6f7-zA7xlPc8SWfv""VGo"

failures=0

pass() {
  printf "✅ %s\n" "$1"
}

fail() {
  printf "❌ %s\n" "$1"
  failures=$((failures + 1))
}

check_file() {
  local path="$1"
  local label="$2"

  if [[ -f "$path" ]]; then
    pass "$label exists"
  else
    fail "$label is missing: $path"
  fi
}

check_icon() {
  local filename="$1"
  local path="$ICON_DIR/$filename"

  if [[ ! -f "$path" ]]; then
    fail "App icon is missing: $filename"
    return
  fi

  local width
  local height
  local alpha
  width="$(sips -g pixelWidth "$path" 2>/dev/null | awk '/pixelWidth/ { print $2 }')"
  height="$(sips -g pixelHeight "$path" 2>/dev/null | awk '/pixelHeight/ { print $2 }')"
  alpha="$(sips -g hasAlpha "$path" 2>/dev/null | awk '/hasAlpha/ { print $2 }')"

  if [[ "$width" == "1024" && "$height" == "1024" && "$alpha" == "no" ]]; then
    pass "$filename is 1024x1024 with no alpha channel"
  else
    fail "$filename must be 1024x1024 and hasAlpha: no (got ${width:-unknown}x${height:-unknown}, hasAlpha: ${alpha:-unknown})"
  fi
}

printf "\nTipSavvy release preflight\n"
printf "==========================\n\n"

check_icon "TipSavvy-iOS-Default-1024x1024@1x.png"
check_icon "TipSavvy-iOS-Dark-1024x1024@1x.png"
check_icon "TipSavvy-iOS-TintedDark-1024x1024@1x.png"

check_file "$GOOGLE_SERVICE_EXAMPLE" "Firebase plist example"
if [[ -f "$GOOGLE_SERVICE_PLIST" ]]; then
  if grep -q "REPLACE_WITH_" "$GOOGLE_SERVICE_PLIST"; then
    fail "GoogleService-Info.plist still contains placeholder values; download the rotated Firebase config"
  elif grep -q "$COMPROMISED_GOOGLE_API_KEY" "$GOOGLE_SERVICE_PLIST"; then
    fail "GoogleService-Info.plist contains the revoked Google API key; replace it with the rotated Firebase config"
  else
    pass "GoogleService-Info.plist is present and does not contain known placeholders or the revoked key"
  fi
else
  fail "GoogleService-Info.plist is missing; download the rotated Firebase config to the repo root before release"
fi

if grep -R --exclude-dir=".git" --exclude="release_preflight.sh" -q "$COMPROMISED_GOOGLE_API_KEY" "$ROOT_DIR"; then
  fail "Working tree still contains the revoked Google API key"
else
  pass "Working tree does not contain the revoked Google API key"
fi

encryption_value="$(plutil -extract ITSAppUsesNonExemptEncryption raw "$INFO_PLIST" 2>/dev/null || true)"
if [[ "$encryption_value" == "0" || "$encryption_value" == "false" ]]; then
  pass "ITSAppUsesNonExemptEncryption is false"
else
  fail "ITSAppUsesNonExemptEncryption should be false (got ${encryption_value:-missing})"
fi

check_file "$ROOT_DIR/docs/AccessibilityChecklist.md" "Accessibility checklist"
check_file "$ROOT_DIR/docs/AppStoreScreenshotPlan.md" "App Store screenshot plan"
check_file "$ROOT_DIR/docs/ReleaseChecklist.md" "Release checklist"

if command -v xcodebuild >/dev/null 2>&1; then
  pass "xcodebuild is available"
else
  fail "xcodebuild is not available"
fi

if grep -q "xcodebuild build-for-testing" "$README"; then
  pass "README documents build-for-testing"
else
  fail "README should document xcodebuild build-for-testing"
fi

printf "\n"
if [[ "$failures" -eq 0 ]]; then
  printf "Release preflight passed.\n"
  exit 0
fi

printf "Release preflight failed with %d issue(s).\n" "$failures"
exit 1
