$ADB = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $ADB)) {
    Write-Host 'adb not found – update the path in this script.' -ForegroundColor Red
    exit 1
}

$devices = & $ADB devices | Select-String "device$"
if (-not $devices) {
    Write-Host 'No Android device connected. Plug in your phone and enable USB debugging.' -ForegroundColor Yellow
    exit 1
}

Write-Host 'Setting up ADB port forwarding (8080 to PC)...' -ForegroundColor Cyan
& $ADB reverse tcp:8080 tcp:8080

Write-Host 'Launching Flutter on device...' -ForegroundColor Cyan
flutter run -d $(($devices[0] -split "\s+")[0])
