# Toddler Game Center

A tiny hub of learning games for toddlers. Native SwiftUI app for **macOS**, **iPadOS**, and **iOS** (iPhone), from a single app target.

Included games:
- 🐻 **Matching**: flip cards and find pairs.
- 🚦 **Red Light, Green Light**: tap to move on green, freeze on red.

## Requirements

- Xcode 16 or later (Swift 6)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- Deployment targets: macOS 14, iOS/iPadOS 17

## Run it

The Xcode project is generated from `project.yml` and isn't checked in:

```bash
xcodegen generate
open ToddlerGameCenter.xcodeproj
```

Pick the **ToddlerGameCenter** scheme, choose **My Mac**, an iPad, or an iPhone simulator, and run. Rerun `xcodegen generate` after adding or removing files in `App/`. Files in `GameCenterKit/` are picked up automatically.

Run the game-logic tests without Xcode:

```bash
swift test --package-path GameCenterKit
```

From the command line:

```bash
xcodebuild build -project ToddlerGameCenter.xcodeproj -scheme ToddlerGameCenter \
  -destination 'platform=macOS'
xcodebuild build -project ToddlerGameCenter.xcodeproj -scheme ToddlerGameCenter \
  -destination 'generic/platform=iOS Simulator'
```

## Signed macOS build

`scripts/sign-macos.sh` builds a Release app, signs it with a Developer ID (hardened runtime, secure timestamp, App Sandbox), and notarizes and staples it when App Store Connect API credentials are set. It follows the same flow as Ace's desktop releases.

```bash
scripts/sign-macos.sh --open                                      # sign with the keychain's Developer ID and launch
op run --env-file scripts/signing.env -- scripts/sign-macos.sh    # sign + notarize using 1Password
```

`scripts/signing.env` holds only `op://` references to the "Ace desktop releases" item in the Dev vault. The output is `.build/DerivedData/Build/Products/Release/Toddler Game Center.app`.

### Releases

Pushing a tag like `v0.1.0` runs `.github/workflows/release.yml`. It imports the Developer ID certificate into a temporary keychain, runs `scripts/sign-macos.sh`, and publishes the notarized zip as a GitHub release. It reads these repository secrets, all copied from the 1Password item "Ace desktop releases":

| Secret | 1Password field |
| --- | --- |
| `MACOS_CERTIFICATE_P12` | `ACE_CERTIFICATE_P12` (base64 .p12) |
| `MACOS_CERTIFICATE_PASSWORD` | `ACE_CERTIFICATE_PASSWORD` |
| `APPLE_API_KEY_ID` | `ACE_NOTARY_KEY_ID` |
| `APPLE_API_ISSUER` | `ACE_NOTARY_ISSUER` |
| `APPLE_API_PRIVATE_KEY` | `ACE_NOTARY_PRIVATE_KEY` |

## Playing with a keyboard

- **Tab** moves between buttons when Full Keyboard Access is on (System Settings → Keyboard on macOS, Settings → Accessibility → Keyboards on iPad). **Space** presses the focused button.
- **Escape** goes back to the hub from any game.
- In Red Light, Green Light, **Space** taps the big button wherever focus is.

## Adding a new game

Each game is a SwiftUI view, ideally backed by a plain value type that holds the rules, so the rules can be unit tested without UI:

1. Create `GameCenterKit/Sources/GameCenterKit/Games/<YourGame>/` with:
   - `YourGame.swift`: a `struct` with the rules (no timers, no SwiftUI).
   - `YourGameView.swift`: the view. Keep the game in `@State` and do timed work in `.task { }`, so it stops when the player leaves the game.
2. Add an entry to `GameRegistry.games` in `Hub/GameRegistry.swift`:

```swift
GameEntry(id: "your-game", title: "Your Game", emoji: "🎈", color: Color(hex: 0xFFCC66)) {
    YourGameView()
}
```

3. Add tests in `GameCenterKit/Tests/GameCenterKitTests/`.

The hub renders a tile for each entry. Each visit to a game gets a fresh view, so every visit starts a new round.

## Project layout

```
project.yml                      # XcodeGen spec: one app target for macOS, iPadOS, and iOS
App/
  ToddlerGameCenterApp.swift     # @main entry point; hosts GameCenterView
GameCenterKit/                   # Swift package with the games, hub, and tests
  Package.swift
  Sources/GameCenterKit/
    Hub/
      GameCenterView.swift       # hub: tile grid, header with Back button
      GameRegistry.swift         # single source of truth for available games
    Shared/
      Theme.swift                # colors, fonts, chunky toddler-friendly button style
    Games/
      Matching/                  # MatchingGame (rules) + MatchingGameView
      RedLightGreenLight/        # RedLightGame (rules) + RedLightGameView
  Tests/GameCenterKitTests/      # Swift Testing tests for the game rules
```
