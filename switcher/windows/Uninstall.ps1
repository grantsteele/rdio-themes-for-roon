# Removes the day/night switcher. The Rdio and Rdio Night themes stay in Roon.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

if (Get-ScheduledTask -TaskName $RdioTaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $RdioTaskName -Confirm:$false
}
Write-Host 'Removed the scheduled task.'

# Leave Rdio on the day colours.
$cache = Join-Path $RdioBase 'themes-folder.txt'
$savedDay = Join-Path $RdioBase 'day\colors'
if ((Test-Path -LiteralPath $cache) -and (Test-Path -LiteralPath $savedDay)) {
    $rdio = Join-Path (Get-Content -LiteralPath $cache -TotalCount 1).Trim() 'Rdio\colors'
    if ((Test-Path -LiteralPath $rdio) -and -not (Test-RdioSameFile $rdio $savedDay)) {
        Copy-RdioFile $savedDay $rdio
        Write-Host 'Rdio theme is back on your day colours.'
    }
}
Write-Host "Switcher removed. Your backups are kept in: $(Join-Path $RdioBase 'backups')"
