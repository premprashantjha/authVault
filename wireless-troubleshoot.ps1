# Wireless Troubleshooting Script
# Comprehensive diagnostics for wireless ADB connection issues

param(
    [switch]$Help,
    [switch]$FixCommon
)

if ($Help) {
    Write-Host @"
Wireless ADB Troubleshooting Script
=====================================

Usage: .\wireless-troubleshoot.ps1 [-FixCommon]

Options:
  -FixCommon    Automatically attempt to fix common issues
  -Help         Show this help message

This script diagnoses:
1. ADB installation and configuration
2. Device connection status
3. Network connectivity
4. Firewall issues
5. Port conflicts
6. WiFi network compatibility

"@ -ForegroundColor Cyan
    exit 0
}

Write-Host "`n🔧 Wireless ADB Troubleshooting" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

$issues = @()
$warnings = @()

# Test 1: ADB Installation
Write-Host "Test 1/8: ADB Installation" -ForegroundColor Cyan
$adbPath = "C:\Users\premprashant\AppData\Local\Android\sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    $androidHome = $env:ANDROID_HOME
    if ($androidHome) {
        $adbPath = Join-Path $androidHome "platform-tools\adb.exe"
    }
}

if (Test-Path $adbPath) {
    Write-Host "  ✓ ADB found at: $adbPath" -ForegroundColor Green
} else {
    Write-Host "  ✗ ADB not found!" -ForegroundColor Red
    $issues += "ADB is not installed or not in expected location"
}

# Test 2: ADB Server
Write-Host "`nTest 2/8: ADB Server Status" -ForegroundColor Cyan
if (Test-Path $adbPath) {
    try {
        $serverStart = & $adbPath start-server 2>&1
        Write-Host "  ✓ ADB server is running" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ ADB server failed to start" -ForegroundColor Red
        $issues += "ADB server cannot start - may be blocked or corrupted"
        
        if ($FixCommon) {
            Write-Host "  Attempting to fix..." -ForegroundColor Yellow
            & $adbPath kill-server 2>&1 | Out-Null
            Start-Sleep -Seconds 1
            & $adbPath start-server 2>&1 | Out-Null
            Write-Host "  ✓ ADB server restarted" -ForegroundColor Green
        }
    }
}

# Test 3: Device Detection
Write-Host "`nTest 3/8: Device Detection" -ForegroundColor Cyan
if (Test-Path $adbPath) {
    $devicesOutput = & $adbPath devices
    $allDevices = $devicesOutput | Select-String "device$|offline$|unauthorized$"
    $wirelessDevices = $devicesOutput | Select-String -Pattern "\d+\.\d+\.\d+\.\d+:\d+" 
    $usbDevices = $allDevices | Where-Object { $_.Line -notmatch "\d+\.\d+\.\d+\.\d+" }
    
    if ($allDevices.Count -eq 0) {
        Write-Host "  ✗ No devices detected" -ForegroundColor Red
        $issues += "No devices connected via USB or wireless"
    } else {
        if ($usbDevices.Count -gt 0) {
            Write-Host "  ✓ USB devices: $($usbDevices.Count)" -ForegroundColor Green
        }
        if ($wirelessDevices.Count -gt 0) {
            Write-Host "  ✓ Wireless devices: $($wirelessDevices.Count)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  No wireless devices (USB only)" -ForegroundColor Yellow
            $warnings += "Device not connected wirelessly - run .\wireless-connect.ps1"
        }
    }
    
    # Check for unauthorized devices
    $unauthorized = $devicesOutput | Select-String "unauthorized"
    if ($unauthorized.Count -gt 0) {
        Write-Host "  ⚠️  Unauthorized devices detected" -ForegroundColor Yellow
        $warnings += "Unlock phone and accept USB debugging prompt"
    }
}

# Test 4: PC Network Configuration
Write-Host "`nTest 4/8: PC Network Configuration" -ForegroundColor Cyan
$wifiAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -match "Wi-Fi|Wireless|WLAN" }

if ($wifiAdapters.Count -gt 0) {
    Write-Host "  ✓ WiFi adapter active: $($wifiAdapters[0].Name)" -ForegroundColor Green
    
    $ipConfig = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $wifiAdapters[0].ifIndex
    if ($ipConfig) {
        Write-Host "  ✓ PC IP: $($ipConfig.IPAddress)" -ForegroundColor Green
        
        # Check if IP is in private range
        if ($ipConfig.IPAddress -match "^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.") {
            Write-Host "  ✓ Private network IP (suitable for wireless debugging)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Public IP detected" -ForegroundColor Yellow
            $warnings += "Unusual network configuration - ensure phone is on same network"
        }
    }
} else {
    Write-Host "  ✗ No active WiFi adapter found" -ForegroundColor Red
    $issues += "WiFi is not connected - both PC and phone must be on same WiFi"
}

