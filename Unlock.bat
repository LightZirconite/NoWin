@echo off
:: Check for Administrator privileges silently
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Enable Windows Recovery Environment (WinRE)
reagentc /enable >nul 2>&1

:: Enable Control Panel by deleting the NoControlPanel value
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /f >nul 2>&1

:: Show the "Recovery" page in Settings again
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f >nul 2>&1

:: Force restart Windows Explorer to revert changes
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe
