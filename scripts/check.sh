#!/bin/sh
# Runs every check CI runs: formatting, a build with warnings as errors, and
# the tests.
set -eu

cd "$(dirname "$0")/.."

swift format lint --strict --recursive --parallel .

cd HelloCodexKit
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
