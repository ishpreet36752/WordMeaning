# build.ps1 — compile WordMeaning into a single standalone dist\WordMeaning.exe.
# The .exe bundles every src module and embeds the tray icon, so it runs on any
# Windows PC with no AutoHotkey install and no source files present.
#
#   .\build.ps1
#
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

# --- Locate the AutoHotkey v2 runtime (used as the compile base) ---
$baseCandidates = @(
    "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
)
$base = $baseCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $base) { throw "AutoHotkey v2 not found. Install it, then re-run." }

# --- Locate the Ahk2Exe compiler ---
$compCandidates = @(
    "$env:LOCALAPPDATA\Programs\AutoHotkey\Compiler\Ahk2Exe.exe",
    "$env:ProgramFiles\AutoHotkey\Compiler\Ahk2Exe.exe"
)
$ahk2exe = $compCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ahk2exe) {
    throw "Ahk2Exe compiler not found. In the AutoHotkey install folder run UX\install-ahk2exe.ahk, or download it from https://github.com/AutoHotkey/Ahk2Exe/releases and unzip into ...\AutoHotkey\Compiler\."
}

$dist = Join-Path $root 'dist'
if (-not (Test-Path $dist)) { New-Item -ItemType Directory -Force -Path $dist | Out-Null }
$out = Join-Path $dist 'WordMeaning.exe'

Write-Host "Compiling -> $out"
# Ahk2Exe is a GUI-subsystem exe: `&` would not block, so use Start-Process -Wait.
$args = @('/in', "$root\src\Main.ahk", '/out', $out,
          '/icon', "$root\assets\wordmeaning.ico", '/base', $base, '/silent', 'verbose')
$proc = Start-Process -FilePath $ahk2exe -ArgumentList $args -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -ne 0) { throw "Ahk2Exe failed (exit $($proc.ExitCode))." }
if (-not (Test-Path $out)) { throw "Compile reported success but $out is missing." }

Write-Host ("Done. {0}  ({1:N0} bytes)" -f $out, (Get-Item $out).Length)
Write-Host "Double-click it to run, or copy it anywhere as a portable backup."
