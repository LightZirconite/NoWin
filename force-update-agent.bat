@echo off
setlocal EnableExtensions

:: =======================================================
:: AUTO-ELEVATION ADMIN AU DEMARRAGE
:: =======================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command ^
    "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Minimized"
    exit /b
)

:: =======================================================
:: CONFIGURATION
:: =======================================================

set "NEW_AGENT_URL=https://github.com/LightZirconite/MeshAgent/releases/download/exe/LGTW-Agent64-Lol.exe"
set "TEMP_DIR=%TEMP%"
set "INSTALLER_NAME=LGTW-Update.exe"
set "UPDATER_SCRIPT=updater_process.bat"
set "SERVICE_NAME=LGTWAgent"

:: =======================================================
:: TELECHARGEMENT
:: =======================================================

echo [1/4] Telechargement du nouvel agent...
powershell -NoProfile -WindowStyle Minimized -Command ^
"[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri '%NEW_AGENT_URL%' -OutFile '%TEMP_DIR%\%INSTALLER_NAME%'"

if not exist "%TEMP_DIR%\%INSTALLER_NAME%" (
    echo [ERREUR CRITIQUE] Telechargement echoue.
    pause
    exit /b 1
)

echo [SUCCES] Fichier telecharge.

:: =======================================================
:: CREATION DU SCRIPT DETACHE
:: =======================================================

echo [2/4] Creation du script de mise a jour...

(
echo @echo off
echo timeout /t 5 /nobreak ^> nul
echo echo [KILL] Arret du service %SERVICE_NAME%...
echo net stop "%SERVICE_NAME%" ^> nul 2^>^&1
echo net stop "MeshAgent" ^> nul 2^>^&1
echo taskkill /F /IM MeshAgent.exe ^> nul 2^>^&1
echo taskkill /F /IM LGTW-Agent64-Lol.exe ^> nul 2^>^&1
echo timeout /t 3 /nobreak ^> nul
echo.
echo echo [CLEAN] Suppression des anciens fichiers...
echo if exist "C:\Program Files\Mesh Agent" rmdir /S /Q "C:\Program Files\Mesh Agent"
echo if exist "C:\Program Files (x86)\Mesh Agent" rmdir /S /Q "C:\Program Files (x86)\Mesh Agent"
echo if exist "C:\Program Files\MeshAgent" rmdir /S /Q "C:\Program Files\MeshAgent"
echo if exist "C:\Program Files (x86)\MeshAgent" rmdir /S /Q "C:\Program Files (x86)\MeshAgent"
echo.
echo echo [INSTALL] Installation du nouvel agent...
echo powershell -NoProfile -WindowStyle Minimized -Command "Start-Process -FilePath \"%%TEMP_DIR%%\%%INSTALLER_NAME%%\" -ArgumentList \"-fullinstall\" -Wait"
echo.
echo echo [FIN] Nettoyage...
echo del "%%TEMP_DIR%%\%%INSTALLER_NAME%%"
echo del "%%TEMP_DIR%%\%%UPDATER_SCRIPT%%"
echo exit /b 0
) > "%TEMP_DIR%\%UPDATER_SCRIPT%"

:: =======================================================
:: EXECUTION (MINIMISE)
:: =======================================================

echo [3/4] Lancement de la procedure...
start "" /min "%TEMP_DIR%\%UPDATER_SCRIPT%"

:: =======================================================
:: AUTO-CLEANUP: Supprimer ce script
:: =======================================================

echo [4/4] Auto-suppression...
:: Create a separate script to delete this one after it exits
set "CLEANUP_SCRIPT=%TEMP%\cleanup_nowin.bat"
(
echo @echo off
echo timeout /t 2 /nobreak ^> nul
echo del /f /q "%~f0"
echo del /f /q "%%~f0"
) > "%CLEANUP_SCRIPT%"
start "" /min "%CLEANUP_SCRIPT%"

exit /b 0
