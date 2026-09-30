#!/bin/sh
# Builds a universal release for distribution with Developer ID, the way
# Xcode's Archive and Distribute App do: archives the app, then exports it
# signed with Developer ID, into .build/release/export/Hello Codex.app, and
# checks it.
set -eu
cd "$(dirname "$0")/.."

xcodebuild -quiet -project HelloCodex.xcodeproj -scheme HelloCodex -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath .build/release \
    -archivePath .build/release/HelloCodex.xcarchive \
    archive
xcodebuild -quiet -exportArchive -archivePath .build/release/HelloCodex.xcarchive \
    -exportOptionsPlist scripts/ExportOptions.plist -exportPath .build/release/export
scripts/verify.sh ".build/release/export/Hello Codex.app"
