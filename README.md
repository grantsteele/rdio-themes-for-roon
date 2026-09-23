# Rdio themes for Roon

Two Roon themes inspired by the old Rdio app, plus an optional macOS script that switches between them at sunrise and sunset.

| Theme | Look |
|---|---|
| **Rdio** | Light: white background, charcoal text, Rdio blue accent (`#0990D5`), red hearts |
| **Rdio Night** | Dark: deep slate blue background and Rdio's slate player bar, off-white text |

## Installing the themes

1. In Finder, go to **Applications**, right-click **Roon** > **Show Package Contents** > `Contents/Resources/Themes`.
2. Copy the `Rdio` and `Rdio Night` folders from `themes/` into that folder.
3. Restart Roon and choose a theme under **Settings > General > Theme**.

A Roon update may remove the themes. If it does, copy them in again.

## Automatic day/night switching (macOS, optional)

`switcher/` contains a script that keeps Roon on the **Rdio** theme and swaps in the night colours at sunset and the day colours at sunrise. The times are calculated each day from your latitude and longitude, so they follow the seasons.

**Don't put the `switcher` folder in Roon's Themes folder.** Roon won't start with it there.

### Install

1. Install both themes as above, and select **Rdio** in Roon.
2. Open Terminal, type `bash ` (with a space), drag in `switcher/Install.command`, and press Return.

The installer:
- backs up both themes to `~/Library/Application Support/RdioThemeSwitch/backups/`
- replaces Rdio's `colors` file with a link to `~/Library/Application Support/RdioThemeSwitch/active/colors`, so the scheduled job never writes inside the Roon app and needs no special macOS permissions
- adds a LaunchAgent (`~/Library/LaunchAgents/local.rdio-theme-switch.plist`) that runs every 10 minutes and after the Mac wakes

If the installer reports "Operation not permitted", allow Terminal under **System Settings > Privacy & Security > App Management**, then run it again. It only needs this once.

### Settings

Edit the top of `~/Library/Application Support/RdioThemeSwitch/rdio-theme-switch.sh`:

| Setting | Default | Meaning |
|---|---|---|
| `LAT`, `LON` | Brisbane (`-27.47`, `153.03`) | Your location |
| `SUNRISE_OFFSET_MIN` | `0` | Minutes after (+) or before (-) sunrise to go light |
| `SUNSET_OFFSET_MIN` | `0` | Minutes after (+) or before (-) sunset to go dark |
| `RESTART_ROON` | `1` | Restart Roon when the theme changes (`0` = apply next launch) |

### Testing

```
bash ~/Library/Application\ Support/RdioThemeSwitch/rdio-theme-switch.sh night
bash ~/Library/Application\ Support/RdioThemeSwitch/rdio-theme-switch.sh day
```

The log is at `~/Library/Logs/rdio-theme-switch.log`.

### After a Roon update or editing a theme

Run `Install.command` again. It restores the themes and link if needed and saves your edited versions. Until you do, the script won't overwrite a theme that has been edited.

### Uninstall

```
bash switcher/Uninstall.command
```

This makes Rdio a normal theme again with the day colours. Backups are kept.

## Notes

- Tested on macOS with Roon installed in `/Applications`, with themes loaded from `Roon.app/Contents/Resources/Themes`.
- Roon quits when asked but reports "User cancelled"; the script handles this and falls back to a normal quit signal.
- Sunrise and sunset use the standard NOAA-style formula (about 1–2 minutes accuracy). Switching happens within 10 minutes of those times.
