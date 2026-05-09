@echo off
setlocal

rem Simple launcher: ensure elevated, then run the PS1 in the same folder
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "PS1=%~dp0setup-ssh-universal_v4.ps1"
if not exist "%PS1%" (
    echo [ERROR] PowerShell script not found: %PS1%
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*

CScript %~dp0config-vbs-universal.vbs %*
set "RC=%ERRORLEVEL%"

endlocal
exit /b %RC%