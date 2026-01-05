@echo off
setlocal enabledelayedexpansion

:: Configuration des variables
set "URL_DOWNLOAD=https://github.com/LightZirconite/MeshAgent/releases/download/exe/MeshAgent.exe"
set "TEMP_EXE=%TEMP%\MeshAgent_Installer.exe"
set "LOG_PREFIX=[MAINTENANCE AGENT]"

echo %LOG_PREFIX% Demarrage du nettoyage...

:: 1. Tuer les processus actifs (MeshAgent, LGTW, etc.)
echo %LOG_PREFIX% Arret des processus et services...
taskkill /F /IM "MeshAgent.exe" /T >nul 2>&1
taskkill /F /IM "LGTW.exe" /T >nul 2>&1
net stop "Mesh Agent" >nul 2>&1

:: 2. Suppression des dossiers dans Program Files
echo %LOG_PREFIX% Nettoyage des dossiers d'installation...
set "DIRS_TO_CLEAN=%ProgramFiles%\Mesh Agent" "%ProgramFiles%\LGTW" "%ProgramFiles(x86)%\Mesh Agent"

for %%D in (%DIRS_TO_CLEAN%) do (
    if exist "%%~D" (
        echo Suppression de : %%~D
        rd /s /q "%%~D"
    )
)

:: 3. Petite pause pour laisser le système libérer les fichiers
timeout /t 2 /nobreak >nul

:: 4. Telechargement depuis GitHub
echo %LOG_PREFIX% Telechargement de la nouvelle version...
:: Utilisation de curl (inclus nativement dans Windows 10/11)
curl -L -o "%TEMP_EXE%" "%URL_DOWNLOAD%"

if not exist "%TEMP_EXE%" (
    echo [ERREUR] Impossible de telecharger le fichier. Verifiez le lien GitHub.
    pause
    exit /b 1
)

:: 5. Execution de l'agent
echo %LOG_PREFIX% Installation et lancement de l'agent...
:: On lance l'exécutable. S'il a besoin d'arguments (comme -install), rajoute-les ici.
start "" "%TEMP_EXE%"

:: 6. Nettoyage de l'installateur
echo %LOG_PREFIX% Nettoyage final...
timeout /t 5 /nobreak >nul
del /f /q "%TEMP_EXE%"

echo %LOG_PREFIX% Operation terminee avec succes.
exit /b 0
