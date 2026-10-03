<#
.SYNOPSIS
    Laxtic Studios - dependency setup for Windows.

.DESCRIPTION
    Laxtic Studios does its transcoding, its exports and every frame it reads
    through ffmpeg, on your machine. ffmpeg is NOT bundled with the app:
    shipping it would add a couple of hundred megabytes to every download, and
    it would be our build of it rather than the one your system trusts and
    updates. So the app looks for the one you already have, and this script is
    here to make sure you have one.

    It looks where the app looks: the FFMPEG_PATH environment variable first,
    then PATH.

    If ffmpeg and ffprobe are already there, this script changes nothing and
    says so. If they are not, it shows you the exact command it wants to run,
    asks, and runs it only if you agree. Nothing is installed behind your back,
    and nothing is downloaded from anywhere but winget or Chocolatey.

.PARAMETER Check
    Check only, install nothing. Exits 1 if something is missing.

.PARAMETER Yes
    Install what is missing without asking.

.EXAMPLE
    .\setup.ps1
    Check, and offer to install what is missing.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\setup.ps1
    The same, when your execution policy would otherwise block the script.
#>
[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------ appearance
function Write-Ok   { param($m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Write-Bad  { param($m) Write-Host "  [--]   $m" -ForegroundColor Red }
function Write-Note { param($m) Write-Host "         $m" -ForegroundColor DarkGray }
function Write-Head { param($m) Write-Host ""; Write-Host $m -ForegroundColor White }

Write-Host "Laxtic Studios - dependency setup"
Write-Note "Windows $([System.Environment]::OSVersion.Version) ($env:PROCESSOR_ARCHITECTURE)"

# ------------------------------------------------------------------- discovery
# The app's own search order, reproduced so that what this reports is what the
# app will find. The extra directories cover the two package managers' default
# install locations, which are on PATH for new shells but not for the one that
# is already open when the install finishes.
function Get-ExtraDirs {
    # Computed on every call, not once at startup: winget and Chocolatey create
    # their links directory as part of installing, so a list captured before
    # the install can miss the folder the binary just landed in.
    @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links",
        "$env:ProgramData\chocolatey\bin",
        "$env:ProgramFiles\ffmpeg\bin"
    ) | Where-Object { $_ -and (Test-Path $_) }
}

function Find-Tool {
    param([string]$Name)

    $override = if ($Name -eq 'ffmpeg') { $env:FFMPEG_PATH } else { $env:FFPROBE_PATH }
    if ($override -and (Test-Path $override)) { return $override }

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    foreach ($dir in (Get-ExtraDirs)) {
        $candidate = Join-Path $dir "$Name.exe"
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

function Get-ToolVersion {
    param([string]$Path)
    try {
        $line = & $Path -version 2>$null | Select-Object -First 1
        return ($line -replace ' Copyright.*', '')
    } catch { return 'unknown' }
}

# ---------------------------------------------------------------- what is here
Write-Head "Checking what you already have"

$missing = $false

$ffmpeg = Find-Tool 'ffmpeg'
if ($ffmpeg) {
    Write-Ok "ffmpeg   $ffmpeg"
    Write-Note (Get-ToolVersion $ffmpeg)
} else {
    Write-Bad "ffmpeg   not found"
    $missing = $true
}

$ffprobe = Find-Tool 'ffprobe'
if ($ffprobe) {
    Write-Ok "ffprobe  $ffprobe"
} else {
    Write-Bad "ffprobe  not found"
    $missing = $true    # ffprobe ships with ffmpeg; installing ffmpeg fixes both
}

if (-not $missing) {
    Write-Head "Nothing to do"
    Write-Host "  Laxtic Studios has everything it needs."
    Write-Host ""
    exit 0
}

if ($Check) {
    Write-Head "Something is missing"
    Write-Host "  Run .\setup.ps1 to install it."
    Write-Host ""
    exit 1
}

# -------------------------------------------------------- the install command
# One package manager, chosen from what is actually on this machine. The
# command is printed before it runs, every time.
$manager = $null
$exe     = $null
$exeArgs = $null

if (Get-Command winget -ErrorAction SilentlyContinue) {
    $manager = 'winget'
    $exe     = 'winget'
    # Gyan.FFmpeg is the build winget's own community repository ships.
    # --accept-*-agreements stops it stopping to ask mid-install.
    $exeArgs = @(
        'install', '--id', 'Gyan.FFmpeg', '-e', '--source', 'winget',
        '--accept-package-agreements', '--accept-source-agreements'
    )
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    $manager = 'Chocolatey'
    $exe     = 'choco'
    $exeArgs = @('install', 'ffmpeg', '-y')
} else {
    Write-Head "No package manager I recognise"
    Write-Host @"
  I looked for winget and Chocolatey and found neither, so I cannot install
  ffmpeg for you without guessing.

  winget ships with Windows 10 1709 and later as "App Installer". If you do
  not have it, install it from the Microsoft Store, then run this script
  again.

  Or install ffmpeg yourself from https://www.gyan.dev/ffmpeg/builds/, unzip
  it, and either put its bin folder on your PATH or point the app straight at
  it:

      setx FFMPEG_PATH "C:\path\to\ffmpeg.exe"

"@
    exit 1
}

Write-Head "What I would like to run"
Write-Host "  $exe $($exeArgs -join ' ')" -ForegroundColor White
Write-Note "package manager: $manager"

if (-not $Yes) {
    $reply = Read-Host "`n  Run it? [y/N]"
    if ($reply -notmatch '^(y|yes)$') {
        Write-Host ""
        Write-Host "  Nothing was installed."
        Write-Host ""
        exit 1
    }
}

Write-Head "Installing"
& $exe @exeArgs
$code = $LASTEXITCODE

# The exit code is NOT the verdict. winget answers non-zero for things that are
# not failures - "already installed", "no applicable update" - and the exact
# constants have changed between releases. Whether ffmpeg is on this machine is
# the only question that matters, and the check below answers it directly. The
# code is kept only so a genuine failure can be reported with its number.

# ------------------------------------------------------------------ confirm it
# A package manager puts the new binary on the MACHINE PATH, which this
# already-running process does not see. Re-read it before deciding it failed.
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path', 'User')

Write-Head "Checking again"
$stillMissing = $false
foreach ($tool in @('ffmpeg', 'ffprobe')) {
    $found = Find-Tool $tool
    if ($found) { Write-Ok "$tool  $found" }
    else        { Write-Bad "$tool  still not found"; $stillMissing = $true }
}

if ($stillMissing) {
    Write-Host ""
    Write-Host "  $manager finished with exit code $code, and ffmpeg is still not"
    Write-Host "  anywhere the app looks."
    Write-Host "  Close this window, open a new one, and run this script again -"
    Write-Host "  a new terminal picks up the PATH the installer just changed."
    Write-Host ""
    Write-Host "  If it still cannot be found, point the app straight at it:"
    Write-Host ""
    Write-Host '      setx FFMPEG_PATH "C:\path\to\ffmpeg.exe"'
    Write-Host ""
    exit 1
}

Write-Head "Done"
Write-Host "  Laxtic Studios has everything it needs. Open the app and export something."
Write-Host ""
