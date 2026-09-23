#!/bin/bash
# Installs (or updates) the Rdio themes and the day/night switcher for Roon (macOS).
# Run it again any time: after changing settings.txt, after a Roon update, or after editing a theme.
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETTINGS_SRC="$REPO/settings.txt"
BASE="$HOME/Library/Application Support/RdioThemeSwitch"
AGENT="$HOME/Library/LaunchAgents/local.rdio-theme-switch.plist"
echo "== Rdio themes + day/night switcher for Roon =="
echo

# ---- 1. Check settings.txt --------------------------------------------------
setting() { tr -d '\r' < "$SETTINGS_SRC" | sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" | tail -1 | sed 's/[[:space:]]*$//'; }
is_num() { [[ "$1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; }
[ -f "$SETTINGS_SRC" ] || { echo "Can't find settings.txt at $SETTINGS_SRC. Nothing changed."; exit 1; }
LAT=$(setting LATITUDE); LON=$(setting LONGITUDE)
if ! is_num "$LAT" || ! is_num "$LON" \
   || ! awk -v a="$LAT" -v o="$LON" 'BEGIN { exit !(a >= -90 && a <= 90 && o >= -180 && o <= 180) }'; then
  echo "Your location isn't set yet (or isn't a valid number)."
  echo "Open settings.txt, replace PUT_YOUR_LATITUDE_HERE and PUT_YOUR_LONGITUDE_HERE"
  echo "with your numbers (for example LATITUDE=51.51 and LONGITUDE=-0.13), save it, and run this again."
  echo "Nothing changed."
  exit 1
fi
echo "Location: latitude $LAT, longitude $LON"

# ---- 2. Find Roon's Themes folder --------------------------------------------
THEMES=$(setting ROON_THEMES_FOLDER)
if [ -z "$THEMES" ]; then
  for app in "/Applications/Roon.app" "$HOME/Applications/Roon.app"; do
    [ -d "$app/Contents/Resources/Themes" ] && THEMES="$app/Contents/Resources/Themes" && break
  done
fi
if [ -z "$THEMES" ] || [ ! -d "$THEMES" ]; then
  echo "Can't find Roon's Themes folder. Is Roon installed in Applications?"
  echo "If Roon is somewhere else, set ROON_THEMES_FOLDER in settings.txt. Nothing changed."
  exit 1
fi
echo "Roon themes folder: $THEMES"

# Stop any earlier version first
launchctl bootout "gui/$(id -u)" "$AGENT" 2>/dev/null

# ---- 3. Put the themes into Roon ---------------------------------------------
# Prefer your saved copies (they include any edits you made); otherwise use the ones in this download.
install_theme() {  # $1 = theme name, $2 = saved copy
  [ -f "$THEMES/$1/colors" ] && return 0
  mkdir -p "$THEMES/$1" || return 1
  if [ -f "$2" ]; then cp "$2" "$THEMES/$1/colors" && echo "Restored your saved '$1' theme."
  else cp "$REPO/themes/$1/colors" "$THEMES/$1/colors" && echo "Added '$1' theme to Roon."; fi
  cp "$REPO/themes/$1/name" "$THEMES/$1/name"
}
if ! install_theme "Rdio" "$BASE/day/colors" || ! install_theme "Rdio Night" "$BASE/night/colors"; then
  echo
  echo "Couldn't copy the themes into Roon. Allow Terminal under"
  echo "System Settings > Privacy & Security > App Management, then run this again."
  exit 1
fi
[ -f "$THEMES/Rdio/colors" ] && [ -f "$THEMES/Rdio Night/colors" ] || { echo "Can't find the Rdio and Rdio Night themes in $THEMES. Nothing changed."; exit 1; }

# Switcher currently showing night? Put the saved day colours back first.
if [ -f "$BASE/day/colors" ] && [ -f "$BASE/night/colors" ] && cmp -s "$THEMES/Rdio/colors" "$BASE/night/colors"; then
  if [ -L "$THEMES/Rdio/colors" ] && [ "$(readlink "$THEMES/Rdio/colors")" = "$BASE/active/colors" ]; then
    DEST="$BASE/active/colors"   # linked: change the file in your Library, not inside Roon
  else
    DEST="$THEMES/Rdio/colors"
  fi
  cp "$BASE/day/colors" "$DEST.tmp" && mv "$DEST.tmp" "$DEST" && echo "Put saved day colours back into Rdio before updating."
fi

# Refuse to start if Rdio currently holds the night colours (we'd save the wrong 'day')
if cmp -s "$THEMES/Rdio/colors" "$THEMES/Rdio Night/colors"; then
  echo "Your Rdio theme currently contains the NIGHT colours. Restore your day Rdio colours first, then run this again. Nothing changed."
  exit 1
fi

# ---- 4. Back up both themes, then save them as the day/night sources --------
STAMP=$(date +%Y-%m-%d_%H%M%S)
mkdir -p "$BASE/backups/$STAMP" "$BASE/day" "$BASE/night"
cp -RL "$THEMES/Rdio" "$THEMES/Rdio Night" "$BASE/backups/$STAMP/"
cp "$THEMES/Rdio/colors"       "$BASE/day/colors.new" && mv "$BASE/day/colors.new" "$BASE/day/colors"
cp "$THEMES/Rdio Night/colors" "$BASE/night/colors"
echo "Backed up both themes to: $BASE/backups/$STAMP"

# ---- 5. Link Rdio's colors file to a file in your Library (the only file the schedule changes)
mkdir -p "$BASE/active"
cp "$BASE/day/colors" "$BASE/active/colors"
# (Already linked from an earlier install? Leave it, so re-running needs no extra macOS permission.)
if [ -L "$THEMES/Rdio/colors" ] && [ "$(readlink "$THEMES/Rdio/colors")" = "$BASE/active/colors" ]; then
  echo "Rdio theme already linked to $BASE/active/colors"
# Make the link under a temporary name first, so a refused write never removes the existing file.
elif ln -sf "$BASE/active/colors" "$THEMES/Rdio/colors.link" && mv -f "$THEMES/Rdio/colors.link" "$THEMES/Rdio/colors"; then
  echo "Linked Rdio theme to $BASE/active/colors"
else
  echo "Couldn't create the link inside Roon. Allow Terminal under"
  echo "System Settings > Privacy & Security > App Management, then run this again."
  exit 1
fi

# Clean up earlier versions
rm -rf "$THEMES/Rdio Auto" "$BASE/current" "$BASE/mode"

# ---- 6. Copy the switcher + settings and schedule it -------------------------
cp "$HERE/rdio-theme-switch.sh" "$BASE/rdio-theme-switch.sh" && chmod +x "$BASE/rdio-theme-switch.sh"
cp "$SETTINGS_SRC" "$BASE/settings.txt"
printf '%s\n' "$THEMES" > "$BASE/themes-folder"
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
launchctl bootstrap "gui/$(id -u)" "$AGENT" && echo "Scheduled: switches at your local sunrise and sunset."
echo
echo "Done! Next:"
echo "  1. Quit and reopen Roon."
echo "  2. In Roon, go to Settings > General > Theme and choose 'Rdio'. Leave it on Rdio."
echo "Log: ~/Library/Logs/rdio-theme-switch.log"
