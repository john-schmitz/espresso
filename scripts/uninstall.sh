#!/bin/bash
# Remove Espresso and its login item.
set -euo pipefail

LABEL="local.espresso"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
INSTALL_DIR="$HOME/Library/Application Support/Espresso"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl unload "$PLIST_PATH" 2>/dev/null || true
rm -f "$PLIST_PATH"
rm -rf "$INSTALL_DIR"

# NOTE: this kills every caffeinate process, including any you started yourself
# or other apps use. Normally Espresso already stops its own caffeinate on quit.
pkill -x caffeinate 2>/dev/null || true

echo "Espresso uninstalled."
