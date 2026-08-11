# test-compiled.ps1 — compiles tests\ResourceTest.ahk and runs it, to prove the
# .exe can read the dictionary embedded in it as a resource.
#
#   .\scripts\test-compiled.ps1
#
# The plain-script tests cover LocalDictionary's file-backed path. Only a real
# compile covers the resource path, and that is the one every downloaded build
# actually uses.
param(
    [string]$AutoHotkeyPath = $env:WM_AUTOHOTKEY,
    [string]$Ahk2ExePath    = $env:WM_AHK2EXE
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Resolve-Tool {
    param([string]$Explicit, [string[]]$Candidates, [string]$Name)
    if ($Explicit) {
        if (-not (Test-Path $Explicit)) { throw "$Name not found at: $Explicit" }
        return (Resolve-Path $Explicit).Path
    }
    $found = $Candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    if (-not $found) { throw "$Name not found." }
    return (Resolve-Path $found).Path
}

$base = Resolve-Tool -Explicit $AutoHotkeyPath -Name 'AutoHotkey v2' -Candidates @(
    "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
)
$ahk2exe = Resolve-Tool -Explicit $Ahk2ExePath -Name 'Ahk2Exe' -Candidates @(
    "$env:LOCALAPPDATA\Programs\AutoHotkey\Compiler\Ahk2Exe.exe",
    "$env:ProgramFiles\AutoHotkey\Compiler\Ahk2Exe.exe"
)

$outDir = Join-Path $root 'dist'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
$exe = Join-Path $outDir 'ResourceTest.exe'
if (Test-Path $exe) { Remove-Item $exe -Force }

Write-Host "Compiling tests\ResourceTest.ahk"
$compileArgs = @('/in', "$root\tests\ResourceTest.ahk", '/out', $exe,
                 '/base', $base, '/silent', 'verbose')
$proc = Start-Process -FilePath $ahk2exe -ArgumentList $compileArgs -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -ne 0) { throw "Ahk2Exe failed (exit $($proc.ExitCode))." }
if (-not (Test-Path $exe)) { throw "Compile reported success but $exe is missing." }
Write-Host ("Built {0} ({1:N0} bytes)" -f $exe, (Get-Item $exe).Length)

$log = Join-Path $env:TEMP 'wordmeaning-resourcetest.txt'
if (Test-Path $log) { Remove-Item $log -Force }

$run = Start-Process -FilePath $exe -Wait -PassThru
if (Test-Path $log) { Get-Content $log | ForEach-Object { Write-Host "  $_" } }

if ($run.ExitCode -ne 0) {
    throw "ResourceTest failed with $($run.ExitCode) failing check(s)."
}
Write-Host "Compiled build reads its embedded dictionary. ALL PASS"