# Test 5: Port Availability
Write-Host "`nTest 5/8: Port 5555 Availability" -ForegroundColor Cyan
$portInUse = Get-NetTCPConnection -LocalPort 5555 -ErrorAction SilentlyContinue

if ($portInUse) {
    Write-Host "  ⚠️  Port 5555 is in use" -ForegroundColor Yellow
    $warnings += "Port 5555 already in use - may conflict with wireless ADB"
    
    foreach ($conn in $portInUse) {
        $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        if ($process) {
            Write-Host "    Process: $($process.Name) (PID: $($process.Id))" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  ✓ Port 5555 is available" -ForegroundColor Green
}

# Test 6: Firewall Rules
Write-Host "`nTest 6/8: Windows Firewall" -ForegroundColor Cyan
try {
    $firewallProfile = Get-NetFirewallProfile -Profile Domain,Public,Private
    $blockInbound = $firewallProfile | Where-Object { $_.DefaultInboundAction -eq "Block" }
    
    if ($blockInbound.Count -gt 0) {
        Write-Host "  ⚠️  Firewall is blocking inbound connections" -ForegroundColor Yellow
        $warnings += "Windows Firewall may block wireless ADB - add exception if needed"
    } else {
        Write-Host "  ✓ Firewall allows inbound connections" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Cannot check firewall status" -ForegroundColor Yellow
}

# Test 7: Flutter Installation
Write-Host "`nTest 7/8: Flutter Installation" -ForegroundColor Cyan
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue

if ($flutterPath) {
    Write-Host "  ✓ Flutter is installed" -ForegroundColor Green
    $flutterVersion = & flutter --version 2>&1 | Select-String "Flutter"
    Write-Host "    $flutterVersion" -ForegroundColor Gray
} else {
    Write-Host "  ✗ Flutter not found in PATH" -ForegroundColor Red
    $issues += "Flutter SDK is not installed or not in PATH"
}

# Test 8: Previous Connection
Write-Host "`nTest 8/8: Previous Wireless Connections" -ForegroundColor Cyan
if (Test-Path $adbPath) {
    $devicesOutput = & $adbPath devices
    $wirelessHistory = $devicesOutput | Select-String -Pattern "(\d+\.\d+\.\d+\.\d+:\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    
    if ($wirelessHistory.Count -gt 0) {
        Write-Host "  ℹ️  Found previous wireless connection(s):" -ForegroundColor Cyan
        foreach ($device in $wirelessHistory) {
            Write-Host "    • $device" -ForegroundColor White
            
            # Test if still reachable
            $testPing = Test-Connection -ComputerName ($device -split ":")[0] -Count 1 -Quiet -ErrorAction SilentlyContinue
            if ($testPing) {
                Write-Host "      ✓ Device is reachable on network" -ForegroundColor Green
            } else {
                Write-Host "      ✗ Device not reachable (may have changed IP)" -ForegroundColor Red
                $warnings += "Previous device IP is no longer reachable"
            }
        }
    } else {
        Write-Host "  ℹ️  No previous wireless connections" -ForegroundColor Cyan
    }
}

# Summary
Write-Host "`n" -NoNewline
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📋 Diagnostic Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "`n✅ All checks passed!" -ForegroundColor Green
    Write-Host "Your system is ready for wireless debugging." -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Connect device via USB" -ForegroundColor White
    Write-Host "  2. Run: .\wireless-connect.ps1" -ForegroundColor White
} else {
    if ($issues.Count -gt 0) {
        Write-Host "`n❌ Critical Issues Found: $($issues.Count)" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "  • $issue" -ForegroundColor Red
        }
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "`n⚠️  Warnings: $($warnings.Count)" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  • $warning" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n📚 Recommended Actions:" -ForegroundColor Cyan
    
    if ($issues -match "ADB") {
        Write-Host "  1. Install Android SDK platform-tools" -ForegroundColor White
        Write-Host "     https://developer.android.com/studio/releases/platform-tools" -ForegroundColor Gray
    }
    
    if ($issues -match "WiFi" -or $warnings -match "network") {
        Write-Host "  2. Ensure PC and phone are on the SAME WiFi network" -ForegroundColor White
        Write-Host "     • Check WiFi settings on both devices" -ForegroundColor Gray
        Write-Host "     • Disable VPN temporarily" -ForegroundColor Gray
    }
    
    if ($issues -match "No devices") {
        Write-Host "  3. Connect your Android device" -ForegroundColor White
        Write-Host "     • USB cable for initial setup" -ForegroundColor Gray
        Write-Host "     • Enable USB debugging in Developer Options" -ForegroundColor Gray
    }
    
    if ($warnings -match "Firewall") {
        Write-Host "  4. Add Windows Firewall exception" -ForegroundColor White
        Write-Host "     • Windows Security → Firewall → Allow an app" -ForegroundColor Gray
        Write-Host "     • Add: $adbPath" -ForegroundColor Gray
    }
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
