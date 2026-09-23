#!/bin/bash
# Rdio day/night switcher for Roon (macOS).
# Keep Roon's theme set to "Rdio". Rdio's colors file is a link to
# ~/Library/Application Support/RdioThemeSwitch/active/colors. At sunset this copies
# your night colours into that file; at sunrise, your day colours. It never writes
# inside the Roon app, so macOS App Management permission is not needed.
#
# Settings live in ~/Library/Application Support/RdioThemeSwitch/settings.txt
# (copied there by Install.command). Edit settings.txt and re-run the installer to change them.

BASE="$HOME/Library/Application Support/RdioThemeSwitch"
SETTINGS="$BASE/settings.txt"
TARGET="$BASE/active/colors"
LOG="$HOME/Library/Logs/rdio-theme-switch.log"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }
FORCE="$1"   # optional: day | night

# Reads KEY=value from settings.txt (ignores comments, spaces and Windows line endings)
setting() { tr -d '\r' < "$SETTINGS" | sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" | tail -1 | sed 's/[[:space:]]*$//'; }
is_num() { [[ "$1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; }
is_int() { [[ "$1" =~ ^-?[0-9]+$ ]]; }

[ -f "$SETTINGS" ] || { log "ERROR: $SETTINGS missing. Re-run Install.command."; exit 1; }
LAT=$(setting LATITUDE); LON=$(setting LONGITUDE)
SUNRISE_OFFSET_MIN=$(setting SUNRISE_OFFSET_MIN); is_int "$SUNRISE_OFFSET_MIN" || SUNRISE_OFFSET_MIN=0
SUNSET_OFFSET_MIN=$(setting SUNSET_OFFSET_MIN);   is_int "$SUNSET_OFFSET_MIN"  || SUNSET_OFFSET_MIN=0
RESTART_ROON=$(setting RESTART_ROON)
if ! is_num "$LAT" || ! is_num "$LON"; then log "ERROR: LATITUDE/LONGITUDE in $SETTINGS aren't numbers. Fix them and re-run Install.command."; exit 1; fi

THEMES=$(cat "$BASE/themes-folder" 2>/dev/null)
LINK="$THEMES/Rdio/colors"

# Sunrise/sunset as Unix times. Near the poles: midnight sun = day all day, polar night = night all day.
read RISE SET < <(osascript -l JavaScript -e "
function sunTimes(lat, lon, now) {
  var rad = Math.PI / 180;
  var nowS = Math.round(now.getTime() / 1000);
  var jdNow = now.getTime() / 86400000 + 2440587.5;
  var n = Math.round(jdNow - 2451545.0 + 0.0008 + lon / 360);
  var Js = n - lon / 360;
  var M = (357.5291 + 0.98560028 * Js) % 360;
  var C = 1.9148 * Math.sin(M * rad) + 0.02 * Math.sin(2 * M * rad) + 0.0003 * Math.sin(3 * M * rad);
  var L = (M + C + 180 + 102.9372) % 360;
  var Jt = 2451545.0 + Js + 0.0053 * Math.sin(M * rad) - 0.0069 * Math.sin(2 * L * rad);
  var sd = Math.sin(L * rad) * Math.sin(23.4397 * rad), cd = Math.cos(Math.asin(sd));
  var cosw = (Math.sin(-0.833 * rad) - Math.sin(lat * rad) * sd) / (Math.cos(lat * rad) * cd);
  if (cosw >= 1) return '0 0';
  if (cosw <= -1) return (nowS - 86400) + ' ' + (nowS + 86400);
  var w = Math.acos(cosw) / rad;
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

if [ "$RESTART_ROON" != "0" ] && pgrep -xq Roon; then
  # Roon reports "User cancelled" to this request but does quit, so errors are ignored.
  osascript -e 'tell application "Roon" to quit' >/dev/null 2>&1
  for i in $(seq 1 20); do pgrep -xq Roon || break; sleep 1; done
  if pgrep -xq Roon; then killall -TERM Roon 2>/dev/null; sleep 3; fi
  sleep 2
  open -a Roon
  log "Restarted Roon"
fi
