# Script to wrap all debug logs with kDebugMode checks
$ErrorActionPreference = 'Stop'

function Wrap-DeveloperLog {
    param([string]$filePath)
    
    $content = Get-Content $filePath -Raw
    $hasFoundation = $content -match 'import ''package:flutter/foundation\.dart'''
    
    # Add import if needed
    if (-not $hasFoundation) {
        $content = $content -replace '(import ''dart:developer'' as developer;)', "`$1`nimport 'package:flutter/foundation.dart';"
    }
    
    # Wrap developer.log calls - match indentation
    $content = $content -replace '(\s+)(developer\.log\([^\)]+\);)', "`$1if (kDebugMode) {`n`$1  `$2`n`$1}"
    
    Set-Content -Path $filePath -Value $content -NoNewline
}

# Process files
$files = @(
    'lib\services\auth_service.dart',
    'lib\services\migration_service.dart',
    'lib\services\qr_scanner_service.dart',
    'lib\view_models\otp_view_model.dart'
)

foreach ($file in $files) {
    $fullPath = "C:\Users\premprashant\Desktop\authvault_poc\$file"
    Write-Host "Processing $file..."
    Wrap-DeveloperLog -filePath $fullPath
}

Write-Host "Done! All developer.log calls wrapped with kDebugMode checks."
