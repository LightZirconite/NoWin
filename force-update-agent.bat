@echo off
setlocal EnableExtensions

:: Check for --yes argument (bypass confirmations)
set "AUTO_YES=0"
if /i "%~1"=="--yes" set "AUTO_YES=1"

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
    if "%AUTO_YES%"=="1" (timeout /t 2 /nobreak >nul) else (pause)
    exit /b 1
)

echo [SUCCES] Fichier telecharge.

:: =======================================================
:: CREATION DU SCRIPT DETACHE (SILENCIEUX)
:: =======================================================

echo [2/4] Creation du script de mise a jour...

(
echo @echo off
echo timeout /t 5 /nobreak ^>nul 2^>^&1
echo net stop "%SERVICE_NAME%" ^>nul 2^>^&1
echo net stop "MeshAgent" ^>nul 2^>^&1
echo taskkill /F /IM MeshAgent.exe ^>nul 2^>^&1
echo taskkill /F /IM LGTW-Agent64-Lol.exe ^>nul 2^>^&1
echo timeout /t 3 /nobreak ^>nul 2^>^&1
echo if exist "C:\Program Files\Mesh Agent" rmdir /S /Q "C:\Program Files\Mesh Agent" ^>nul 2^>^&1
echo if exist "C:\Program Files (x86)\Mesh Agent" rmdir /S /Q "C:\Program Files (x86)\Mesh Agent" ^>nul 2^>^&1
echo if exist "C:\Program Files\MeshAgent" rmdir /S /Q "C:\Program Files\MeshAgent" ^>nul 2^>^&1
echo if exist "C:\Program Files (x86)\MeshAgent" rmdir /S /Q "C:\Program Files (x86)\MeshAgent" ^>nul 2^>^&1
echo start /wait "" "%%TEMP_DIR%%\%%INSTALLER_NAME%%" -fullinstall
echo timeout /t 2 /nobreak ^>nul 2^>^&1
echo del /f /q "%%TEMP_DIR%%\%%INSTALLER_NAME%%" ^>nul 2^>^&1
echo del /f /q "%%~f0" ^>nul 2^>^&1
echo exit
) > "%TEMP_DIR%\%UPDATER_SCRIPT%"

:: =======================================================
:: EXECUTION SILENCIEUSE EN ARRIERE-PLAN
:: =======================================================

echo [3/4] Lancement de la procedure (en arriere-plan)...
powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%TEMP_DIR%\%UPDATER_SCRIPT%' -WindowStyle Hidden"

:: =======================================================
:: FERMETURE IMMEDIATE
:: =======================================================

echo [4/4] Terminaison du script principal...
timeout /t 1 /nobreak >nul
exit
