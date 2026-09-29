# Hello Codex

Hello Codex is a native macOS companion app for Codex: a dashboard that helps
you understand how you use Codex, and enriches it with what Codex itself
doesn't show. Its first feature tracks the weekly usage limit: how much is
left, how the week is going, and whether it will last until the reset.

It's written in Swift with SwiftUI, and has no third-party dependencies.

## Requirements

- macOS 14 or later to run the app
- Xcode 26 or later (Swift 6.2) to build it

## Checks

```sh
scripts/check.sh
```

This checks formatting with `swift format lint --strict`, builds and tests the
package, and builds the app, failing on any warning. Pull request CI runs the
same script from a clean build. Run `swift format --in-place --recursive .` to
fix formatting.

## Install

```sh
scripts/install.sh
```

This builds a release signed with Developer ID, quits the installed app, moves
it to the Trash, installs the new build in `/Applications`, and opens it. It
needs the Developer ID Application certificate for Hanlogy AB in the keychain.
