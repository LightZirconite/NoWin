@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: NoWin v4.2 - Smart System Manager
:: Point d'entree principal (Menu Intelligent)
:: ============================================

set "VERSION=4.2"
set "SCRIPT_DIR=%~dp0"
set "REPO_RAW=https://raw.githubusercontent.com/LightZirconite/NoWin/main"
set "AUTO_YES=0"
set "SKIP_UPDATE=0"
set "ACTION=MENU"
set "ACTION_SCRIPT="
set "ACTION_ARGS="
set "PASS_YES=0"

for %%A in (%*) do (
    set "ARG=%%~A"
    if /i "!ARG!"=="--yes" set "AUTO_YES=1"
    if /i "!ARG!"=="--skip-update" set "SKIP_UPDATE=1"
    if /i "!ARG!"=="--help" set "ACTION=HELP"
    if /i "!ARG!"=="help" set "ACTION=HELP"
    if /i "!ARG!"=="menu" set "ACTION=MENU"

    if /i "!ARG!"=="1" call :set_action "Lockdown.bat" "" "1"
    if /i "!ARG!"=="2" call :set_action "Unlock.bat" "" "1"
    if /i "!ARG!"=="3" call :set_action "UserLock.bat" "" "1"
    if /i "!ARG!"=="4" call :set_action "UserUnlock.bat" "" "1"
    if /i "!ARG!"=="5" call :set_action "Verify.bat" "" "1"
    if /i "!ARG!"=="6" call :set_action "AdminLauncher.bat" "" "0"
    if /i "!ARG!"=="7" call :set_action "force-update-agent.bat" "" "1"
    if /i "!ARG!"=="8" call :set_action "Watchdog.bat" "" "0"
    if /i "!ARG!"=="9" call :set_action "AutoUpdate.bat" "" "0"

    if /i "!ARG!"=="lockdown" call :set_action "Lockdown.bat" "" "1"
    if /i "!ARG!"=="unlock" call :set_action "Unlock.bat" "" "1"
    if /i "!ARG!"=="userlock" call :set_action "UserLock.bat" "" "1"
    if /i "!ARG!"=="userunlock" call :set_action "UserUnlock.bat" "" "1"
    if /i "!ARG!"=="verify" call :set_action "Verify.bat" "" "1"
    if /i "!ARG!"=="adminlauncher" call :set_action "AdminLauncher.bat" "" "0"
    if /i "!ARG!"=="force-update" call :set_action "force-update-agent.bat" "" "1"
    if /i "!ARG!"=="watchdog" call :set_action "Watchdog.bat" "" "0"

    if /i "!ARG!"=="watchdog-install" call :set_action "Watchdog.bat" "--install" "0"
    if /i "!ARG!"=="watchdog-uninstall" call :set_action "Watchdog.bat" "--uninstall" "0"
    if /i "!ARG!"=="watchdog-run" call :set_action "Watchdog.bat" "--run" "0"

    if /i "!ARG!"=="autoupdate" call :set_action "AutoUpdate.bat" "" "0"
    if /i "!ARG!"=="autoupdate-check" call :set_action "AutoUpdate.bat" "--check" "0"
    if /i "!ARG!"=="autoupdate-install" call :set_action "AutoUpdate.bat" "--install" "0"
    if /i "!ARG!"=="autoupdate-uninstall" call :set_action "AutoUpdate.bat" "--uninstall" "0"
    if /i "!ARG!"=="autoupdate-update" call :set_action "AutoUpdate.bat" "--update" "0"
)

if /i "%ACTION%"=="HELP" goto :help

:: Vérification des droits Administrateur
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ========================================
    echo    ELEVATION REQUISE
    echo ========================================
    echo.
    echo Lancement du Smart Menu avec droits Admin...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs" 2>nul
    exit /b
)

if defined ACTION_SCRIPT (
    call :run_action
    exit /b %errorlevel%
)

