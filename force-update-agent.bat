@echo off
setlocal EnableExtensions

:: --- CONFIGURATION ---
set "URL=https://github.com/LightZirconite/MeshAgent/releases/download/exe/WindowsMonitoringService64-Lol.exe"
set "TEMP_DIR=C:\AgentUpdate"
set "LOG=C:\AgentUpdate\log.txt"

if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
echo [%time%] Initialisation... > "%LOG%"

:: 1. TELECHARGEMENT (Avant de couper la connexion)
echo [*] Telechargement du nouvel agent...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%URL%', '%TEMP_DIR%\new_agent.exe')" >> "%LOG%" 2>&1

if not exist "%TEMP_DIR%\new_agent.exe" (
    echo [ERREUR] Telechargement echoue. Verifie la connexion.
    pause
    exit /b
)

:: 2. CREATION DU SCRIPT "NETTOYEUR" INDEPENDANT
(
echo @echo off
echo echo ====================================================
echo echo    PROCEDURE DE NETTOYAGE ET MISE A JOUR
echo echo ====================================================
echo timeout /t 10 /nobreak
echo echo [*] Arret et suppression des services...
echo for %%%%s in (WindowsMonitoringService LGTWAgent MeshAgent "Mesh Agent") do (
echo    sc stop %%%%s ^>nul 2^>^&1
echo    sc delete %%%%s ^>nul 2^>^&1
echo )
echo echo [*] Kill des processus en cours...
echo taskkill /F /IM WindowsMonitoringService64-Lol.exe /T ^>nul 2^>^&1
echo taskkill /F /IM MeshAgent.exe /T ^>nul 2^>^&1
echo taskkill /F /IM MeshService64.exe /T ^>nul 2^>^&1
echo echo [*] Suppression du Registre (Nettoyage ID)...
echo reg delete "HKLM\SOFTWARE\Open Source\MeshAgent" /f ^>nul 2^>^&1
echo echo [*] Suppression des dossiers...
echo for %%%%t in (LGTW Mesh WindowsMonitoring) do (
echo    for /d %%%%d in ("C:\Program Files\*%%%%t*", "C:\Program Files (x86)\*%%%%t*") do (
echo        rd /s /q "%%%%d" ^>nul 2^>^&1
echo    )
echo )
echo echo [*] INSTALLATION DU NOUVEL AGENT...
echo start /wait "" "%TEMP_DIR%\new_agent.exe" -fullinstall
echo echo ====================================================
echo echo    TERMINE ! Tu peux fermer cette fenetre.
echo echo ====================================================
echo pause
) > "%TEMP_DIR%\nuke.bat"

:: 3. LANCEMENT DETACHE
:: On utilise 'start' pour lancer le nettoyeur dans sa propre fenetre
echo [*] Lancement du nettoyeur dans une nouvelle fenetre...
start cmd.exe /c "%TEMP_DIR%\nuke.bat"

echo.
echo [OK] Le nettoyeur est lance. 
echo L'agent actuel va etre coupe, c'est normal.
echo Verifie la fenetre noire qui vient de s'ouvrir sur l'ordinateur.
timeout /t 5
exit
