#!/bin/bash
# Removes the day/night switcher. The Rdio and Rdio Night themes stay in Roon.
BASE="$HOME/Library/Application Support/RdioThemeSwitch"
THEMES=$(cat "$BASE/themes-folder" 2>/dev/null)
[ -n "$THEMES" ] || THEMES="/Applications/Roon.app/Contents/Resources/Themes"
LINK="$THEMES/Rdio/colors"
AGENT="$HOME/Library/LaunchAgents/local.rdio-theme-switch.plist"
launchctl bootout "gui/$(id -u)" "$AGENT" 2>/dev/null; rm -f "$AGENT"
if [ -L "$LINK" ] && [ -f "$BASE/day/colors" ]; then
  cp "$BASE/day/colors" "$LINK.tmp" && mv "$LINK.tmp" "$LINK" && echo "Rdio theme is a normal file again, with your day colours."
fi
echo "Switcher removed. Your backups are kept in: $BASE/backups"
