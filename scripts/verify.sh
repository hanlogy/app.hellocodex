#!/bin/sh
# Fails unless the app at $1 has Hello Codex's bundle ID and a valid Developer
# ID signature.
set -eu
app=$1
bundle_id=com.hanlogy.hellocodex

id=$(plutil -extract CFBundleIdentifier raw -o - "$app/Contents/Info.plist")
if [ "$id" != "$bundle_id" ]; then
    echo "error: $app has the bundle ID $id" >&2
    exit 1
fi
codesign --verify --deep --strict "$app"
if ! codesign -dvv "$app" 2>&1 | grep -q '^Authority=Developer ID Application: Hanlogy AB'; then
    echo "error: $app isn't signed with Developer ID" >&2
    exit 1
fi
