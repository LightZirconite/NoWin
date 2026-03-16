@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: WATCHDOG.BAT - Auto-Guérison et Logs NoWin
:: Version 4.1 - Smart Edition
:: ============================================

set "LOG_DIR=C:\ProgramData\NoWin"
set "LOG_FILE=%LOG_DIR%\system.log"
set "TASK_NAME=NoWin_Watchdog"

if "%~1"=="--run" goto :watchdog_loop
if "%~1"=="--install" goto :install_task
if "%~1"=="--uninstall" goto :uninstall_task

:: Elevation check for interactive/install/uninstall usage
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [INFO] Elevation admin requise pour Watchdog.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs" 2>nul
    exit /b
)

:: Interface utilisateur
echo ==========================================================
echo        NoWin v4.1 - SMART WATCHDOG (Auto-Guérison)
echo ==========================================================
echo.
echo Role : Verifie silencieusement (toutes les heures) que les
echo        restrictions n'ont pas saute. Si quelqu'un modifie
echo        le registre, le Watchdog repare et log.
echo.
echo Statut actuel :
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if !errorlevel! equ 0 (
    echo [x] INSTALLE (Le Watchdog protege votre systeme)
) else (
    echo [ ] NON INSTALLE
)
echo.
echo [1] Installer le Watchdog
echo [2] Desinstaller le Watchdog
echo [3] Lancer une verification manuelle maintenant
echo [0] Quitter
echo.
set /p choix="👉 Choix : "

if "%choix%"=="1" goto install_task
if "%choix%"=="2" goto uninstall_task
if "%choix%"=="3" (
    echo.
    echo Lancement de la verification manuelle...
    call :watchdog_loop
    pause
    exit /b
)
exit /b

:install_task
echo.
echo [*] Installation de la tâche planifiee...
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
copy /y "%~f0" "%LOG_DIR%\Watchdog.bat" >nul
schtasks /create /tn "%TASK_NAME%" /tr "\"%LOG_DIR%\Watchdog.bat\" --run" /sc hourly /ru SYSTEM /rl HIGHEST /f >nul 2>&1
if !errorlevel! equ 0 (
    echo [SUCCES] Watchdog installe. Il tournera en arriere-plan (SYSTEM).
    echo [%date% %time%] Watchdog installé par l'administrateur >> "%LOG_FILE%"
) else (
    echo [ERREUR] Echec de l'installation. Lancez en Administrateur !
)
timeout /t 3 >nul
exit /b

:uninstall_task
echo.
echo [*] Suppression de la tâche planifiee...
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo [SUCCES] Watchdog desinstalle avec succes.
    echo [%date% %time%] Watchdog supprimé par l'administrateur >> "%LOG_FILE%"
) else (
    echo [INFO] Watchdog n'est pas installe ou erreur.
)
timeout /t 3 >nul
exit /b

:watchdog_loop
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "FIXED=0"

:: --- VERIFICATION 1 : BCD DisableStartupRepair ---
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" /v DisableStartupRepair >nul 2>&1
if !errorlevel! neq 0 (
    echo [%date% %time%] [ALERTE] DisableStartupRepair manquant. Remise en place... >> "%LOG_FILE%"
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" /v DisableStartupRepair /t REG_DWORD /d 1 /f >nul 2>&1
    set "FIXED=1"
)

:: --- VERIFICATION 2 : systemreset.exe block ---
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /v Debugger >nul 2>&1
if !errorlevel! neq 0 (
    echo [%date% %time%] [ALERTE] IFEO systemreset.exe manquant. Remise en place... >> "%LOG_FILE%"
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /v Debugger /t REG_SZ /d "cmd.exe /c exit" /f >nul 2>&1
    set "FIXED=1"
)

:: --- VERIFICATION 3 : System Restore Disabled ---
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableSR >nul 2>&1
if !errorlevel! neq 0 (
    echo [%date% %time%] [ALERTE] SystemRestore Policy manquant. Remise en place... >> "%LOG_FILE%"
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableSR /t REG_DWORD /d 1 /f >nul 2>&1
    set "FIXED=1"
)

if "%FIXED%"=="0" (
    :: Seulement logguer discrètement en debug si besoin, mais on evite le flood
    :: echo [%date% %time%] [INFO] Check Watchdog OK. Aucune anomalie. >> "%LOG_FILE%"
) else (
    echo [%date% %time%] [ACTION] Le Watchdog a corrige des failles. >> "%LOG_FILE%"
)

if not "%~1"=="--run" (
    echo [INFO] Verification manuelle terminee. Regardez %LOG_FILE%.
)
exit /b
