#!/bin/sh
# Builds a release signed with Developer ID, quits the installed app, moves it
# to the Trash, installs the new build in /Applications, and opens it.
set -eu
cd "$(dirname "$0")/.."

bundle_id=com.hanlogy.hellocodex
installed="/Applications/Hello Codex.app"
built=".build/release/Build/Products/Release/Hello Codex.app"

# Fails unless the app has the bundle ID and a valid Developer ID signature.
verify() {
    id=$(plutil -extract CFBundleIdentifier raw -o - "$1/Contents/Info.plist")
    if [ "$id" != "$bundle_id" ]; then
        echo "error: $1 has the bundle ID $id" >&2
        return 1
    fi
    codesign --verify --deep --strict "$1"
    if ! codesign -dvv "$1" 2>&1 | grep -q '^Authority=Developer ID Application: Hanlogy AB'; then
        echo "error: $1 isn't signed with Developer ID" >&2
        return 1
    fi
}

# Runs JavaScript for Automation with the installed app's path and bundle ID.
jxa() {
    osascript -l JavaScript -e "ObjC.import('AppKit');
        var installed = '$installed', bundleID = '$bundle_id';
        $1"
}

# The number of running copies of the installed app, found by its path as well
# as its bundle ID: other builds, such as a debug build, share the bundle ID.
# With "quit", also asks each to quit, as ⌘Q does.
installed_copies() {
    jxa "var apps = \$.NSWorkspace.sharedWorkspace.runningApplications, count = 0;
        for (var i = 0; i < apps.count; i++) {
            var app = apps.objectAtIndex(i);
            if (ObjC.unwrap(app.bundleIdentifier) === bundleID &&
                ObjC.unwrap(app.bundleURL.path) === installed) {
                count++;
                if ('${1-}' === 'quit') { app.terminate; }
            }
        }
        count;"
}

xcodebuild -quiet -project HelloCodex.xcodeproj -scheme HelloCodex -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath .build/release \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY='Developer ID Application' DEVELOPMENT_TEAM=SRHSX6M8CZ \
    OTHER_CODE_SIGN_FLAGS=--timestamp \
    build
verify "$built"

if [ "$(installed_copies quit)" -gt 0 ]; then
    tries=0
    while [ "$(installed_copies)" -gt 0 ]; do
        tries=$((tries + 1))
        if [ "$tries" -gt 30 ]; then
            echo "error: $installed didn't quit, so it wasn't replaced" >&2
            exit 1
        fi
        sleep 0.5
    done
fi

if [ -e "$installed" ]; then
    jxa "var error = \$();
        if (!\$.NSFileManager.defaultManager.trashItemAtURLResultingItemURLError(
            \$.NSURL.fileURLWithPath(installed), null, error)) {
            throw new Error('Could not move ' + installed + ' to the Trash');
        }" >/dev/null
    echo "Moved the old $installed to the Trash"
fi

ditto "$built" "$installed"
verify "$installed"
open "$installed"
echo "Installed and opened $installed"
