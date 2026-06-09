# DeskTank

DeskTank is a macOS desktop tank-battle prototype. It launches a transparent
SpriteKit battlefield over the desktop, turns Desktop files and folders into
obstacles, and updates the map while the game is running.

## Current Gameplay

- `W`, `A`, `S`, `D`: move up, left, down, right
- `J`: fire
- `Space`: pause or resume
- `R`: restart after victory or defeat
- `Command` + `Option` + `T`: show or hide the game overlay

The app starts the overlay immediately when launched. Desktop files and folders
are scanned as obstacles. DeskTank first tries to read real Finder desktop icon
positions with AppleScript; if macOS denies automation access or Finder does not
return positions, it falls back to a stable right-to-left grid layout.

## Run

```bash
swift run DeskTank
```

macOS may ask for Finder automation permission so DeskTank can read desktop icon
positions. If permission is denied, the game still runs with the fallback map.

## Test

```bash
swift test
```

## Build

```bash
swift build
```

## Project Layout

- `Sources/DeskTankCore`: testable game rules, map geometry, collision, movement
- `Sources/DeskTank`: AppKit window, global hotkey, desktop scanning, SpriteKit scene
- `Tests/DeskTankCoreTests`: unit tests for map and rules behavior
