#!/bin/sh
set -eu

ROOT_DIR="${CI_WORKSPACE:-$(pwd)}/repository"
if [ ! -d "$ROOT_DIR" ]; then
  ROOT_DIR="$(pwd)"
fi

GOOGLE_SERVICE_PLIST="$ROOT_DIR/GoogleService-Info.plist"
GOOGLE_SERVICE_EXAMPLE="$ROOT_DIR/GoogleService-Info.plist.example"

if [ -n "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" ]; then
  echo "$GOOGLE_SERVICE_INFO_PLIST_BASE64" | base64 --decode > "$GOOGLE_SERVICE_PLIST"
  echo "Created GoogleService-Info.plist from GOOGLE_SERVICE_INFO_PLIST_BASE64."
elif [ -n "${GOOGLE_SERVICE_INFO_PLIST:-}" ]; then
  printf '%s' "$GOOGLE_SERVICE_INFO_PLIST" > "$GOOGLE_SERVICE_PLIST"
  echo "Created GoogleService-Info.plist from GOOGLE_SERVICE_INFO_PLIST."
elif [ -f "$GOOGLE_SERVICE_EXAMPLE" ]; then
  cp "$GOOGLE_SERVICE_EXAMPLE" "$GOOGLE_SERVICE_PLIST"
  echo "Created GoogleService-Info.plist from example placeholder."
else
  echo "error: GoogleService-Info.plist.example is missing." >&2
  exit 1
fi
