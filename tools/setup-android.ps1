<#
.SYNOPSIS
    Installs the local toolchain for Android builds into tools/ (nothing system-wide).
.DESCRIPTION
    - Temurin JDK 17                         -> tools/jdk
    - Android SDK: cmdline-tools, platform-tools, platform 36, build-tools 36.1.0 -> tools/android-sdk
    - Godot 4.7.2 export templates           -> %APPDATA%/Godot/export_templates/4.7.2.stable
    - Debug keystore                         -> tools/android/debug.keystore
    - Godot editor settings: JDK, SDK and keystore paths (a backup of the settings file is kept)
    Godot itself is expected in tools/godot (see README).
.EXAMPLE
    .\tools\setup-android.ps1
#>
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

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
$tools = $PSScriptRoot
$downloads = Join-Path $tools 'downloads'
New-Item -ItemType Directory -Force $downloads | Out-Null

$godotVersion = '4.7.2'
$jdkUrl = 'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.20.1%2B1/OpenJDK17U-jdk_x64_windows_hotspot_17.0.20.1_1.zip'
$sdkToolsUrl = 'https://dl.google.com/android/repository/commandlinetools-win-16111833_latest.zip'
$templatesUrl = "https://github.com/godotengine/godot/releases/download/$godotVersion-stable/Godot_v$godotVersion-stable_export_templates.tpz"
$sdkPackages = @('platform-tools', 'platforms;android-36', 'build-tools;36.1.0')

function Get-File([string]$url, [string]$name) {
    $path = Join-Path $downloads $name
    if (-not (Test-Path $path)) {
        Write-Host "Downloading $name"
        Invoke-WebRequest $url -OutFile $path
    }
    return $path
}

# JDK
$jdk = Join-Path $tools 'jdk'
if (-not (Test-Path $jdk)) {
    $zip = Get-File $jdkUrl 'jdk17.zip'
    Expand-Archive $zip -DestinationPath $downloads -Force
    Move-Item (Get-ChildItem $downloads -Directory -Filter 'jdk-17*' | Select-Object -First 1).FullName $jdk
}
$env:JAVA_HOME = $jdk

# Android SDK
$sdk = Join-Path $tools 'android-sdk'
$sdkManager = Join-Path $sdk 'cmdline-tools/latest/bin/sdkmanager.bat'
if (-not (Test-Path $sdkManager)) {
    $zip = Get-File $sdkToolsUrl 'cmdline-tools.zip'
    $unpacked = Join-Path $downloads 'cmdline-tools-unpacked'
    Expand-Archive $zip -DestinationPath $unpacked -Force
    New-Item -ItemType Directory -Force (Join-Path $sdk 'cmdline-tools') | Out-Null
    Move-Item (Join-Path $unpacked 'cmdline-tools') (Join-Path $sdk 'cmdline-tools/latest')
}
# Package names contain ';', which cmd.exe would split, so they go through a file.
$packageFile = Join-Path $downloads 'packages.txt'
Set-Content $packageFile ($sdkPackages -join "`n") -Encoding ascii
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
"y`n" * 20 | & $sdkManager "--sdk_root=$sdk" --licenses 2>&1 | Out-Null
$ErrorActionPreference = $previous
Invoke-Native $sdkManager @("--sdk_root=$sdk", "--package_file=$packageFile")

# Godot export templates
$templates = Join-Path $env:APPDATA "Godot/export_templates/$godotVersion.stable"
if (-not (Test-Path (Join-Path $templates 'android_source.zip'))) {
    $tpz = Get-File $templatesUrl 'templates.tpz'
    $unpacked = Join-Path $downloads 'templates-unpacked'
    Expand-Archive $tpz -DestinationPath $unpacked -Force
    New-Item -ItemType Directory -Force $templates | Out-Null
    Copy-Item (Join-Path $unpacked 'templates/*') $templates -Recurse -Force
}

# Debug keystore (standard Android debug credentials)
$keystore = Join-Path $tools 'android/debug.keystore'
if (-not (Test-Path $keystore)) {
    New-Item -ItemType Directory -Force (Split-Path $keystore) | Out-Null
    Invoke-Native (Join-Path $jdk 'bin/keytool.exe') @(
        '-genkeypair', '-keystore', $keystore, '-storepass', 'android', '-alias', 'androiddebugkey',
        '-keypass', 'android', '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000',
        '-dname', 'CN=Android Debug,O=Android,C=US'
    )
}

# Godot editor settings
$settings = Join-Path $env:APPDATA 'Godot/editor_settings-4.7.tres'
if (Test-Path $settings) {
    Copy-Item $settings "$settings.bak" -Force
    $text = Get-Content $settings -Raw -Encoding utf8
    $values = [ordered]@{
        'export/android/java_sdk_path'      = $jdk
        'export/android/android_sdk_path'   = $sdk
        'export/android/debug_keystore'     = $keystore
        'export/android/debug_keystore_user' = 'androiddebugkey'
        'export/android/debug_keystore_pass' = 'android'
    }
    foreach ($key in $values.Keys) {
        $line = '{0} = "{1}"' -f $key, ($values[$key] -replace '\\', '/')
        $pattern = '(?m)^' + [regex]::Escape($key) + ' = .*$'
        if ($text -match $pattern) { $text = $text -replace $pattern, $line.Replace('$', '$$') }
        else { $text = $text.TrimEnd() + "`n" + $line + "`n" }
    }
    [IO.File]::WriteAllText($settings, $text)
}
else {
    Write-Warning "Open the Godot editor once, then run this script again to set the Android paths in $settings"
}
Write-Host 'Android toolchain is ready. Build with tools/build-android.ps1'
