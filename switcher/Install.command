#!/bin/bash
# Installs (or updates) the Rdio day/night switcher for Roon.
HERE="$(cd "$(dirname "$0")" && pwd)"
BASE="$HOME/Library/Application Support/RdioThemeSwitch"
THEMES="/Applications/Roon.app/Contents/Resources/Themes"
AGENT="$HOME/Library/LaunchAgents/local.rdio-theme-switch.plist"
echo "== Rdio day/night switcher =="

# Stop any earlier version first
launchctl bootout "gui/$(id -u)" "$AGENT" 2>/dev/null

# Roon update removed the themes? Put them back from the saved copies.
if [ ! -f "$THEMES/Rdio/colors" ] && [ -f "$BASE/day/colors" ]; then
  mkdir -p "$THEMES/Rdio" && echo "Rdio" > "$THEMES/Rdio/name" && cp "$BASE/day/colors" "$THEMES/Rdio/colors" && echo "Restored Rdio theme."
fi
if [ ! -f "$THEMES/Rdio Night/colors" ] && [ -f "$BASE/night/colors" ]; then
  mkdir -p "$THEMES/Rdio Night" && echo "Rdio Night" > "$THEMES/Rdio Night/name" && cp "$BASE/night/colors" "$THEMES/Rdio Night/colors" && echo "Restored Rdio Night theme."
fi
[ -f "$THEMES/Rdio/colors" ] && [ -f "$THEMES/Rdio Night/colors" ] || { echo "Can't find the Rdio and Rdio Night themes in $THEMES. Nothing changed."; exit 1; }

# Switcher currently showing night? Put the saved day colours back first.
if [ -f "$BASE/day/colors" ] && [ -f "$BASE/night/colors" ] && cmp -s "$THEMES/Rdio/colors" "$BASE/night/colors"; then
  cp "$BASE/day/colors" "$THEMES/Rdio/colors.tmp" && mv "$THEMES/Rdio/colors.tmp" "$THEMES/Rdio/colors" && echo "Put saved day colours back into Rdio before updating."
fi

# Refuse to start if Rdio currently holds the night colours (we'd save the wrong 'day')
if cmp -s "$THEMES/Rdio/colors" "$THEMES/Rdio Night/colors"; then
  echo "Your Rdio theme currently contains the NIGHT colours. Restore your day Rdio colours first, then run this again. Nothing changed."
  exit 1
fi

# Back up both themes, then save them as the day/night sources
STAMP=$(date +%Y-%m-%d_%H%M%S)
mkdir -p "$BASE/backups/$STAMP" "$BASE/day" "$BASE/night"
cp -RL "$THEMES/Rdio" "$THEMES/Rdio Night" "$BASE/backups/$STAMP/"
cp "$THEMES/Rdio/colors"       "$BASE/day/colors.new" && mv "$BASE/day/colors.new" "$BASE/day/colors"
cp "$THEMES/Rdio Night/colors" "$BASE/night/colors"
echo "Backed up both themes to: $BASE/backups/$STAMP"

# Link Rdio's colors file to a file in your Library (the only file the schedule changes)
mkdir -p "$BASE/active"
cp "$BASE/day/colors" "$BASE/active/colors"
if ln -sf "$BASE/active/colors" "$THEMES/Rdio/colors"; then
  echo "Linked Rdio theme to $BASE/active/colors"
else
  echo "Couldn't create the link inside Roon. Nothing scheduled."; exit 1
fi

# Clean up earlier versions
rm -rf "$THEMES/Rdio Auto" "$BASE/current" "$BASE/mode"

cp "$HERE/rdio-theme-switch.sh" "$BASE/rdio-theme-switch.sh" && chmod +x "$BASE/rdio-theme-switch.sh"
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>local.rdio-theme-switch</string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string><string>$BASE/rdio-theme-switch.sh</string>
  </array>
  <key>StartInterval</key><integer>600</integer>
  <key>RunAtLoad</key><true/>
</dict></plist>
PLIST
launchctl bootstrap "gui/$(id -u)" "$AGENT" && echo "Scheduled: switches at sunrise and sunset (Brisbane)."
echo
echo "In Roon, keep Settings > General > Theme set to 'Rdio'."
echo "Log: ~/Library/Logs/rdio-theme-switch.log"
