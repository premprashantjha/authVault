# Release Build Script for AuthVault
# This script helps you build release APKs with proper keystore signing

Write-Host "=== Authenticator Release Build ===" -ForegroundColor Cyan
Write-Host ""

# Load non-sensitive config from .env
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^AUTHENTICATOR_') {
            $parts = $_ -split '=', 2
            if ($parts.Length -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim()
                Set-Item -Path "env:$key" -Value $value
            }
        }
    }
    Write-Host "[OK] Loaded configuration from .env" -ForegroundColor Green
}

# Check if keystore exists
$keystorePath = "android\app\release.keystore"
if (-not (Test-Path $keystorePath)) {
    Write-Host "[ERROR] Keystore not found at: $keystorePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "First time? Generate a keystore:" -ForegroundColor Yellow
    Write-Host "  cd android\app" -ForegroundColor White
    Write-Host "  keytool -genkey -v -keystore release.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias release" -ForegroundColor White
    exit 1
}

Write-Host "[OK] Keystore found" -ForegroundColor Green

# Prompt for passwords if not set
if (-not $env:AUTHENTICATOR_KEYSTORE_PASSWORD) {
    $securePassword = Read-Host "Enter keystore password" -AsSecureString
    $env:AUTHENTICATOR_KEYSTORE_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    )
}

if (-not $env:AUTHENTICATOR_KEY_PASSWORD) {
    $securePassword = Read-Host "Enter key password" -AsSecureString
    $env:AUTHENTICATOR_KEY_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    )
}

Write-Host "[OK] Passwords set" -ForegroundColor Green
Write-Host ""
Write-Host "Building release APK..." -ForegroundColor Cyan

# Build
flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Build Successful! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "APK Location:" -ForegroundColor Cyan
    Write-Host "  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
    Write-Host ""
    
    # Show APK size
    $apk = Get-Item "build\app\outputs\flutter-apk\app-release.apk" -ErrorAction SilentlyContinue
    if ($apk) {
        $sizeMB = [math]::Round($apk.Length / 1MB, 2)
        Write-Host "APK Size: $sizeMB MB" -ForegroundColor Cyan
    }
} else {
    Write-Host ""
    Write-Host "=== Build Failed ===" -ForegroundColor Red
    exit 1
}
