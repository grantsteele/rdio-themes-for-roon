# Installs (or updates) the Rdio themes and the day/night switcher for Roon (Windows).
# Start it by double-clicking Install.cmd. Run it again any time: after changing
# settings.txt, or after editing a theme.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$SettingsSrc = Join-Path $Repo 'settings.txt'

function Stop-Install([string]$Message) {
    Write-Host ''
    Write-Host $Message -ForegroundColor Yellow
    Write-Host 'Nothing else was changed.'
    exit 1
}

Write-Host '== Rdio themes + day/night switcher for Roon =='
Write-Host ''

# ---- 1. Check settings.txt --------------------------------------------------
if (-not (Test-Path -LiteralPath $SettingsSrc)) { Stop-Install "Can't find settings.txt at $SettingsSrc." }
$settings = Read-RdioSettings $SettingsSrc
$lat = ConvertTo-RdioNumber $settings['LATITUDE']
$lon = ConvertTo-RdioNumber $settings['LONGITUDE']
if ($null -eq $lat -or $null -eq $lon -or $lat -lt -90 -or $lat -gt 90 -or $lon -lt -180 -or $lon -gt 180) {
    Stop-Install ("Your location isn't set yet (or isn't a valid number).`n" +
        "Open settings.txt, replace PUT_YOUR_LATITUDE_HERE and PUT_YOUR_LONGITUDE_HERE`n" +
        "with your numbers (for example LATITUDE=51.51 and LONGITUDE=-0.13), save it, and run this again.`n" +
        "Use a dot for decimals, not a comma.")
}
Write-Host "Location: latitude $($settings['LATITUDE']), longitude $($settings['LONGITUDE'])"

# ---- 2. Find Roon's Themes folder --------------------------------------------
Write-Host 'Looking for Roon...'
$themes = Find-RoonThemesFolder $settings
if (-not $themes) {
    Stop-Install ("Can't find Roon's Themes folder. Is Roon installed, and has it been opened at least once?`n" +
        'If Roon is installed somewhere unusual, set ROON_THEMES_FOLDER in settings.txt.')
}
Write-Host "Roon themes folder: $themes"

# Stop any earlier version first
if (Get-ScheduledTask -TaskName $RdioTaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $RdioTaskName -Confirm:$false
}

# ---- 3. Put the themes into Roon ---------------------------------------------
# Prefer your saved copies (they include any edits you made); otherwise use the ones in this download.
New-Item -ItemType Directory -Path (Join-Path $RdioBase 'day'), (Join-Path $RdioBase 'night') -Force | Out-Null
$savedDay = Join-Path $RdioBase 'day\colors'
$savedNight = Join-Path $RdioBase 'night\colors'
foreach ($t in @(@('Rdio', $savedDay), @('Rdio Night', $savedNight))) {
    $dir = Join-Path $themes $t[0]
    if (Test-Path -LiteralPath (Join-Path $dir 'colors')) { continue }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    if (Test-Path -LiteralPath $t[1]) {
        Copy-Item -LiteralPath $t[1] -Destination (Join-Path $dir 'colors') -Force
        Write-Host "Restored your saved '$($t[0])' theme."
    } else {
        Copy-Item -LiteralPath (Join-Path $Repo "themes\$($t[0])\colors") -Destination (Join-Path $dir 'colors') -Force
        Write-Host "Added '$($t[0])' theme to Roon."
    }
    Copy-Item -LiteralPath (Join-Path $Repo "themes\$($t[0])\name") -Destination (Join-Path $dir 'name') -Force
}
$rdio = Join-Path $themes 'Rdio\colors'
$rdioNight = Join-Path $themes 'Rdio Night\colors'

# Switcher currently showing night? Put the saved day colours back first.
if ((Test-Path -LiteralPath $savedDay) -and (Test-RdioSameFile $rdio $savedNight)) {
    Copy-RdioFile $savedDay $rdio
    Write-Host 'Put saved day colours back into Rdio before updating.'
}

# Refuse to continue if Rdio currently holds the night colours (we'd save the wrong 'day')
if (Test-RdioSameFile $rdio $rdioNight) {
    Stop-Install 'Your Rdio theme currently contains the NIGHT colours. Restore your day Rdio colours first, then run this again.'
}

# ---- 4. Back up both themes, then save them as the day/night sources --------
$backup = Join-Path $RdioBase ('backups\' + (Get-Date -Format 'yyyy-MM-dd_HHmmss'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $themes 'Rdio'), (Join-Path $themes 'Rdio Night') -Destination $backup -Recurse -Force
Copy-Item -LiteralPath $rdio -Destination $savedDay -Force
Copy-Item -LiteralPath $rdioNight -Destination $savedNight -Force
Write-Host "Backed up both themes to: $backup"

# ---- 5. Copy the switcher + settings and schedule it -------------------------
foreach ($f in @('rdio-theme-switch.ps1', 'common.ps1')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $f) -Destination (Join-Path $RdioBase $f) -Force
    Unblock-File -LiteralPath (Join-Path $RdioBase $f)
}
Copy-Item -LiteralPath $SettingsSrc -Destination (Join-Path $RdioBase 'settings.txt') -Force
Set-Content -LiteralPath (Join-Path $RdioBase 'themes-folder.txt') -Value $themes -Encoding UTF8

# Every 10 minutes. conhost --headless keeps a PowerShell window from flashing up each time.
$script = Join-Path $RdioBase 'rdio-theme-switch.ps1'
$action = New-ScheduledTaskAction -Execute 'conhost.exe' `
    -Argument "--headless powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$script`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10)
$taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
$principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) `
    -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName $RdioTaskName -Action $action -Trigger $trigger -Settings $taskSettings `
    -Principal $principal -Description 'Switches the Rdio Roon theme between day and night colours at sunrise and sunset.' | Out-Null
Write-Host 'Scheduled: switches at your local sunrise and sunset.'

Write-Host ''
Write-Host 'Done! Next:' -ForegroundColor Green
Write-Host '  1. Quit and reopen Roon.'
Write-Host "  2. In Roon, go to Settings > General > Theme and choose 'Rdio'. Leave it on Rdio."
Write-Host "Log: $(Join-Path $RdioBase 'switch.log')"
