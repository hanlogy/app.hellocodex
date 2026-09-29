#!/bin/sh
# Runs every check CI runs: formatting, a build with warnings as errors, and
# the tests.
set -eu

cd "$(dirname "$0")/.."

swift format lint --strict --recursive --parallel .

# Without the import check, a module can import any other module of the
# package, even one it doesn't declare as a dependency.
cd HelloCodexKit
swift build --explicit-target-dependency-import-check error -Xswiftc -warnings-as-errors
swift test --explicit-target-dependency-import-check error -Xswiftc -warnings-as-errors
