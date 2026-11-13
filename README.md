# Espresso ☕

A tiny menu-bar app for macOS that keeps your Mac awake — a personal
[Amphetamine](https://apps.apple.com/app/amphetamine/id937984704) clone.

Click the coffee cup in the menu bar to run `caffeinate -imdsu` (no idle
sleep, no disk sleep, no display sleep, no system sleep + simulated user
activity). Click it again to stop and let your Mac sleep normally.

## Usage

- **Left-click** the cup — toggle keep-awake on/off
- **Right-click** the cup — status + Quit
- Bright filled cup = ON, dimmed outline cup = OFF

## Build

```sh
swift build -c release
```

## Run (without installing)

```sh
swift run
# or
.build/release/Espresso
```

## Install as a login item

```sh
./scripts/install.sh
```

Builds the binary, copies it to `~/Library/Application Support/Espresso/`,
and installs a LaunchAgent so Espresso starts automatically when you log in.

## Uninstall

```sh
./scripts/uninstall.sh
```

## How it works

The app lives as an `NSStatusItem` (menu bar icon, no Dock icon). Toggling it
spawns `/usr/bin/caffeinate -imdsu` as a child process; toggling again sends
SIGTERM to that process. If Espresso itself is quit or killed, it stops the
child too, so your Mac is never left stuck awake.

## Requirements

- macOS 11 or later
- Xcode Command Line Tools (`xcode-select --install`)
