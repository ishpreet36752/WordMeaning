# run.ps1 — launch WordMeaning. Finds AutoHotkey v2 in user-scope or machine-scope install.
$candidates = @(
    "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
)
$ahk = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ahk) {
    Write-Error "AutoHotkey v2 not found. Install: winget install AutoHotkey.AutoHotkey"
    exit 1
}
$main = Join-Path $PSScriptRoot "src\Main.ahk"
Start-Process -FilePath $ahk -ArgumentList "`"$main`""
Write-Output "WordMeaning started (tray icon). Select a word anywhere to see its meaning."
