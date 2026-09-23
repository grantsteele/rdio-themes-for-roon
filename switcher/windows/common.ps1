# Shared helpers for the Rdio day/night switcher (Windows). Used by Install.ps1 and rdio-theme-switch.ps1.

$RdioBase = Join-Path $env:LOCALAPPDATA 'RdioThemeSwitch'
$RdioTaskName = 'Rdio theme switch for Roon'
$Invariant = [Globalization.CultureInfo]::InvariantCulture

# Reads KEY=value lines from settings.txt, ignoring blank lines and # comments.
function Read-RdioSettings([string]$Path) {
    $s = @{}
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        $t = $line.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        $i = $t.IndexOf('=')
        if ($i -lt 1) { continue }
        $s[$t.Substring(0, $i).Trim()] = $t.Substring($i + 1).Trim()
    }
    return $s
}

# Numbers always use a dot, whatever the Windows region setting is.
function ConvertTo-RdioNumber([string]$Value) {
    $d = 0.0
    if ($Value -match '^-?[0-9]+(\.[0-9]+)?$' -and
        [double]::TryParse($Value, [Globalization.NumberStyles]::Float, $Invariant, [ref]$d)) { return $d }
    return $null
}

function ConvertTo-RdioInt([string]$Value) {
    if ($Value -match '^-?[0-9]+$') { return [int]$Value }
    return 0
}

# Roon keeps its themes in a folder called "Themes" somewhere under its install folder.
# Roon updates can move it, so we look for the newest one that contains at least one theme.
function Find-RoonThemesFolder([hashtable]$Settings) {
    $custom = $Settings['ROON_THEMES_FOLDER']
    if ($custom) {
        if (Test-Path -LiteralPath $custom -PathType Container) { return $custom }
        return $null
    }
    $roots = @((Join-Path $env:LOCALAPPDATA 'Roon\Application'))
    if ($env:ProgramFiles) { $roots += (Join-Path $env:ProgramFiles 'Roon') }
    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $found = Get-ChildItem -LiteralPath $root -Recurse -Directory -Filter 'Themes' -ErrorAction SilentlyContinue |
            Where-Object {
                @(Get-ChildItem -LiteralPath $_.FullName -Directory -ErrorAction SilentlyContinue |
                  Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'colors') }).Count -gt 0
            } |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

function Test-RdioSameFile([string]$A, [string]$B) {
    if (-not (Test-Path -LiteralPath $A) -or -not (Test-Path -LiteralPath $B)) { return $false }
    return (Get-FileHash -LiteralPath $A).Hash -eq (Get-FileHash -LiteralPath $B).Hash
}

# Copies a file via a temporary file so Roon never sees a half-written theme.
function Copy-RdioFile([string]$From, [string]$To) {
    Copy-Item -LiteralPath $From -Destination "$To.tmp" -Force
    Move-Item -LiteralPath "$To.tmp" -Destination $To -Force
}

# Today's sunrise and sunset as Unix times (same formula as the Mac version).
# Near the poles: midnight sun = day all day, polar night = night all day.
function Get-RdioSunTimes([double]$Lat, [double]$Lon) {
    $rad = [Math]::PI / 180
    $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $nowS = [long][Math]::Floor($nowMs / 1000)
    $jdNow = $nowMs / 86400000 + 2440587.5
    $n = [Math]::Floor($jdNow - 2451545.0 + 0.0008 + $Lon / 360 + 0.5)
    $Js = $n - $Lon / 360
    $M = (357.5291 + 0.98560028 * $Js) % 360
    $C = 1.9148 * [Math]::Sin($M * $rad) + 0.02 * [Math]::Sin(2 * $M * $rad) + 0.0003 * [Math]::Sin(3 * $M * $rad)
    $L = ($M + $C + 180 + 102.9372) % 360
    $Jt = 2451545.0 + $Js + 0.0053 * [Math]::Sin($M * $rad) - 0.0069 * [Math]::Sin(2 * $L * $rad)
    $sd = [Math]::Sin($L * $rad) * [Math]::Sin(23.4397 * $rad)
    $cd = [Math]::Cos([Math]::Asin($sd))
    $cosw = ([Math]::Sin(-0.833 * $rad) - [Math]::Sin($Lat * $rad) * $sd) / ([Math]::Cos($Lat * $rad) * $cd)
    if ($cosw -ge 1) { return @([long]0, [long]0) }
    if ($cosw -le -1) { return @(($nowS - 86400), ($nowS + 86400)) }
    $w = [Math]::Acos($cosw) / $rad
    $rise = [long][Math]::Floor(($Jt - $w / 360 - 2440587.5) * 86400 + 0.5)
    $set = [long][Math]::Floor(($Jt + $w / 360 - 2440587.5) * 86400 + 0.5)
    return @($rise, $set)
}
