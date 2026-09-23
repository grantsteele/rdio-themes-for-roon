#!/bin/bash
# Rdio day/night switcher for Roon.
# Keep Roon's theme set to "Rdio". Rdio's colors file is a link to
# ~/Library/Application Support/RdioThemeSwitch/active/colors. At sunset this copies
# your night colours into that file; at sunrise, your day colours. It never writes
# inside the Roon app, so macOS App Management permission is not needed.

# ---- Settings you can change ------------------------------------------------
LAT=-27.47            # Brisbane
LON=153.03
SUNRISE_OFFSET_MIN=0  # e.g. 30 = switch to day 30 min AFTER sunrise
SUNSET_OFFSET_MIN=0   # e.g. -30 = switch to night 30 min BEFORE sunset
RESTART_ROON=1        # 0 = never restart; the change applies next time Roon opens
# -----------------------------------------------------------------------------

BASE="$HOME/Library/Application Support/RdioThemeSwitch"
LINK="/Applications/Roon.app/Contents/Resources/Themes/Rdio/colors"
TARGET="$BASE/active/colors"
LOG="$HOME/Library/Logs/rdio-theme-switch.log"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }
FORCE="$1"   # optional: day | night

read RISE SET < <(osascript -l JavaScript -e "
function sunTimes(lat, lon, now) {
  var rad = Math.PI / 180;
  var jdNow = now.getTime() / 86400000 + 2440587.5;
  var n = Math.round(jdNow - 2451545.0 + 0.0008 + lon / 360);
  var Js = n - lon / 360;
  var M = (357.5291 + 0.98560028 * Js) % 360;
  var C = 1.9148 * Math.sin(M * rad) + 0.02 * Math.sin(2 * M * rad) + 0.0003 * Math.sin(3 * M * rad);
  var L = (M + C + 180 + 102.9372) % 360;
  var Jt = 2451545.0 + Js + 0.0053 * Math.sin(M * rad) - 0.0069 * Math.sin(2 * L * rad);
  var sd = Math.sin(L * rad) * Math.sin(23.4397 * rad), cd = Math.cos(Math.asin(sd));
  var w = Math.acos((Math.sin(-0.833 * rad) - Math.sin(lat * rad) * sd) / (Math.cos(lat * rad) * cd)) / rad;
  var toS = function (j) { return Math.round((j - 2440587.5) * 86400); };
  return toS(Jt - w / 360) + ' ' + toS(Jt + w / 360);
}
sunTimes($LAT, $LON, new Date());")
if [ -z "$RISE" ] || [ -z "$SET" ]; then log "ERROR: could not calculate sun times"; exit 1; fi

NOW=$(date +%s); RISE=$((RISE + SUNRISE_OFFSET_MIN * 60)); SET=$((SET + SUNSET_OFFSET_MIN * 60))
if [ -n "$FORCE" ]; then MODE="$FORCE"
elif [ "$NOW" -ge "$RISE" ] && [ "$NOW" -lt "$SET" ]; then MODE=day
else MODE=night; fi

if [ ! -L "$LINK" ] || [ "$(readlink "$LINK")" != "$TARGET" ]; then
  log "ERROR: Roon's Rdio theme is no longer linked (Roon update?). Re-run Install.command."; exit 1
fi
[ -f "$TARGET" ] || { log "ERROR: $TARGET missing. Re-run Install.command."; exit 1; }
[ -f "$BASE/$MODE/colors" ] || { log "ERROR: saved $MODE colours missing. Re-run Install.command."; exit 1; }

# Already correct? Nothing to do.
cmp -s "$TARGET" "$BASE/$MODE/colors" && exit 0

# Safety: only overwrite if Rdio currently holds one of the two saved versions.
if ! cmp -s "$TARGET" "$BASE/day/colors" && ! cmp -s "$TARGET" "$BASE/night/colors"; then
  log "SKIPPED: Rdio/colors has been edited (matches neither saved day nor night). Not touching it. Re-run Install.command to save your edits."
  exit 0
fi

cp "$BASE/$MODE/colors" "$TARGET.tmp" 2>>"$LOG" && mv "$TARGET.tmp" "$TARGET" || { log "ERROR: could not write $TARGET"; exit 1; }
log "Switched to $MODE (sunrise $(date -r $RISE '+%H:%M'), sunset $(date -r $SET '+%H:%M'))"

if [ "$RESTART_ROON" = "1" ] && pgrep -xq Roon; then
  # Roon reports "User cancelled" to this request but does quit, so errors are ignored.
  osascript -e 'tell application "Roon" to quit' >/dev/null 2>&1
  for i in $(seq 1 20); do pgrep -xq Roon || break; sleep 1; done
  if pgrep -xq Roon; then killall -TERM Roon 2>/dev/null; sleep 3; fi
  sleep 2
  open -a Roon
  log "Restarted Roon"
fi
