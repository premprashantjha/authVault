# Wireless ADB Connection Script
# Connects your Android device to ADB wirelessly for Flutter development

param(
    [string]$Port = "5555",
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Wireless ADB Connection Script
================================

Usage: .\wireless-connect.ps1 [-Port <port>]

Options:
  -Port     Port number for wireless connection (default: 5555)
  -Help     Show this help message

Prerequisites:
1. Connect your Android phone via USB cable FIRST
2. Ensure USB debugging is enabled on your phone
3. Both PC and phone must be on the SAME WiFi network
4. Make sure Developer Options > Wireless debugging is enabled

Steps this script performs:
1. Locates ADB from Android SDK
2. Restarts ADB server
3. Gets your phone's IP address
4. Enables TCP/IP mode on port $Port
5. Disconnects USB (you can then unplug the cable)
6. Connects wirelessly to your device
7. Verifies the wireless connection

After running this script successfully, you can:
- Unplug the USB cable
- Run 'flutter run' normally
- Use 'flutter run --wireless' for better stability
- Run '.\wireless-status.ps1' to check connection

"@ -ForegroundColor Cyan
    exit 0
}

# ANSI color codes for better output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

Write-Host "`n🔧 Wireless ADB Connection Setup" -ForegroundColor $InfoColor
Write-Host "================================`n" -ForegroundColor $InfoColor

# Step 1: Locate ADB
Write-Host "📍 Step 1: Locating ADB..." -ForegroundColor $InfoColor
$adbPath = "C:\Users\premprashant\AppData\Local\Android\sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    # Try alternative locations
    $androidHome = $env:ANDROID_HOME
    if ($androidHome) {
        $adbPath = Join-Path $androidHome "platform-tools\adb.exe"
    }
}

if (-not (Test-Path $adbPath)) {
    Write-Host "✗ ERROR: ADB not found!" -ForegroundColor $ErrorColor
    Write-Host "Expected location: C:\Users\premprashant\AppData\Local\Android\sdk\platform-tools\adb.exe" -ForegroundColor $WarningColor
    Write-Host "`nPlease install Android SDK platform-tools or set ANDROID_HOME environment variable." -ForegroundColor $WarningColor
    exit 1
}

Write-Host "✓ Found ADB at: $adbPath" -ForegroundColor $SuccessColor

# Step 2: Restart ADB server
Write-Host "`n🔄 Step 2: Restarting ADB server..." -ForegroundColor $InfoColor
& $adbPath kill-server 2>&1 | Out-Null
Start-Sleep -Milliseconds 500
& $adbPath start-server 2>&1 | Out-Null
Start-Sleep -Milliseconds 500
Write-Host "✓ ADB server restarted" -ForegroundColor $SuccessColor

# Step 3: Check for USB connected devices
Write-Host "`n📱 Step 3: Detecting USB connected devices..." -ForegroundColor $InfoColor
$devices = & $adbPath devices | Select-String "device$"

if ($devices.Count -eq 0) {
    Write-Host "✗ ERROR: No devices found connected via USB!" -ForegroundColor $ErrorColor
    Write-Host "`nTroubleshooting steps:" -ForegroundColor $WarningColor
    Write-Host "1. Connect your phone via USB cable" -ForegroundColor $WarningColor
    Write-Host "2. Enable USB debugging in Developer Options" -ForegroundColor $WarningColor
    Write-Host "3. Unlock your phone and accept the USB debugging prompt" -ForegroundColor $WarningColor
    Write-Host "4. Try running: .\wireless-status.ps1 to diagnose" -ForegroundColor $WarningColor
    exit 1
}

Write-Host "✓ Found $($devices.Count) device(s) connected via USB" -ForegroundColor $SuccessColor

# Step 4: Get device IP address
Write-Host "`n🌐 Step 4: Getting device IP address..." -ForegroundColor $InfoColor
$ipOutput = & $adbPath shell ip route | Select-String -Pattern "src (\d+\.\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }

if (-not $ipOutput) {
    # Try alternative method
    $ipOutput = & $adbPath shell ip addr show wlan0 | Select-String -Pattern "inet (\d+\.\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
}

