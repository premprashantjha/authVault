# Wireless ADB Disconnect Script
# Disconnects wireless ADB and switches back to USB mode

param(
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Wireless ADB Disconnect Script
================================

Usage: .\wireless-disconnect.ps1

What this script does:
1. Disconnects all wireless ADB connections
2. Switches ADB back to USB mode
3. Cleans up ADB server state

After running this script:
- All wireless connections will be terminated
- ADB will be ready for USB connections
- You can reconnect wirelessly anytime with .\wireless-connect.ps1

"@ -ForegroundColor Cyan
    exit 0
}

Write-Host "`n🔌 Wireless ADB Disconnect" -ForegroundColor Cyan
Write-Host "==========================`n" -ForegroundColor Cyan

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

Write-Host "📱 Checking current connections..." -ForegroundColor Cyan
$currentDevices = & $adbPath devices

# Get list of wireless connections (IP:PORT format)
$wirelessDevices = $currentDevices | Select-String -Pattern "(\d+\.\d+\.\d+\.\d+:\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }

if ($wirelessDevices.Count -eq 0) {
    Write-Host "ℹ️  No wireless connections found" -ForegroundColor Yellow
    Write-Host "✓ Already in USB mode" -ForegroundColor Green
} else {
    Write-Host "Found $($wirelessDevices.Count) wireless connection(s):" -ForegroundColor Cyan
    foreach ($device in $wirelessDevices) {
        Write-Host "  • $device" -ForegroundColor White
    }
    
    Write-Host "`n🔓 Disconnecting wireless devices..." -ForegroundColor Cyan
    foreach ($device in $wirelessDevices) {
        & $adbPath disconnect $device | Out-Null
        Write-Host "✓ Disconnected: $device" -ForegroundColor Green
    }
}

Write-Host "`n🔄 Switching to USB mode..." -ForegroundColor Cyan
& $adbPath usb 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Switched to USB mode" -ForegroundColor Green
} else {
    Write-Host "ℹ️  USB mode command sent (may require device reconnection)" -ForegroundColor Yellow
}

Write-Host "`n🔄 Restarting ADB server..." -ForegroundColor Cyan
& $adbPath kill-server 2>&1 | Out-Null
Start-Sleep -Milliseconds 500
& $adbPath start-server 2>&1 | Out-Null
Write-Host "✓ ADB server restarted" -ForegroundColor Green

Write-Host "`n✅ Disconnection complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "`nTo use wireless debugging again:" -ForegroundColor Cyan
Write-Host "1. Connect device via USB cable" -ForegroundColor White
Write-Host "2. Run: .\wireless-connect.ps1" -ForegroundColor White
Write-Host ""
