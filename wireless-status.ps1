# Wireless ADB Status Check Script
# Displays connection status and diagnostic information

param(
    [switch]$Help,
    [switch]$Detailed
)

if ($Help) {
    Write-Host @"
Wireless ADB Status Check Script
==================================

Usage: .\wireless-status.ps1 [-Detailed]

Options:
  -Detailed    Show detailed diagnostic information
  -Help        Show this help message

What this script checks:
1. ADB installation and version
2. ADB server status
3. Connected devices (USB and wireless)
4. Network connectivity
5. Device IP address
6. Connection quality

"@ -ForegroundColor Cyan
    exit 0
}

Write-Host "`n📊 Wireless ADB Status Check" -ForegroundColor Cyan
Write-Host "============================`n" -ForegroundColor Cyan

# Locate ADB
Write-Host "🔍 Checking ADB installation..." -ForegroundColor Cyan
$adbPath = "C:\Users\premprashant\AppData\Local\Android\sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    $androidHome = $env:ANDROID_HOME
    if ($androidHome) {
        $adbPath = Join-Path $androidHome "platform-tools\adb.exe"
    }
}

if (-not (Test-Path $adbPath)) {
    Write-Host "✗ ADB not found!" -ForegroundColor Red
    Write-Host "Expected location: C:\Users\premprashant\AppData\Local\Android\sdk\platform-tools\adb.exe" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ ADB found: $adbPath" -ForegroundColor Green

if ($Detailed) {
    $version = & $adbPath --version
    Write-Host "  Version: $($version[0])" -ForegroundColor Gray
}

# Check ADB server
Write-Host "`n🖥️  Checking ADB server..." -ForegroundColor Cyan
try {
    $serverCheck = & $adbPath start-server 2>&1
    Write-Host "✓ ADB server is running" -ForegroundColor Green
} catch {
    Write-Host "✗ ADB server error!" -ForegroundColor Red
}

# Check connected devices
Write-Host "`n📱 Connected devices:" -ForegroundColor Cyan
$devicesOutput = & $adbPath devices
$devices = $devicesOutput | Select-String "device$|offline$|unauthorized$"

if ($devices.Count -eq 0) {
    Write-Host "  ⚠️  No devices connected" -ForegroundColor Yellow
    Write-Host "`n  To connect wirelessly:" -ForegroundColor Cyan
    Write-Host "  1. Connect phone via USB cable" -ForegroundColor White
    Write-Host "  2. Run: .\wireless-connect.ps1" -ForegroundColor White
} else {
    $usbCount = 0
    $wirelessCount = 0
    $offlineCount = 0
    $unauthorizedCount = 0
    
    foreach ($device in $devices) {
        $deviceLine = $device.Line
        
        if ($deviceLine -match "unauthorized") {
            $unauthorizedCount++
            Write-Host "  ⚠️  $deviceLine" -ForegroundColor Yellow
        } elseif ($deviceLine -match "offline") {
            $offlineCount++
            Write-Host "  ⚠️  $deviceLine" -ForegroundColor Yellow
        } elseif ($deviceLine -match "\d+\.\d+\.\d+\.\d+:\d+") {
            $wirelessCount++
            Write-Host "  📡 $deviceLine" -ForegroundColor Green
        } else {
            $usbCount++
            Write-Host "  🔌 $deviceLine" -ForegroundColor Green
        }
    }
    
    Write-Host "`n  Summary:" -ForegroundColor Cyan
    Write-Host "    USB devices: $usbCount" -ForegroundColor White
    Write-Host "    Wireless devices: $wirelessCount" -ForegroundColor White
    if ($offlineCount -gt 0) {
        Write-Host "    Offline devices: $offlineCount" -ForegroundColor Yellow
    }
    if ($unauthorizedCount -gt 0) {
        Write-Host "    Unauthorized devices: $unauthorizedCount" -ForegroundColor Yellow
        Write-Host "`n  ⚠️  Unlock your phone and accept USB debugging prompt" -ForegroundColor Yellow
    }
}

# Check for wireless connections specifically
$wirelessDevices = $devicesOutput | Select-String -Pattern "(\d+\.\d+\.\d+\.\d+:\d+)\s+device" | ForEach-Object { $_.Matches.Groups[1].Value }

if ($wirelessDevices.Count -gt 0) {
    Write-Host "`n🌐 Wireless connection details:" -ForegroundColor Cyan
    foreach ($device in $wirelessDevices) {
        Write-Host "  Device: $device" -ForegroundColor Green
        
        if ($Detailed) {
            # Test connection speed
            Write-Host "  Testing connection..." -ForegroundColor Gray
            $testStart = Get-Date
            $pingTest = & $adbPath -s $device shell echo "ping" 2>&1
            $testEnd = Get-Date
            $latency = ($testEnd - $testStart).TotalMilliseconds
            
            if ($latency -lt 100) {
                Write-Host "  ✓ Latency: ${latency}ms (Excellent)" -ForegroundColor Green
            } elseif ($latency -lt 300) {
                Write-Host "  ⚠️  Latency: ${latency}ms (Good)" -ForegroundColor Yellow
            } else {
                Write-Host "  ⚠️  Latency: ${latency}ms (Slow - check WiFi)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "`n✅ Wireless debugging is ACTIVE" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "`nYou can now:" -ForegroundColor Cyan
    Write-Host "  • Run: flutter run" -ForegroundColor White
    Write-Host "  • Run: flutter run --wireless" -ForegroundColor White
    Write-Host "  • Run: .\flutter-wireless.ps1" -ForegroundColor White
    Write-Host "  • Disconnect: .\wireless-disconnect.ps1" -ForegroundColor White
} else {
    Write-Host "`n⚠️  No wireless connections active" -ForegroundColor Yellow
    Write-Host "`nTo set up wireless debugging:" -ForegroundColor Cyan
    Write-Host "  1. Connect device via USB cable" -ForegroundColor White
    Write-Host "  2. Run: .\wireless-connect.ps1" -ForegroundColor White
}

# Network diagnostics
if ($Detailed) {
    Write-Host "`n🌐 Network diagnostics:" -ForegroundColor Cyan
    
    # Get PC's WiFi IP
    $pcIP = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -match "^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\." } | Select-Object -First 1
    
    if ($pcIP) {
        Write-Host "  PC WiFi IP: $($pcIP.IPAddress)" -ForegroundColor White
    }
    
    # Check firewall
    Write-Host "  Firewall: Check Windows Defender settings if connection fails" -ForegroundColor Gray
}

Write-Host ""
