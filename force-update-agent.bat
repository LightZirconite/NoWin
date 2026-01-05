@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: --- CONFIGURATION ---
set "NEW_URL=https://github.com/LightZirconite/MeshAgent/releases/download/exe/WindowsMonitoringService64-Lol.exe"
set "WORK_DIR=C:\Windows\Temp\AgentUpdate"
set "INSTALLER_NAME=NewAgent.exe"
set "MARKER_FILE=%WORK_DIR%\cleanup_done.txt"

:: 1. CREATION DU DOSSIER DE TRAVAIL
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
cd /d "%WORK_DIR%"

echo [*] Telechargement du nouvel agent...
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%NEW_URL%' -OutFile '%INSTALLER_NAME%'"

if not exist "%INSTALLER_NAME%" (
    echo [ERREUR] Impossible de telecharger l'agent.
    exit /b 1
)

:: 2. CREATION DU SCRIPT DE NETTOYAGE RADICAL (Worker)
(
echo @echo off
echo timeout /t 10 /nobreak
echo :: --- 1. KILL PROCESSUS ---
echo for %%%%p in (MeshAgent.exe MeshService64.exe LGTW-Agent64-Lol.exe WindowsMonitoringService64-Lol.exe WinMonService.exe) do (
echo    taskkill /F /IM %%%%p /T ^>nul 2^>^&1
echo )
echo :: --- 2. SUPPRESSION SERVICES ---
echo for %%%%s in (MeshAgent "Mesh Agent" LGTWAgent WindowsMonitoringService WinMonService) do (
echo    net stop %%%%s /y ^>nul 2^>^&1
echo    sc delete %%%%s ^>nul 2^>^&1
echo )
echo :: --- 3. RECHERCHE ET DESTRUCTION DES DOSSIERS (SCAN) ---
echo set "TARGETS=Mesh LGTW WindowsMonitoring"
echo for %%%%t in (%%TARGETS%%) do (
echo    for /d %%%%d in ("C:\Program Files\*%%%%t*", "C:\Program Files (x86)\*%%%%t*", "C:\ProgramData\*%%%%t*") do (
echo        echo Suppression de %%%%d
echo        takeown /f "%%%%d" /r /d y ^>nul 2^>^&1
echo        icacls "%%%%d" /grant administrators:F /t ^>nul 2^>^&1
echo        rd /s /q "%%%%d" ^>nul 2^>^&1
echo    )
echo )
echo :: --- 4. NETTOYAGE REGISTRE (SERVICES RESTANTS) ---
echo reg delete "HKLM\SYSTEM\CurrentControlSet\Services\MeshAgent" /f ^>nul 2^>^&1
echo reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LGTWAgent" /f ^>nul 2^>^&1
echo :: --- 5. INSTALLATION ---
echo "%WORK_DIR%\%INSTALLER_NAME%" -fullinstall
echo echo Termine ^> "%MARKER_FILE%"
echo :: --- 6. AUTO-DESTRUCTION DE LA TACHE ---
echo schtasks /delete /tn "AgentPurge" /f ^>nul 2^>^&1
echo exit
) > "%WORK_DIR%\purge.bat"

:: 3. EXECUTION VIA TACHE PLANIFIEE (ULTRA ROBUSTE)
:: On lance le script via une tâche pour qu'il survive à la fermeture de l'agent actuel
echo [*] Planification du nettoyage profond...
schtasks /create /tn "AgentPurge" /tr "%WORK_DIR%\purge.bat" /sc once /st 00:00 /sd 01/01/2099 /rl highest /ru SYSTEM /f >nul 2>&1
schtasks /run /tn "AgentPurge" >nul 2>&1

echo [*] Le processus est detache. L'ancien agent va etre supprime.
echo [*] La reconnexion se fera automatiquement avec le nouvel agent.
timeout /t 5
exit
