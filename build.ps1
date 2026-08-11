# build.ps1 — compile WordMeaning into a single standalone dist\WordMeaning.exe,
# then (if Inno Setup is available) dist\WordMeaning-Setup.exe.
#
# The .exe bundles every src module and embeds the tray icon, so it runs on any
# Windows PC with no AutoHotkey install and no source files present.
#
#   .\build.ps1                      # local build, finds the tools itself
#   .\build.ps1 -RequireInstaller    # fail instead of skipping the installer
#
# CI runs this exact script with the tool paths passed in, so a released binary
# comes out of the same build path a maintainer runs locally — there is no
# separate "release build" to drift from this one.
#
param(
    # Explicit tool locations. Each falls back to an env var, then to a search of
    # the usual install directories.
    [string]$AutoHotkeyPath = $env:WM_AUTOHOTKEY,
    [string]$Ahk2ExePath    = $env:WM_AHK2EXE,
    [string]$InnoSetupPath  = $env:WM_ISCC,

    # Treat a missing Inno Setup as an error. CI sets this: a release that
    # silently shipped only the portable .exe would be a broken release.
    [switch]$RequireInstaller
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

# Returns the first existing path: the explicit one if given, else the candidates.
function Resolve-Tool {
    param([string]$Explicit, [string[]]$Candidates, [string]$Name)
    if ($Explicit) {
        if (-not (Test-Path $Explicit)) { throw "$Name not found at the given path: $Explicit" }
        return (Resolve-Path $Explicit).Path
    }
    $found = $Candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    if ($found) { return (Resolve-Path $found).Path }
    return $null
}

# --- Locate the AutoHotkey v2 runtime (used as the compile base) ---
$base = Resolve-Tool -Explicit $AutoHotkeyPath -Name 'AutoHotkey v2' -Candidates @(
    "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
)
if (-not $base) { throw "AutoHotkey v2 not found. Install it, then re-run." }

# --- Locate the Ahk2Exe compiler ---
$ahk2exe = Resolve-Tool -Explicit $Ahk2ExePath -Name 'Ahk2Exe' -Candidates @(
    "$env:LOCALAPPDATA\Programs\AutoHotkey\Compiler\Ahk2Exe.exe",
    "$env:ProgramFiles\AutoHotkey\Compiler\Ahk2Exe.exe"
)
if (-not $ahk2exe) {
    throw "Ahk2Exe compiler not found. In the AutoHotkey install folder run UX\install-ahk2exe.ahk, or download it from https://github.com/AutoHotkey/Ahk2Exe/releases and unzip into ...\AutoHotkey\Compiler\."
}

Write-Host "AutoHotkey: $base"
Write-Host "Ahk2Exe:    $ahk2exe"

# --- The bundled dictionary must exist before compiling: Ahk2Exe resolves the
# FileInstall in Main.ahk at compile time and fails if the file is missing. ---
$dictionary = Join-Path $root 'assets\dictionary.dat'
if (-not (Test-Path $dictionary)) {
    throw "assets\dictionary.dat is missing. Build it first with:`n  .\scripts\build-dictionary.ps1"
}
Write-Host ("Dictionary: {0}  ({1:N0} bytes)" -f $dictionary, (Get-Item $dictionary).Length)

$dist = Join-Path $root 'dist'
if (-not (Test-Path $dist)) { New-Item -ItemType Directory -Force -Path $dist | Out-Null }
$out = Join-Path $dist 'WordMeaning.exe'

Write-Host "Compiling -> $out"
# Ahk2Exe is a GUI-subsystem exe: `&` would not block, so use Start-Process -Wait.
$compileArgs = @('/in', "$root\src\Main.ahk", '/out', $out,
                 '/icon', "$root\assets\wordmeaning.ico", '/base', $base, '/silent', 'verbose')
$proc = Start-Process -FilePath $ahk2exe -ArgumentList $compileArgs -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -ne 0) { throw "Ahk2Exe failed (exit $($proc.ExitCode))." }
if (-not (Test-Path $out)) { throw "Compile reported success but $out is missing." }

Write-Host ("Portable exe: {0}  ({1:N0} bytes)" -f $out, (Get-Item $out).Length)

# --- Build the Setup.exe installer if Inno Setup is available ---
$iscc = Resolve-Tool -Explicit $InnoSetupPath -Name 'Inno Setup (ISCC.exe)' -Candidates @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
)
if ($iscc) {
    Write-Host "Building installer with Inno Setup..."
    & $iscc "$root\installer\WordMeaning.iss" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed (exit $LASTEXITCODE)." }
    $setup = Join-Path $dist 'WordMeaning-Setup.exe'
    Write-Host ("Installer:    {0}  ({1:N0} bytes)" -f $setup, (Get-Item $setup).Length)
} elseif ($RequireInstaller) {
    throw "Inno Setup (ISCC.exe) not found and -RequireInstaller was set."
} else {
    Write-Host "Inno Setup not found - skipped installer. (Install from https://jrsoftware.org/isdl.php to also build WordMeaning-Setup.exe.)"
}

# --- Checksums, so a download can be verified against this build ---
# Named explicitly, not globbed: dist\ also collects test binaries, and a
# checksum file listing files nobody downloads is just noise.
$sums = Join-Path $dist 'SHA256SUMS.txt'
@('WordMeaning-Setup.exe', 'WordMeaning.exe') |
    ForEach-Object { Join-Path $dist $_ } |
    Where-Object { Test-Path $_ } |
    ForEach-Object {
        "{0}  {1}" -f (Get-FileHash $_ -Algorithm SHA256).Hash.ToLower(), (Split-Path $_ -Leaf)
    } | Set-Content -Path $sums -Encoding ascii
Write-Host ""
Write-Host "SHA256:"
Get-Content $sums | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "Done. Double-click WordMeaning.exe to run, or copy it anywhere as a portable backup."
Write-Host ""
Write-Host "Releases are built and published by CI - push a tag instead of uploading by hand:"
Write-Host "  git tag v1.1.0 && git push origin v1.1.0"
Write-Host "(.github\workflows\release.yml rebuilds from that tag, attaches build provenance, and uploads the assets.)"
