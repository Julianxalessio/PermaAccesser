@echo off
powershell -command "$p=Get-Process 'Discord' -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowHandle -ne 0}; if($p){$sig1='[DllImport(\"user32.dll\")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'; $sig2='[DllImport(\"user32.dll\")] public static extern bool SetForegroundWindow(IntPtr hWnd);'; Add-Type -MemberDefinition $sig1 -Name W1 -Namespace Win32; Add-Type -MemberDefinition $sig2 -Name W2 -Namespace Win32; [Win32.W1]::ShowWindowAsync($p.MainWindowHandle, 3) | Out-Null; [Win32.W2]::SetForegroundWindow($p.MainWindowHandle) | Out-Null; }"
powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $refWidth=1440; $refHeight=900; $refX=750; $refY=815; $screen=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $targetX = [math]::Round($refX * $screen.Width / $refWidth); $targetY = [math]::Round($refY * $screen.Height / $refHeight); Start-Sleep -Milliseconds 500; [System.Windows.Forms.SendKeys]::SendWait('^k'); Start-Sleep -Milliseconds 300; [System.Windows.Forms.SendKeys]::SendWait('Players'); Start-Sleep -Milliseconds 300; [System.Windows.Forms.SendKeys]::SendWait('{ENTER}'); Start-Sleep -Milliseconds 700; [System.Windows.Forms.Cursor]::Position = [System.Drawing.Point]::new($targetX,$targetY); Start-Sleep -Milliseconds 300; Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class MouseClick { [DllImport(\"user32.dll\")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, uint dwExtraInfo); }'; [MouseClick]::mouse_event(0x02,0,0,0,0); [MouseClick]::mouse_event(0x04,0,0,0,0)"

:: Add-Type -AssemblyName System.Windows.Forms
:: $pos = [System.Windows.Forms.Cursor]::Position
:: Write-Host "X:" $pos.X "Y:" $pos.Y


:: $refWidth=1440; $refHeight=900; $refX=776; $refY=812

:: Add-Type -AssemblyName System.Windows.Forms
:: $screen=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
:: echo $screen
