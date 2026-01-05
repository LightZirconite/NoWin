@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: --- CONFIGURATION ---
set "NEW_URL=https://github.com/LightZirconite/MeshAgent/releases/download/exe/WindowsMonitoringService64-Lol.exe"
set "WORK_DIR=C:\Windows\Temp\AgentUpdate"
set "INSTALLER_NAME=NewAgent.exe"
set "LOG_FILE=%WORK_DIR%\install.log"

:: 1. INITIALISATION DU DOSSIER DE TRAVAIL
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
echo [%date% %time%] Debut de la procedure > "%LOG_FILE%"

:: 2. AUTO-ELEVATION ADMIN
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Droits admin requis. Elevation... >> "%LOG_FILE%"
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: 3. TELECHARGEMENT
echo [*] Telechargement de l'agent...
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%NEW_URL%' -OutFile '%WORK_DIR%\%INSTALLER_NAME%'"
if not exist "%WORK_DIR%\%INSTALLER_NAME%" (
    echo [ERREUR] Echec du telechargement >> "%LOG_FILE%"
    exit /b 1
)

:: 4. CREATION DU SCRIPT DE PURGE (Le "Worker")
(
echo @echo off
echo echo --- DEBUT DU NETTOYAGE PROFOND ---
echo timeout /t 5 /nobreak
echo :: 1. ARRET DES SERVICES (TOUS NOMS POSSIBLES)
echo for %%%%s in (WindowsMonitoringService LGTWAgent MeshAgent "Mesh Agent" MeshService) do (
echo    net stop %%%%s /y ^>nul 2^>^&1
echo    sc delete %%%%s ^>nul 2^>^&1
echo )
echo :: 2. KILL DES PROCESSUS (FORCE)
echo for %%%%p in (WindowsMonitoringService64-Lol.exe MeshAgent.exe MeshService64.exe LGTW-Agent64-Lol.exe WinMon.exe) do (
echo    taskkill /F /IM %%%%p /T ^>nul 2^>^&1
echo )
echo timeout /t 2 /nobreak
echo :: 3. NETTOYAGE DU REGISTRE (EMPECHE LES CONFLITS D'ID)
echo reg delete "HKLM\SYSTEM\CurrentControlSet\Services\WindowsMonitoringService" /f ^>nul 2^>^&1
echo reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LGTWAgent" /f ^>nul 2^>^&1
echo reg delete "HKLM\SYSTEM\CurrentControlSet\Services\MeshAgent" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\Open Source\MeshAgent" /f ^>nul 2^>^&1
echo :: 4. SUPPRESSION DES DOSSIERS (SCAN DYNAMIQUE)
echo for %%%%t in (LGTW Mesh WindowsMonitoring) do (
echo    for /d %%%%d in ("C:\Program Files\*%%%%t*", "C:\Program Files (x86)\*%%%%t*", "C:\ProgramData\*%%%%t*") do (
echo        takeown /f "%%%%d" /r /d y ^>nul 2^>^&1
echo        icacls "%%%%d" /grant administrators:F /t ^>nul 2^>^&1
echo        rd /s /q "%%%%d" ^>nul 2^>^&1
echo    )
echo )
echo :: 5. INSTALLATION DU NOUVEL AGENT
echo start /wait "" "%WORK_DIR%\%INSTALLER_NAME%" -fullinstall
echo echo [%date% %time%] Installation terminee >> "%LOG_FILE%"
echo :: 6. NETTOYAGE FINALE DE LA TACHE
echo schtasks /delete /tn "AgentCleaner" /f ^>nul 2^>^&1
echo exit
) > "%WORK_DIR%\worker.bat"

:: 5. PLANIFICATION ET EXECUTION DETACHEE
echo [*] Lancement du worker via Tache Planifiee... >> "%LOG_FILE%"
schtasks /create /tn "AgentCleaner" /tr "%WORK_DIR%\worker.bat" /sc once /st 00:00 /sd 01/01/2099 /rl highest /ru SYSTEM /f >nul 2>&1
schtasks /run /tn "AgentCleaner" >nul 2>&1

echo [*] Script termine. L'agent va redemarrer sous peu.
timeout /t 3
exit
