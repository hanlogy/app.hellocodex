#!/bin/sh
# Builds a release signed with Developer ID, quits the installed app, moves it
# to the Trash, installs the new build in /Applications, and opens it. For
# your own Mac; scripts/release.sh makes the notarized download for others.
set -eu
cd "$(dirname "$0")/.."

bundle_id=com.hanlogy.hellocodex
installed="/Applications/Hello Codex.app"
built=".build/release/export/Hello Codex.app"

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

scripts/build.sh

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
scripts/verify.sh "$installed"
open "$installed"
echo "Installed and opened $installed"