:menu
cls
echo ==========================================================
echo        NoWin v%VERSION% - SMART SYSTEM MANAGER
echo ==========================================================
echo.
echo   🔒 PROTECTION SYSTEME
echo   [1] Lockdown       (Bloquer la réinitialisation PC)
echo   [2] Unlock         (Débloquer la réinitialisation PC)
echo.
echo   👤 GESTION UTILISATEUR
echo   [3] UserLock       (Restreindre l'utilisateur actuel)
echo   [4] UserUnlock     (Restaurer les droits Administrateur)
echo.
echo   🛠️ OUTILS ET DIAGNOSTICS
echo   [5] Verify         (Rapport d'état de sécurité complet)
echo   [6] AdminLauncher  (Ouvrir le menu d'outils bloqués)
echo   [7] Force Update   (Mettre à jour l'agent MeshCentral)
echo   [8] Watchdog       (Auto-Remediation ^& Logs)
echo   [9] AutoUpdate     (Mise a jour GitHub auto/manuelle)
echo.
echo   [A] AutoUpdate Check      (Verification rapide)
echo   [B] AutoUpdate Update     (Appliquer les updates)
echo   [C] AutoUpdate Install    (Planifier a 03:30)
echo   [D] AutoUpdate Uninstall  (Retirer planification)
echo.
echo   [0] Quitter
echo ==========================================================
echo.
set /p choix="👉 Choisissez une action (0-9): "

set "ACTION_SCRIPT="
set "ACTION_ARGS="
set "PASS_YES=0"

if "%choix%"=="1" call :set_action "Lockdown.bat" "" "1"
if "%choix%"=="2" call :set_action "Unlock.bat" "" "1"
if "%choix%"=="3" call :set_action "UserLock.bat" "" "1"
if "%choix%"=="4" call :set_action "UserUnlock.bat" "" "1"
if "%choix%"=="5" call :set_action "Verify.bat" "" "1"
if "%choix%"=="6" call :set_action "AdminLauncher.bat" "" "0"
if "%choix%"=="7" call :set_action "force-update-agent.bat" "" "1"
if "%choix%"=="8" call :set_action "Watchdog.bat" "" "0"
if "%choix%"=="9" call :set_action "AutoUpdate.bat" "" "0"
if /i "%choix%"=="A" call :set_action "AutoUpdate.bat" "--check" "0"
if /i "%choix%"=="B" call :set_action "AutoUpdate.bat" "--update" "0"
if /i "%choix%"=="C" call :set_action "AutoUpdate.bat" "--install" "0"
if /i "%choix%"=="D" call :set_action "AutoUpdate.bat" "--uninstall" "0"
if "%choix%"=="0" exit /b

if not defined ACTION_SCRIPT (
    echo Choix invalide.
    timeout /t 2 >nul
    goto menu
)

call :run_action
echo.
echo ==========================================================
echo   Operation terminee.
echo ==========================================================
pause
goto menu

goto :eof

:set_action
set "ACTION=CLI"
set "ACTION_SCRIPT=%~1"
set "ACTION_ARGS=%~2"
set "PASS_YES=%~3"
exit /b 0

:run_action
if "%SKIP_UPDATE%"=="0" (
    if /i not "%ACTION_SCRIPT%"=="AutoUpdate.bat" (
        if /i not "%ACTION_SCRIPT%"=="Watchdog.bat" (
            if "%AUTO_YES%"=="1" (
                call :ensure_script "AutoUpdate.bat"
                if exist "%SCRIPT_DIR%AutoUpdate.bat" (
                    call "%SCRIPT_DIR%AutoUpdate.bat" --run >nul 2>&1
                )
            )
        )
    )
)

call :ensure_script "%ACTION_SCRIPT%"
if not exist "%SCRIPT_DIR%%ACTION_SCRIPT%" (
    echo [ERREUR] Script introuvable: %ACTION_SCRIPT%
    exit /b 1
)

set "FINAL_ARGS=%ACTION_ARGS%"

if "%AUTO_YES%"=="1" (
    if "%PASS_YES%"=="1" set "FINAL_ARGS=%FINAL_ARGS% --yes"
    if /i "%ACTION_SCRIPT%"=="AutoUpdate.bat" (
        if "%ACTION_ARGS%"=="--update" set "FINAL_ARGS=--run"
    )
)

cls
echo ==========================================================
echo   Lancement de : %ACTION_SCRIPT% %FINAL_ARGS%
echo ==========================================================
echo.
call "%SCRIPT_DIR%%ACTION_SCRIPT%" %FINAL_ARGS%
exit /b %errorlevel%

:ensure_script
set "TARGET_SCRIPT=%~1"
if exist "%SCRIPT_DIR%%TARGET_SCRIPT%" exit /b 0

echo.
echo [*] Le fichier %TARGET_SCRIPT% n'existe pas localement.
echo [*] Telechargement depuis GitHub en cours...
powershell -NoProfile -Command "Invoke-WebRequest -UseBasicParsing -Uri '%REPO_RAW%/%TARGET_SCRIPT%' -OutFile '%SCRIPT_DIR%%TARGET_SCRIPT%'" >nul 2>&1
if not exist "%SCRIPT_DIR%%TARGET_SCRIPT%" (
    echo [ERREUR] Impossible de telecharger %TARGET_SCRIPT%. Verifiez la connexion.
    exit /b 1
)
exit /b 0

:help
echo ==========================================================
echo NoWin v%VERSION% - Commandes
echo ==========================================================
echo.
echo Usage:
echo   NoWin.bat                    ^(menu interactif^)
echo   NoWin.bat lockdown --yes     ^(execution directe, sans prompts^)
echo   NoWin.bat unlock --yes
echo   NoWin.bat userlock --yes
echo   NoWin.bat userunlock --yes
echo   NoWin.bat verify --yes
echo   NoWin.bat autoupdate-check
echo   NoWin.bat autoupdate-update --yes
echo   NoWin.bat autoupdate-install
echo   NoWin.bat watchdog-install
echo.
echo Options:
echo   --yes           Valide automatiquement les confirmations quand supporte
echo   --skip-update   Ignore le pre-check AutoUpdate avant execution CLI
echo.
exit /b 0
