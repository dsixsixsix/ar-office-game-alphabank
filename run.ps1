<#
.SYNOPSIS
    Runs the Godot client on the desktop, emulating a phone screen.
.EXAMPLE
    .\run.ps1 -Device iphone_15
.EXAMPLE
    .\run.ps1 -Device iphone_17_pro -ScreenDpi 109
#>
param(
    [ValidateSet('pixel_8', 'iphone_15', 'iphone_17_pro', 'iphone_17_pro_max', 'galaxy_s24', 'android_hd', 'iphone_se', 'desktop')]
    [string]$Device = 'pixel_8',
    # Monitor pixel density for the real-size phone window; the OS value is used when omitted.
    [double]$ScreenDpi = 0
)

$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot 'client'
$godotDir = Join-Path $PSScriptRoot 'tools\godot'

$console = Get-ChildItem $godotDir -Filter 'Godot_v*_win64_console.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
$gui = Get-ChildItem $godotDir -Filter 'Godot_v*_win64.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $console -or -not $gui) {
    throw "Godot not found in $godotDir. Download Godot 4.7 (win64) and unpack it there."
}

if (-not (Test-Path (Join-Path $project '.godot'))) {
    Write-Host 'First run: importing assets...'
    & $console.FullName --headless --path $project --import
}

$arguments = @('--path', "`"$project`"")
if ($Device -ne 'desktop') {
    $arguments += @('--', "--device=$Device")
    if ($ScreenDpi -gt 0) {
        $arguments += "--screen-dpi=$([string]::Format([cultureinfo]::InvariantCulture, '{0}', $ScreenDpi))"
    }
}
Start-Process -FilePath $gui.FullName -ArgumentList $arguments
