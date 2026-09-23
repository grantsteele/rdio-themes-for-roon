# Rdio day/night switcher for Roon (Windows).
# Keep Roon's theme set to "Rdio". At sunset this copies your night colours into the
# Rdio theme; at sunrise, your day colours. Task Scheduler runs it every 10 minutes.
#
# Settings live in %LOCALAPPDATA%\RdioThemeSwitch\settings.txt (copied there by the
# installer). Edit settings.txt in the download folder and run Install.cmd again to change them.
#
# Test it by hand:  powershell -ExecutionPolicy Bypass -File rdio-theme-switch.ps1 night
param([string]$Force = '')

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
$Log = Join-Path $RdioBase 'switch.log'
function Write-Log([string]$Message) {
    Add-Content -LiteralPath $Log -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $Message)
}
function Format-Time([long]$Unix) { [DateTimeOffset]::FromUnixTimeSeconds($Unix).LocalDateTime.ToString('HH:mm') }

try {
    $settings = Read-RdioSettings (Join-Path $RdioBase 'settings.txt')
    $lat = ConvertTo-RdioNumber $settings['LATITUDE']
    $lon = ConvertTo-RdioNumber $settings['LONGITUDE']
    if ($null -eq $lat -or $null -eq $lon) { Write-Log 'ERROR: LATITUDE/LONGITUDE in settings.txt are not numbers. Fix them and run Install.cmd again.'; exit 1 }

    $times = Get-RdioSunTimes $lat $lon
    $rise = $times[0] + 60 * (ConvertTo-RdioInt $settings['SUNRISE_OFFSET_MIN'])
    $set = $times[1] + 60 * (ConvertTo-RdioInt $settings['SUNSET_OFFSET_MIN'])
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    if ($Force) { $mode = $Force }
    elseif ($now -ge $rise -and $now -lt $set) { $mode = 'day' }
    else { $mode = 'night' }

    $day = Join-Path $RdioBase 'day\colors'
    $night = Join-Path $RdioBase 'night\colors'
    $want = Join-Path $RdioBase "$mode\colors"
    if (-not (Test-Path -LiteralPath $want)) { Write-Log "ERROR: saved $mode colours missing. Run Install.cmd again."; exit 1 }

    # Find the Rdio theme. A Roon update can move Roon's Themes folder; if so, put the themes back.
    $cache = Join-Path $RdioBase 'themes-folder.txt'
    $themes = ''
    if (Test-Path -LiteralPath $cache) { $themes = (Get-Content -LiteralPath $cache -TotalCount 1).Trim() }
    if (-not $themes -or -not (Test-Path -LiteralPath (Join-Path $themes 'Rdio\colors'))) {
        $themes = Find-RoonThemesFolder $settings
        if (-not $themes) { Write-Log "ERROR: can't find Roon's Themes folder. Run Install.cmd again."; exit 1 }
        foreach ($t in @(@('Rdio', $day), @('Rdio Night', $night))) {
            $dir = Join-Path $themes $t[0]
            if (-not (Test-Path -LiteralPath (Join-Path $dir 'colors'))) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $dir 'name') -Value $t[0] -NoNewline -Encoding Ascii
                Copy-Item -LiteralPath $t[1] -Destination (Join-Path $dir 'colors') -Force
                Write-Log "Put the '$($t[0])' theme back into $themes (Roon update?). You may need to choose Rdio in Roon's settings again."
            }
        }
        Set-Content -LiteralPath $cache -Value $themes -Encoding UTF8
    }
    $target = Join-Path $themes 'Rdio\colors'

    # Already correct? Nothing to do.
    if (Test-RdioSameFile $target $want) { exit 0 }

    # Safety: only overwrite if Rdio currently holds one of the two saved versions.
    if (-not (Test-RdioSameFile $target $day) -and -not (Test-RdioSameFile $target $night)) {
        Write-Log 'SKIPPED: Rdio\colors has been edited (matches neither saved day nor night). Not touching it. Run Install.cmd again to save your edits.'
        exit 0
    }

    Copy-RdioFile $want $target
    Write-Log "Switched to $mode (sunrise $(Format-Time $rise), sunset $(Format-Time $set))"

    # Roon only loads theme colours when it starts.
    if ($settings['RESTART_ROON'] -ne '0') {
        $procs = @(Get-Process -Name 'Roon' -ErrorAction SilentlyContinue)
        if ($procs.Count -gt 0) {
            $exe = Join-Path $env:LOCALAPPDATA 'Roon\Application\Roon.exe'
            if (-not (Test-Path -LiteralPath $exe)) { $exe = $procs[0].Path }
            foreach ($p in $procs) { [void]$p.CloseMainWindow() }
            for ($i = 0; $i -lt 20; $i++) {
                if (-not (Get-Process -Name 'Roon' -ErrorAction SilentlyContinue)) { break }
                Start-Sleep -Seconds 1
            }
            Get-Process -Name 'Roon' -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Seconds 2
            if ($exe) { Start-Process -FilePath $exe }
            Write-Log 'Restarted Roon'
        }
    }
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