if (-not $ipOutput) {
    Write-Host "✗ ERROR: Could not detect device IP address!" -ForegroundColor $ErrorColor
    Write-Host "`nPossible issues:" -ForegroundColor $WarningColor
    Write-Host "1. Device is not connected to WiFi" -ForegroundColor $WarningColor
    Write-Host "2. WiFi network doesn't allow device-to-device communication" -ForegroundColor $WarningColor
    Write-Host "3. Device is using VPN or mobile hotspot" -ForegroundColor $WarningColor
    Write-Host "`nPlease ensure your phone is connected to the SAME WiFi as your PC." -ForegroundColor $WarningColor
    exit 1
}

$deviceIP = $ipOutput | Select-Object -First 1
Write-Host "✓ Device IP: $deviceIP" -ForegroundColor $SuccessColor

# Step 5: Enable TCP/IP mode
Write-Host "`n🔌 Step 5: Enabling TCP/IP mode on port $Port..." -ForegroundColor $InfoColor
$tcpResult = & $adbPath tcpip $Port 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ ERROR: Failed to enable TCP/IP mode!" -ForegroundColor $ErrorColor
    Write-Host $tcpResult -ForegroundColor $WarningColor
    exit 1
}

Write-Host "✓ TCP/IP mode enabled on port $Port" -ForegroundColor $SuccessColor
Write-Host "  You can now UNPLUG the USB cable!" -ForegroundColor $WarningColor
Start-Sleep -Seconds 2

# Step 6: Connect wirelessly
Write-Host "`n📡 Step 6: Connecting wirelessly to ${deviceIP}:${Port}..." -ForegroundColor $InfoColor
Start-Sleep -Seconds 1

$connectResult = & $adbPath connect "${deviceIP}:${Port}" 2>&1

if ($connectResult -match "connected|already connected") {
    Write-Host "✓ Successfully connected wirelessly!" -ForegroundColor $SuccessColor
} else {
    Write-Host "✗ WARNING: Connection attempt returned unexpected response:" -ForegroundColor $WarningColor
    Write-Host $connectResult -ForegroundColor $WarningColor
}

# Step 7: Verify connection
Write-Host "`n✅ Step 7: Verifying wireless connection..." -ForegroundColor $InfoColor
Start-Sleep -Seconds 1

$verifyDevices = & $adbPath devices
Write-Host "`nConnected devices:" -ForegroundColor $InfoColor
Write-Host $verifyDevices

if ($verifyDevices -match $deviceIP) {
    Write-Host "`n🎉 SUCCESS! Wireless debugging is now active!" -ForegroundColor $SuccessColor
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $SuccessColor
    Write-Host "`nNext steps:" -ForegroundColor $InfoColor
    Write-Host "1. ✓ You can now UNPLUG the USB cable" -ForegroundColor $SuccessColor
    Write-Host "2. ✓ Run Flutter apps with: flutter run" -ForegroundColor $SuccessColor
    Write-Host "3. ✓ For better stability: flutter run --wireless" -ForegroundColor $SuccessColor
    Write-Host "4. ✓ Check connection: .\wireless-status.ps1" -ForegroundColor $SuccessColor
    Write-Host "5. ✓ Disconnect: .\wireless-disconnect.ps1" -ForegroundColor $SuccessColor
    Write-Host "`nDevice address: ${deviceIP}:${Port}" -ForegroundColor $InfoColor
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $SuccessColor
} else {
    Write-Host "`n⚠️  WARNING: Wireless connection may not be stable" -ForegroundColor $WarningColor
    Write-Host "`nTroubleshooting:" -ForegroundColor $InfoColor
    Write-Host "1. Wait 5 seconds and run: .\wireless-status.ps1" -ForegroundColor $WarningColor
    Write-Host "2. Check if phone and PC are on the same WiFi" -ForegroundColor $WarningColor
    Write-Host "3. Try reconnecting: .\wireless-connect.ps1" -ForegroundColor $WarningColor
    Write-Host "4. Check firewall settings on PC" -ForegroundColor $WarningColor
}

Write-Host ""
