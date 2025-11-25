# Flutter Wireless Run Script
# Simplified script to run Flutter apps wirelessly with automatic connection management

param(
    [string]$Mode = "debug",
    [switch]$AutoConnect,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Flutter Wireless Run Script
============================

Usage: .\flutter-wireless.ps1 [-Mode <mode>] [-AutoConnect]

Options:
  -Mode         Build mode: debug, profile, or release (default: debug)
  -AutoConnect  Automatically attempt wireless connection if not connected
  -Help         Show this help message

Examples:
  .\flutter-wireless.ps1                    # Run in debug mode
  .\flutter-wireless.ps1 -Mode profile      # Run in profile mode (optimized with logs)
  .\flutter-wireless.ps1 -Mode release      # Run in release mode (production build)
  .\flutter-wireless.ps1 -AutoConnect       # Auto-connect if needed

This script:
1. Checks for wireless ADB connection
2. Optionally auto-connects if device is on USB
3. Runs Flutter with the specified mode
4. Provides helpful error messages

"@ -ForegroundColor Cyan
    exit 0
}

Write-Host "`n🚀 Flutter Wireless Run" -ForegroundColor Cyan
Write-Host "======================`n" -ForegroundColor Cyan

# Locate ADB
$adbPath = "C:\Users\premprashant\AppData\Local\Android\sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    $androidHome = $env:ANDROID_HOME
    if ($androidHome) {
        $adbPath = Join-Path $androidHome "platform-tools\adb.exe"
    }
}

if (-not (Test-Path $adbPath)) {
    Write-Host "✗ ERROR: ADB not found!" -ForegroundColor Red
    exit 1
}

# Check for connected devices
Write-Host "📱 Checking device connection..." -ForegroundColor Cyan
$devicesOutput = & $adbPath devices
$wirelessDevices = $devicesOutput | Select-String -Pattern "(\d+\.\d+\.\d+\.\d+:\d+)\s+device"
$usbDevices = $devicesOutput | Select-String "device$" | Where-Object { $_.Line -notmatch "\d+\.\d+\.\d+\.\d+" }

if ($wirelessDevices.Count -gt 0) {
    Write-Host "✓ Wireless device connected: $($wirelessDevices[0].Matches.Groups[1].Value)" -ForegroundColor Green
} elseif ($usbDevices.Count -gt 0 -and $AutoConnect) {
    Write-Host "⚠️  Device connected via USB, attempting wireless connection..." -ForegroundColor Yellow
    & "$PSScriptRoot\wireless-connect.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to establish wireless connection" -ForegroundColor Red
        exit 1
    }
} elseif ($usbDevices.Count -gt 0) {
    Write-Host "⚠️  Device is connected via USB (not wireless)" -ForegroundColor Yellow
    Write-Host "`nOptions:" -ForegroundColor Cyan
    Write-Host "  1. Run with -AutoConnect flag to setup wireless automatically" -ForegroundColor White
    Write-Host "  2. Manually run: .\wireless-connect.ps1" -ForegroundColor White
    Write-Host "  3. Continue with USB connection (press Enter)" -ForegroundColor White
    Write-Host "`nPress Enter to continue with USB, or Ctrl+C to cancel..." -ForegroundColor Yellow
    Read-Host
} else {
    Write-Host "✗ ERROR: No devices connected!" -ForegroundColor Red
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Connect device via USB: .\wireless-connect.ps1" -ForegroundColor White
    Write-Host "  2. Check status: .\wireless-status.ps1" -ForegroundColor White
    Write-Host "  3. Ensure device is on same WiFi network" -ForegroundColor White
    exit 1
}

# Validate mode
$validModes = @("debug", "profile", "release")
if ($Mode -notin $validModes) {
    Write-Host "✗ Invalid mode: $Mode" -ForegroundColor Red
    Write-Host "Valid modes: debug, profile, release" -ForegroundColor Yellow
    exit 1
}

# Load environment for release builds
if ($Mode -eq "release") {
    Write-Host "`n🔐 Loading release build credentials..." -ForegroundColor Cyan
    
    if (Test-Path "$PSScriptRoot\load_env.ps1") {
        Write-Host "Loading environment variables from .env..." -ForegroundColor Gray
        & "$PSScriptRoot\load_env.ps1"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️  Warning: Failed to load environment variables" -ForegroundColor Yellow
            Write-Host "Release build may fail if keystore credentials are not set" -ForegroundColor Yellow
            Write-Host "`nPress Enter to continue anyway, or Ctrl+C to cancel..." -ForegroundColor Yellow
            Read-Host
        }
    } else {
        Write-Host "⚠️  Warning: load_env.ps1 not found" -ForegroundColor Yellow
        Write-Host "Ensure keystore environment variables are set for release builds" -ForegroundColor Yellow
    }
}

# Run Flutter
Write-Host "`n▶️  Launching Flutter in $Mode mode..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$flutterArgs = @("run")

switch ($Mode) {
    "debug" { 
        # Debug is the default, no extra flags needed
    }
    "profile" { 
        $flutterArgs += "--profile"
    }
    "release" { 
        $flutterArgs += "--release"
    }
}

# Execute Flutter
try {
    & flutter @flutterArgs
} catch {
    Write-Host "`n✗ Flutter run failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✅ Flutter session ended" -ForegroundColor Green
