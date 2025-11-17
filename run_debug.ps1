# Robust Flutter run script that handles APK detection issues
param(
    [string]$Device = "emulator-5554"
)

Write-Host "Building and running Flutter app..." -ForegroundColor Green

# Clean and build
flutter clean
flutter build apk --debug

# Check if APK was built
$apkPath = "build\app\outputs\apk\debug\app-debug.apk"
if (Test-Path $apkPath) {
    Write-Host "APK built successfully at $apkPath" -ForegroundColor Green
    
    # Install and run
    adb -s $Device install -r $apkPath
    adb -s $Device shell am start -n com.example.authenticator/.MainActivity
    
    # Attach Flutter debugger
    flutter attach -d $Device
} else {
    Write-Host "APK not found. Trying flutter run..." -ForegroundColor Yellow
    flutter run -d $Device
}