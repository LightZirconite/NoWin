@echo off
setlocal enabledelayedexpansion

:: Configuration des dossiers et fichiers
set "LOG_DIR=C:\Temp"
set "LOG_FILE=%LOG_DIR%\agent_maintenance.log"
set "URL_DOWNLOAD=https://github.com/LightZirconite/MeshAgent/releases/download/exe/MeshAgent.exe"
set "TEMP_EXE=%TEMP%\MeshAgent_Installer.exe"

:: Création du dossier Temp s'il n'existe pas
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo ======================================== >> "%LOG_FILE%"
echo [LOG %DATE% %TIME%] Lancement du script >> "%LOG_FILE%"

:: 1. Tentative d'arrêt des processus
echo [*] Arret des processus... | tee
taskkill /F /IM "MeshAgent.exe" /T >> "%LOG_FILE%" 2>&1
taskkill /F /IM "LGTW.exe" /T >> "%LOG_FILE%" 2>&1
net stop "Mesh Agent" >> "%LOG_FILE%" 2>&1

:: 2. Suppression des dossiers avec vérification
echo [*] Nettoyage des dossiers... | tee
set "DIRS_TO_CLEAN=%ProgramFiles%\Mesh Agent" "%ProgramFiles%\LGTW" "%ProgramFiles(x86)%\Mesh Agent"

for %%D in (%DIRS_TO_CLEAN%) do (
    if exist "%%~D" (
        echo [INFO] Tentative de suppression de : %%~D >> "%LOG_FILE%"
        rd /s /q "%%~D" >> "%LOG_FILE%" 2>&1
        if exist "%%~D" (
            echo [ERREUR] Impossible de supprimer %%~D. Le dossier est peut-etre utilise. >> "%LOG_FILE%"
        ) else (
            echo [SUCCESS] Dossier %%~D supprime. >> "%LOG_FILE%"
        )
    ) else (
        echo [INFO] Dossier non trouve (ignore) : %%~D >> "%LOG_FILE%"
    )
)

:: 3. Téléchargement
echo [*] Telechargement de l'agent... | tee
curl -L -o "%TEMP_EXE%" "%URL_DOWNLOAD%" >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec du telechargement via CURL. Code: %ERRORLEVEL% >> "%LOG_FILE%"
    goto :end
)

if not exist "%TEMP_EXE%" (
    echo [ERREUR] Le fichier telecharge est introuvable. >> "%LOG_FILE%"
    goto :end
)

:: 4. Installation / Exécution
echo [*] Lancement de l'agent... | tee
:: Note : J'ajoute start /wait pour s'assurer que l'exécution commence bien
start "" "%TEMP_EXE%" >> "%LOG_FILE%" 2>&1
echo [SUCCESS] Agent lance depuis %TEMP_EXE% >> "%LOG_FILE%"

:: 5. Nettoyage après une pause
timeout /t 10 /nobreak >nul
del /f /q "%TEMP_EXE%" >> "%LOG_FILE%" 2>&1
echo [INFO] Nettoyage du fichier temporaire effectue. >> "%LOG_FILE%"

:end
echo [LOG %DATE% %TIME%] Fin du script. >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"
exit /b 0
