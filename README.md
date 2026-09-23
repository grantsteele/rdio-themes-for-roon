# Rdio themes for Roon

Two themes for the [Roon](https://roon.app) music player, inspired by the much-missed Rdio app. There's also an optional switcher that changes Roon to the light theme at sunrise and the dark theme at sunset, wherever you are in the world.

| Theme | Look |
|---|---|
| **Rdio** | Light: white background, charcoal text, Rdio blue accents (`#0990D5`), red hearts |
| **Rdio Night** | Dark: deep slate-blue background, Rdio's slate player bar, off-white text |

Works on **Mac** and **Windows**.

> **Windows is untested.** I've only tested this on a Mac. The Windows version was written to do the same thing, but it hasn't been run on a Windows PC yet. If you try it, please [open an issue](../../issues) to say whether it worked, and include the log file if it didn't (see [Troubleshooting](#troubleshooting)).

---

## Contents

1. [Download](#1-download)
2. [Set your location](#2-set-your-location)
3. [Install on a Mac](#3a-install-on-a-mac)
4. [Install on Windows](#3b-install-on-windows)
5. [Changing settings later](#changing-settings-later)
6. [Just want the themes, without the switcher?](#just-want-the-themes-without-the-switcher)
7. [Troubleshooting](#troubleshooting)
8. [Uninstalling](#uninstalling)
9. [Questions](#questions)

---

## 1. Download

1. At the top of this page, click the green **Code** button, then **Download ZIP**.
2. Find the ZIP in your Downloads folder and unzip it:
   - **Mac:** double-click it.
   - **Windows:** right-click it, choose **Extract All...**, then **Extract**. Don't run anything from inside the ZIP without extracting it first.

You now have a folder called `rdio-themes-for-roon-main`. Everything below happens inside that folder.

## 2. Set your location

The switcher works out your sunrise and sunset times from your location, so you only need to set this once.

> **Do I need to enter my time zone?** No. The switcher uses your computer's clock, which already knows your time zone and daylight saving. It only needs to know where on Earth you are.

1. **Find your latitude and longitude:**
   - Open [Google Maps](https://maps.google.com) and find your town.
   - **Right-click** on it. Two numbers appear at the top of the menu, for example `51.5072, -0.1276`.
   - Click them to copy them. The **first** number is your **latitude** and the **second** is your **longitude**.
2. **Open `settings.txt`** (in the main folder):
   - **Mac:** right-click it > **Open With** > **TextEdit**.
   - **Windows:** double-click it. It opens in Notepad.
3. **Find these two lines:**
   ```
   LATITUDE=PUT_YOUR_LATITUDE_HERE
   LONGITUDE=PUT_YOUR_LONGITUDE_HERE
   ```
4. **Replace the placeholder text with your numbers.** For London:
   ```
   LATITUDE=51.51
   LONGITUDE=-0.13
   ```
   - Keep the minus sign if there is one. South of the equator and west of London are negative.
   - Use a **dot** for decimals (`51.51`), not a comma (`51,51`).
   - Two decimal places are plenty.
5. **Save** and close the file.

`settings.txt` also has a few optional settings, such as switching 30 minutes before sunset. The notes inside the file explain them. The defaults are fine for most people.

<details>
<summary>Example locations</summary>

| City | LATITUDE | LONGITUDE |
|---|---|---|
| Brisbane | -27.47 | 153.03 |
| Sydney | -33.87 | 151.21 |
| Auckland | -36.85 | 174.76 |
| Tokyo | 35.68 | 139.69 |
| Singapore | 1.35 | 103.82 |
| Berlin | 52.52 | 13.40 |
| London | 51.51 | -0.13 |
| New York | 40.71 | -74.01 |
| Los Angeles | 34.05 | -118.24 |
| Sao Paulo | -23.55 | -46.63 |

</details>

## 3a. Install on a Mac

1. **Quit Roon** if it's open.
2. **Open Terminal:** press `Cmd + Space`, type `Terminal`, and press Return.
3. In Terminal, type `bash` followed by a **space**. Don't press Return yet.
4. In Finder, open `rdio-themes-for-roon-main` > `switcher` > `mac`, and **drag `Install.command` into the Terminal window**. Its location appears after `bash `.
5. **Press Return.**
6. When you see **Done!**, open Roon and go to **Settings > General > Theme**. Choose **Rdio** and leave it on Rdio. The switcher changes Rdio's colours between day and night automatically.

That's it. Roon restarts itself at sunrise and sunset to change the theme. It only takes a few seconds.

**If you see "Operation not permitted" or "Couldn't copy the themes into Roon":** open **System Settings > Privacy & Security > App Management**, turn on **Terminal**, then repeat steps 3–5. You only need to do this once.

## 3b. Install on Windows

1. **Quit Roon** if it's open. Roon needs to have been opened at least once on this PC.
2. Open the `rdio-themes-for-roon-main` folder, then `switcher` > `windows`.
3. **Double-click `Install.cmd`.**
   - If Windows shows **"Windows protected your PC"**, click **More info**, then **Run anyway**. Windows shows this for any script downloaded from the internet.
4. A black window shows the progress. When you see **Done!**, press any key to close it.
5. Open Roon and go to **Settings > General > Theme**. Choose **Rdio** and leave it on Rdio. The switcher changes Rdio's colours between day and night automatically.

That's it. Roon restarts itself at sunrise and sunset to change the theme. It only takes a few seconds.

> **Reminder: the Windows version hasn't been tested yet.** If something doesn't work, please [open an issue](../../issues) and include the log file (see [Troubleshooting](#troubleshooting)). Nothing is lost if it fails: the installer backs up both themes first, and `Uninstall.cmd` removes the switcher.

---

## Changing settings later

1. Edit `settings.txt` in the downloaded folder, for example if you move house or want different offsets.
2. Run the installer again, as in step 3a or 3b.

Running the installer again is always safe. It keeps your themes and saves a backup each time.

## Just want the themes, without the switcher?

Copy the two folders inside `themes` (`Rdio` and `Rdio Night`) into Roon's **Themes** folder, restart Roon, and choose a theme under **Settings > General > Theme**. You don't need `settings.txt` for this.

- **Mac:** in Finder, go to **Applications**, right-click **Roon** > **Show Package Contents**, then open `Contents` > `Resources` > `Themes`.
- **Windows:** press `Windows + R`, paste `%LOCALAPPDATA%\Roon\Application`, and press Return. Search that folder for a folder named **Themes**. It already contains Roon's built-in themes, such as `Dark`.

**Don't copy the `switcher` folder into Roon's Themes folder.** Roon won't start with it there.

## Troubleshooting

**The theme doesn't change at sunset or sunrise.**
Check the log. Each switch writes a line such as `Switched to night (sunrise 06:12, sunset 18:04)`, and problems are written there too.

| | Log file |
|---|---|
| Mac | `~/Library/Logs/rdio-theme-switch.log`. In Finder, press `Cmd + Shift + G` and paste the path. |
| Windows | `%LOCALAPPDATA%\RdioThemeSwitch\switch.log`. Press `Windows + R` and paste the path. |

If the sunrise and sunset times in the log look wrong, check the minus signs on `LATITUDE` and `LONGITUDE` in `settings.txt`, then run the installer again.

**Test it without waiting for sunset.** This forces night or day straight away. The next scheduled check, up to 10 minutes later, puts it back to the correct setting.

- Mac (Terminal):
  ```
  bash ~/Library/Application\ Support/RdioThemeSwitch/rdio-theme-switch.sh night
  bash ~/Library/Application\ Support/RdioThemeSwitch/rdio-theme-switch.sh day
  ```
- Windows (Command Prompt):
  ```
  powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\RdioThemeSwitch\rdio-theme-switch.ps1" night
  powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\RdioThemeSwitch\rdio-theme-switch.ps1" day
  ```

**The Rdio themes disappeared after a Roon update.**
- **Mac:** run the installer again. It puts your themes back.
- **Windows:** the switcher usually puts them back by itself within 10 minutes. If it doesn't, run the installer again. You may need to choose **Rdio** again in Roon's settings.

**The log says "SKIPPED: Rdio/colors has been edited".**
You edited the Rdio theme file directly. The switcher won't overwrite your edits. Run the installer again to save your edited version as the new day theme. It picks up edits to **Rdio Night** the same way.

**I don't want Roon to restart by itself.**
Set `RESTART_ROON=0` in `settings.txt` and run the installer again. The theme then changes the next time you open Roon.

## Uninstalling

This removes the automatic switching and leaves Rdio on its day colours. Both themes stay in Roon, and your backups are kept.

- **Mac:** in Terminal, type `bash ` (with a space), drag in `switcher/mac/Uninstall.command`, and press Return.
- **Windows:** double-click `switcher\windows\Uninstall.cmd`.

To remove the themes as well, delete the `Rdio` and `Rdio Night` folders from Roon's Themes folder (see [Just want the themes](#just-want-the-themes-without-the-switcher)).

## Questions

**Why does it restart Roon?** Roon only reads theme colours when it starts. The restart takes a few seconds, happens twice a day, and only when Roon is open.

**How accurate are the times?** Within a minute or two of the real sunrise and sunset. The switcher checks every 10 minutes, so the change happens within 10 minutes of that time, and within 10 minutes of your computer waking from sleep.

**What about the Arctic or Antarctic?** During midnight sun the theme stays light all day. During polar night it stays dark.

**What does the installer change on my computer?**

| | Mac | Windows |
|---|---|---|
| Themes | Adds `Rdio` and `Rdio Night` to Roon's Themes folder | Same |
| Switcher files, saved themes, backups | `~/Library/Application Support/RdioThemeSwitch/` | `%LOCALAPPDATA%\RdioThemeSwitch\` |
| Schedule | A LaunchAgent: `~/Library/LaunchAgents/local.rdio-theme-switch.plist` | A Task Scheduler task: "Rdio theme switch for Roon" |

On a Mac, Rdio's `colors` file becomes a link to a file in your Library. This means the scheduled job never writes inside the Roon app and needs no extra macOS permissions.
