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

This checks formatting with `swift format lint --strict`, builds with warnings
as errors, and runs the tests. Pull request CI runs the same script. Run
`swift format --in-place --recursive .` to fix formatting.
