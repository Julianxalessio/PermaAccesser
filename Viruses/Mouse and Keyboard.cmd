# 1. Windows API Funktion für Maus-Events definieren
$signature = '[DllImport("user32.dll")] public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);'
$type = Add-Type -MemberDefinition $signature -Name "Win32MouseRightClick" -Namespace Win32Functions -PassThru

# 2. Flags für Rechtsklick definieren
# MOUSEEVENTF_RIGHTDOWN = 0x0008
# MOUSEEVENTF_RIGHTUP   = 0x0010

# 3. Rechtsklick ausführen (Down und Up)
$type::mouse_event(0x0008, 0, 0, 0, 0)
$type::mouse_event(0x0010, 0, 0, 0, 0)

Write-Host "Rechtsklick an aktueller Cursor-Position ausgeführt." -ForegroundColor Green
