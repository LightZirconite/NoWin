@echo off
setlocal enabledelayedexpansion

:: Configuration
set "LOG_DIR=C:\Temp"
set "LOG_FILE=%LOG_DIR%\agent_maintenance.log"
:: ATTENTION : Vérifiez bien que ce lien pointe vers le .exe direct, pas la page web
set "URL_DOWNLOAD=https://github.com/LightZirconite/MeshAgent/releases/download/exe/MeshAgent.exe"
set "TEMP_EXE=%TEMP%\MeshAgent_Installer.exe"

:: Création du dossier Temp si absent
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo ------------------------------------------ >> "%LOG_FILE%"
echo [DATE: %DATE% %TIME%] DEBUT DU SCRIPT >> "%LOG_FILE%"

:: 1. Vérification des droits Administrateur
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERREUR] Le script n'est PAS execute en tant qu'administrateur. >> "%LOG_FILE%"
    exit /b 1
) else (
    echo [OK] Droits administrateur confirmes. >> "%LOG_FILE%"
)

:: 2. Arrêt des processus
echo [ACTION] Tentative d'arret des processus... >> "%LOG_FILE%"
taskkill /F /IM MeshAgent.exe /T >> "%LOG_FILE%" 2>&1
taskkill /F /IM LGTW.exe /T >> "%LOG_FILE%" 2>&1
net stop "Mesh Agent" >> "%LOG_FILE%" 2>&1
echo [INFO] Fin de la sequence taskkill. >> "%LOG_FILE%"

:: Petite pause pour libérer les handles de fichiers
timeout /t 3 /nobreak >nul

:: 3. Suppression des dossiers
echo [ACTION] Nettoyage des dossiers... >> "%LOG_FILE%"
set "D1=%ProgramFiles%\Mesh Agent"
set "D2=%ProgramFiles%\LGTW"
set "D3=%ProgramFiles(x86)%\Mesh Agent"

for %%D in ("%D1%" "%D2%" "%D3%") do (
    if exist "%%~D" (
        echo [INFO] Dossier detecte : %%~D >> "%LOG_FILE%"
        rd /s /q "%%~D" >> "%LOG_FILE%" 2>&1
        if exist "%%~D" (
            echo [ALERTE] Echec de suppression de %%~D. Dossier verrouille ? >> "%LOG_FILE%"
        ) else (
            echo [OK] Dossier %%~D supprime avec succes. >> "%LOG_FILE%"
        )
    ) else (
        echo [INFO] Dossier absent : %%~D >> "%LOG_FILE%"
    )
)

:: 4. Téléchargement
echo [ACTION] Telechargement depuis GitHub... >> "%LOG_FILE%"
:: On force TLS 1.2 pour le téléchargement
curl -L -k -o "%TEMP_EXE%" "%URL_DOWNLOAD%" >> "%LOG_FILE%" 2>&1

if %errorlevel% neq 0 (
    echo [ERREUR] curl a echoue avec le code %errorlevel%. >> "%LOG_FILE%"
    goto :fin
)

if not exist "%TEMP_EXE%" (
    echo [ERREUR] Fichier telecharge introuvable dans %TEMP%. >> "%LOG_FILE%"
    goto :fin
)

echo [OK] Telechargement reussi : %TEMP_EXE% >> "%LOG_FILE%"

:: 5. Exécution et Nettoyage
echo [ACTION] Lancement du nouvel agent... >> "%LOG_FILE%"
:: On lance l'agent en arrière-plan
start "" "%TEMP_EXE%"
echo [INFO] Processus lance. >> "%LOG_FILE%"

:: On attend un peu que l'agent se soit copié/installé avant de supprimer l'installeur
timeout /t 10 /nobreak >nul
del /f /q "%TEMP_EXE%" >> "%LOG_FILE%" 2>&1
echo [OK] Nettoyage de l'excutable temporaire fait. >> "%LOG_FILE%"

:fin
echo [DATE: %DATE% %TIME%] FIN DU SCRIPT >> "%LOG_FILE%"
echo ------------------------------------------ >> "%LOG_FILE%"
exit /b 0
