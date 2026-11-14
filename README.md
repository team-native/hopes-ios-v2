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

The app opens through a splash screen into the UIKit welcome screen. The welcome screen links to the existing sign-up and login flows. Authentication, account creation, and password reset are currently local UI prototypes; production server integration is not present in this repository.
