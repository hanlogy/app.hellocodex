#!/bin/sh
# Builds a release signed with Developer ID and packages it as a notarized disk
# image for other Macs: .build/release/Hello-Codex-<version>.dmg, with the app
# and a shortcut to Applications to drag it to.
#
# Notarization uses credentials saved once in the keychain, under the profile
# in $NOTARY_PROFILE (hellocodex-notary by default):
#   xcrun notarytool store-credentials hellocodex-notary \
#       --apple-id <Apple ID> --team-id SRHSX6M8CZ
set -eu
cd "$(dirname "$0")/.."

profile=${NOTARY_PROFILE:-hellocodex-notary}
identity='Developer ID Application: Hanlogy AB (SRHSX6M8CZ)'
app=".build/release/export/Hello Codex.app"

scripts/build.sh
version=$(plutil -extract CFBundleShortVersionString raw -o - "$app/Contents/Info.plist")
dmg=".build/release/Hello-Codex-$version.dmg"

# The disk image's contents: the app, and a shortcut to Applications.
contents=$(mktemp -d "${TMPDIR:-/tmp}/hellocodex-dmg.XXXXXX")
ditto "$app" "$contents/Hello Codex.app"
ln -s /Applications "$contents/Applications"
hdiutil create -quiet -volname "Hello Codex" -srcfolder "$contents" -ov -format UDZO "$dmg"
codesign --sign "$identity" --timestamp "$dmg"

# Apple checks the disk image and the app in it; the ticket stapled to the disk
# image lets Gatekeeper open it even offline.
# notarytool succeeds even when Apple rejects the image, so the result is
# checked, and Apple's log says why it was rejected.
result=$(xcrun notarytool submit "$dmg" --keychain-profile "$profile" --wait --output-format json)
status=$(printf '%s' "$result" | plutil -extract status raw -o - -)
if [ "$status" != "Accepted" ]; then
    id=$(printf '%s' "$result" | plutil -extract id raw -o - -)
    echo "error: Apple didn't notarize $dmg: $status" >&2
    xcrun notarytool log "$id" --keychain-profile "$profile" >&2
    exit 1
fi
xcrun stapler staple "$dmg"
spctl --assess --type open --context context:primary-signature --verbose "$dmg"

echo "Made $dmg"
