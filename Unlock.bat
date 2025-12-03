@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 1. Enable WinRE
reagentc /enable >nul 2>&1

:: 2. Revert BCD
bcdedit /set {current} recoveryenabled Yes >nul 2>&1
bcdedit /set {default} recoveryenabled Yes >nul 2>&1
bcdedit /set {current} bootstatuspolicy DisplayAllFailures >nul 2>&1

:: 3. Remove IFEO Block
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\rstrui.exe" /f >nul 2>&1

:: 4. Re-enable System Restore
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /f >nul 2>&1

:: 5. Restore UI
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f >nul 2>&1

:: Force restart Windows Explorer to revert changes
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe
