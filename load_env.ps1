# Load environment variables from .env file
# Usage: .\load_env.ps1 [-StorePasswords]
# -StorePasswords: Optional flag to store passwords in .env (less secure)

param(
    [switch]$StorePasswords
)

$envFile = Join-Path $PSScriptRoot ".env"

if (-not (Test-Path $envFile)) {
    Write-Host "Error: .env file not found" -ForegroundColor Red
    exit 1
}

Write-Host "Loading environment variables from .env..." -ForegroundColor Cyan

# Load non-sensitive variables from .env
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*?)\s*=\s*(.+?)\s*$') {
        $name = $matches[1]
        $value = $matches[2]
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
        Write-Host "Loaded: $name" -ForegroundColor Green
    }
}

Write-Host ""

# Prompt for passwords securely (not stored on disk)
if (-not $StorePasswords) {
    Write-Host "Enter keystore passwords (input hidden):" -ForegroundColor Yellow
    $keystorePass = Read-Host "Keystore Password" -AsSecureString
    $keyPass = Read-Host "Key Password" -AsSecureString
    
    # Convert SecureString to plain text for environment variables
    $BSTR1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($keystorePass)
    $BSTR2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPass)
    
    [Environment]::SetEnvironmentVariable("AUTHENTICATOR_KEYSTORE_PASSWORD", [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR1), "Process")
    [Environment]::SetEnvironmentVariable("AUTHENTICATOR_KEY_PASSWORD", [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2), "Process")
    
    # Clear sensitive data from memory
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR1)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR2)
    
    Write-Host "Passwords set (in memory only)" -ForegroundColor Green
} else {
    Write-Host "WARNING: Using -StorePasswords flag stores passwords in plain text!" -ForegroundColor Red
    # Load passwords from .env if they exist
    if ($env:AUTHENTICATOR_KEYSTORE_PASSWORD -and $env:AUTHENTICATOR_KEY_PASSWORD) {
        Write-Host "Passwords loaded from .env" -ForegroundColor Yellow
    } else {
        Write-Host "No passwords found in .env. You'll need to add them manually." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "All variables loaded!" -ForegroundColor Green
Write-Host "Ready to build: flutter build apk --release" -ForegroundColor Cyan
