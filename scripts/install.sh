#!/bin/bash
# Build Espresso and install it as a login item (LaunchAgent).
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Espresso"
LABEL="local.espresso"
INSTALL_DIR="$HOME/Library/Application Support/$APP_NAME"
BIN_PATH="$INSTALL_DIR/$APP_NAME"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "Building release binary..."
mkdir -p .build/release
if ! swift build -c release 2>/dev/null; then
    VFS_TMP="$(mktemp -t espresso-vfs.XXXXXX.yaml)"
    trap 'rm -f "$VFS_TMP"' EXIT
    cat > "$VFS_TMP" <<'VFS'
{
  "version": 0,
  "case-sensitive": "false",
  "roots": [
    {
      "name": "/Library/Developer/CommandLineTools/usr/include/swift",
      "type": "directory",
      "contents": [
        {
          "name": "module.modulemap",
          "type": "file",
          "external-contents": "/dev/null"
        }
      ]
    }
  ]
}
VFS
    swiftc -vfsoverlay "$VFS_TMP" -O Sources/Espresso/main.swift -o ".build/release/$APP_NAME"
fi

echo "Installing to $BIN_PATH"
mkdir -p "$INSTALL_DIR"
cp ".build/release/$APP_NAME" "$BIN_PATH"

echo "Installing LaunchAgent $PLIST_PATH"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
</dict>
</plist>
PLIST

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || launchctl load "$PLIST_PATH"

echo "Done. You should see a coffee cup in your menu bar."
echo "Left-click it to keep your Mac awake (caffeinate -imdsu); click again to stop."
