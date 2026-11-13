# Hopes iOS v2

UIKit iOS app managed with Tuist.

## Project layout

- `Project.swift` — app target and build settings
- `App/Sources/App` — app lifecycle and composition
- `App/Sources/Features` — feature screens and presentation logic
- `App/Sources/Core` — shared networking and design system
- `App/Resources` — images, colors, and other app resources

## Open in Xcode

From this directory:

```sh
tuist generate
open Hopes.xcodeproj
```

The app currently opens a UIKit home screen stub. Add feature modules as boundaries become clear.
