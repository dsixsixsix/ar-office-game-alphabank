<#
.SYNOPSIS
    Builds the Android plugin and exports the game APK.
.DESCRIPTION
    1. Builds native/android (OfficeGameAndroid AAR) into client/addons/office_game_android/bin.
    2. Installs the Godot Android build template into client/android on the first export.
    3. Exports build/android/office-game-debug.apk (or -release with -Release).
    Needs the toolchain from tools/setup-android.ps1.
.EXAMPLE
    .\tools\build-android.ps1
.EXAMPLE
    .\tools\build-android.ps1 -Install
    Builds and installs the APK on the connected phone (USB debugging on).
#>
param(
    [switch]$Release,
    [switch]$Install
)

$ErrorActionPreference = 'Stop'

# Native tools print warnings to stderr; with 'Stop' Windows PowerShell 5.1 would treat them as errors.
function Invoke-Native([string]$exe, [string[]]$arguments) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $exe @arguments 2>&1 | ForEach-Object { "$_" }
    }
    finally {
        $ErrorActionPreference = $previous
    }
    if ($LASTEXITCODE -ne 0) { throw "$exe failed with code $LASTEXITCODE" }
}

$root = Split-Path $PSScriptRoot -Parent
$client = Join-Path $root 'client'
$env:JAVA_HOME = Join-Path $PSScriptRoot 'jdk'
$env:ANDROID_HOME = Join-Path $PSScriptRoot 'android-sdk'
$env:GRADLE_USER_HOME = Join-Path $PSScriptRoot 'gradle-home'
$godot = Get-ChildItem (Join-Path $PSScriptRoot 'godot') -Filter 'Godot_v*_win64_console.exe' | Select-Object -First 1
if (-not $godot) { throw 'Godot not found in tools/godot.' }
if (-not (Test-Path $env:JAVA_HOME)) { throw 'JDK not found. Run tools/setup-android.ps1 first.' }

Write-Host '== Android plugin'
Push-Location (Join-Path $root 'native/android')
try {
    Invoke-Native '.\gradlew.bat' @('--no-daemon', 'assembleDebug', 'assembleRelease')
}
finally {
    Pop-Location
}

$buildType = if ($Release) { 'release' } else { 'debug' }
$outDir = Join-Path $root 'build/android'
New-Item -ItemType Directory -Force $outDir | Out-Null
$apk = Join-Path $outDir "office-game-$buildType.apk"
Write-Host "== Export $apk"
$exportArgs = @('--headless', '--path', $client)
# The Gradle build template is installed into client/android on the first export.
if (-not (Test-Path (Join-Path $client 'android/build'))) { $exportArgs += '--install-android-build-template' }
Invoke-Native $godot.FullName ($exportArgs + @("--export-$buildType", 'Android', $apk))
if (-not (Test-Path $apk)) { throw 'Godot export failed' }

if ($Install) {
    Invoke-Native (Join-Path $env:ANDROID_HOME 'platform-tools/adb.exe') @('install', '-r', $apk)
}
