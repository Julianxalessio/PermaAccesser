#requires -RunAsAdministrator
param(
    [string]$KeyBasePath = "C:\ProgramData\ssh\test",
    [switch]$RemoveAllKeys = $false
)

$ErrorActionPreference = "Stop"

Write-Host "SSH Deinstallation starten..."
$choice = Read-Host "Fortfahren? (j/N)"
if ($choice -notmatch '^[jJ]$') { exit 0 }

# 1. Stoppe sshd Service
try {
    $sshd = Get-Service -Name sshd -ErrorAction SilentlyContinue
    if ($sshd) {
        Stop-Service sshd -Force -ErrorAction SilentlyContinue
        Set-Service -Name sshd -StartupType Disabled -ErrorAction SilentlyContinue
    }
}
catch { }

# 2. Entferne Firewall-Regel
try {
    Remove-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Force -ErrorAction SilentlyContinue
}
catch { }

# 3. Stelle sshd_config-Backup wieder her
try {
    $cfg = "C:\ProgramData\ssh\sshd_config"
    $backups = Get-ChildItem "$cfg.bak.*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($backups) {
        Copy-Item $backups[0].FullName $cfg -Force
    }
}
catch { }

# 4. Lösche lokal generierte SSH-Keys
try {
    Remove-Item $KeyBasePath -Force -ErrorAction SilentlyContinue
    Remove-Item "$KeyBasePath.pub" -Force -ErrorAction SilentlyContinue
    Get-ChildItem "$KeyBasePath.bak.*" -ErrorAction SilentlyContinue | Remove-Item -Force
}
catch { }

# 5. Optional: Lösche Keys aus Benutzerprofilen
if ($RemoveAllKeys) {
    try {
        $profiles = Get-CimInstance Win32_UserProfile | Where-Object {
            $_.LocalPath -like "C:\Users\*" -and $_.Special -eq $false
        }
        foreach ($profile in $profiles) {
            $sshDir = Join-Path $profile.LocalPath ".ssh"
            Remove-Item $sshDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch { }
}

Write-Host "Fertig."
