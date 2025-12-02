@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 1. Disable WinRE (The Engine)
reagentc /disable >nul 2>&1

:: 2. BCD Hardening (Boot Configuration)
:: Disable recovery in bootloader
bcdedit /set {current} recoveryenabled No >nul 2>&1
bcdedit /set {default} recoveryenabled No >nul 2>&1
:: Prevent auto-triggering recovery on boot failures
bcdedit /set {current} bootstatuspolicy IgnoreAllFailures >nul 2>&1

:: 3. IFEO Blocking (The Executable)
:: Redirect systemreset.exe to a dummy command so it cannot run
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo SYSTEM RESET BLOCKED BY ADMINISTRATOR & pause" /f >nul 2>&1

:: 4. UI Hiding (The Settings App)
:: Hide Recovery and Backup pages in Settings
:: Note: We remove NoControlPanel to allow Settings app access
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /t REG_SZ /d "hide:recovery;backup" /f >nul 2>&1

:: Force restart Windows Explorer to apply changes
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe
