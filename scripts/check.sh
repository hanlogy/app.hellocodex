#!/bin/sh
# Runs every check CI runs: formatting, the package's build and tests with
# warnings as errors, and the app's build.
set -eu

cd "$(dirname "$0")/.."

# Runs a command and fails on any warning in its output. -warnings-as-errors
# misses warnings from inside macro expansions, such as #expect. Builds are
# incremental, so a warning shows only in the run that compiles its file;
# CI builds from scratch and sees every one.
run() {
    output=$("$@" 2>&1) || {
        printf '%s\n' "$output"
        return 1
    }
    printf '%s\n' "$output"
    if printf '%s\n' "$output" | grep -q 'warning:'; then
        echo 'error: the output above has warnings' >&2
        return 1
    fi
}

swift format lint --strict --recursive --parallel .

# Without the import check, a module can import any other module of the
# package, even one it doesn't declare as a dependency.
cd HelloCodexKit
run swift build --explicit-target-dependency-import-check error -Xswiftc -warnings-as-errors
run swift test --explicit-target-dependency-import-check error -Xswiftc -warnings-as-errors
cd ..

# The app target, without signing: the check only needs it to compile.
run xcodebuild -quiet -project HelloCodex.xcodeproj -scheme HelloCodex -configuration Debug \
    -destination "platform=macOS,arch=$(uname -m)" -derivedDataPath .build/xcode \
    CODE_SIGNING_ALLOWED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES GCC_TREAT_WARNINGS_AS_ERRORS=YES \
    build
