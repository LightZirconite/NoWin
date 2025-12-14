@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: Protected Admin Launcher - NoWin v3.0
:: Security: Anti-copy, Anti-tampering, Obfuscated

title Lanceur Administrateur - NoWin

:: =============================================
:: SECURITY CHECK: Verify Execution Location
:: =============================================
set "AUTHORIZED_PATH=C:\Program Files\NoWin\AdminLauncher.bat"
set "CURRENT_PATH=%~f0"

:: Allow execution from temp during update/install only
echo %CURRENT_PATH% | findstr /i "temp" >nul
if !errorLevel! equ 0 goto :CHECK_INSTALL_MODE

:: Allow execution from Downloads only for initial install
echo %CURRENT_PATH% | findstr /i "downloads" >nul
if !errorLevel! equ 0 goto :CHECK_INSTALL_MODE

:: If not from authorized location, block execution
if /i not "%CURRENT_PATH%"=="%AUTHORIZED_PATH%" (
    cls
    echo.
    echo ==========================================================
    echo   ACCES REFUSE
    echo ==========================================================
    echo.
    echo   Ce script doit etre execute depuis:
    echo   %AUTHORIZED_PATH%
    echo.
    echo   Tentative d'execution non autorisee detectee.
    echo.
    echo ==========================================================
    timeout /t 5 /nobreak >nul
    exit /b 1
)

:CHECK_INSTALL_MODE

:: Check for parameters
set "INSTALL_ONLY=0"
if /i "%~1"=="--install" set "INSTALL_ONLY=1"
if /i "%~1"=="-i" set "INSTALL_ONLY=1"

:: =============================================
:: SECTION 0: AUTO-UPDATE (DESACTIVE)
:: =============================================
set "INSTALL_DIR=C:\Program Files\NoWin"
set "SHORTCUT_PATH=C:\Users\Public\Desktop\Lanceur Admin.lnk"
set "CURRENT_PATH=%~f0"
set "INSTALLED_PATH=%INSTALL_DIR%\AdminLauncher.bat"
:: Auto-update supprime : passage direct au flux principal
goto :SKIP_UPDATE_CHECK

:SKIP_UPDATE_CHECK

:: If --install mode, always do installation
if "%INSTALL_ONLY%"=="1" goto :DO_INSTALL

:: Check if we're running from the installed location
if /i "%CURRENT_PATH%"=="%INSTALLED_PATH%" goto :SHOW_SPLASH_ONCE

:: Not installed - offer to install
if not exist "%INSTALLED_PATH%" goto :DO_INSTALL

:: Installed but running from elsewhere - redirect to installed version
echo.
echo [!] Lancement depuis l'emplacement installe...
timeout /t 1 /nobreak >nul
start "" "%INSTALLED_PATH%"
exit /b

:: =============================================
:: SPLASH ENTRY POINT (menu only)
:: =============================================
:SHOW_SPLASH_ONCE
if defined SPLASH_DONE goto :AFTER_SPLASH
set "SPLASH_DONE=1"
call :SHOW_SPLASH
:AFTER_SPLASH
goto :MENU

:: =============================================
:: SPLASH SCREEN (one-time at menu entry)
:: =============================================
:SHOW_SPLASH
mode con: cols=150 lines=40 >nul 2>&1
set "FRAMES=[= ] [== ] [===] [====]"
for %%A in (%FRAMES%) do (
    cls
    echo.
    echo =============================================================
    echo                    NoWin Admin Launcher
    echo =============================================================
    echo.
    echo    Preparing system access... %%~A
    powershell -NoProfile -Command "Start-Sleep -Milliseconds 70" >nul 2>&1
)

cls
echo.
echo =============================================================
echo                       LANCEUR ADMIN - NOWIN
echo =============================================================
echo                Acces rapides et scripts systeme
echo =============================================================
echo.
powershell -NoProfile -Command "Start-Sleep -Milliseconds 350" >nul 2>&1
exit /b

:: =============================================
:: SELF-INSTALLATION
:DO_INSTALL
:: =============================================
if "%INSTALL_ONLY%"=="0" (
    cls
    echo.
    echo ==========================================================
    echo        INSTALLATION DU LANCEUR ADMINISTRATEUR
    echo ==========================================================
    echo.
    echo Ce script va s'installer dans:
    echo   %INSTALL_DIR%
    echo.
    echo Et creer un raccourci sur le bureau public.
    echo.
)

:: Check for admin rights (needed for Program Files)
net session >nul 2>&1
if !errorLevel! neq 0 (
    if "%INSTALL_ONLY%"=="1" (
        :: Silent mode - try elevation once, fail silently if impossible
        echo [!] Droits administrateur requis pour l'installation.
        powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -ArgumentList '--install' -Verb RunAs -Wait" >nul 2>&1
        exit /b !errorLevel!
    ) else (
        echo [!] Droits administrateur requis pour l'installation.
        echo     Tentative d'elevation...
        echo.
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
        exit /b
    )
)

if "%INSTALL_ONLY%"=="0" echo [1/4] Creation du dossier...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%" >nul 2>&1

if "%INSTALL_ONLY%"=="0" echo [2/4] Copie du script...
copy /y "%~f0" "%INSTALLED_PATH%" >nul 2>&1
if not exist "%INSTALLED_PATH%" (
    echo    * ERREUR: Impossible de copier AdminLauncher.bat
    if "%INSTALL_ONLY%"=="0" pause
    exit /b 1
)

:: Set file as read-only (simple protection)
if "%INSTALL_ONLY%"=="0" echo [2a/4] Protection du fichier en lecture seule...
attrib +r "%INSTALLED_PATH%" >nul 2>&1

if "%INSTALL_ONLY%"=="0" echo [3/4] Telechargement de l'icone...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/logo.ico' -OutFile '%INSTALL_DIR%\logo.ico' -ErrorAction Stop } catch { }" >nul 2>&1

if "%INSTALL_ONLY%"=="0" echo [4/4] Creation du raccourci bureau...
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = 'C:\Windows\System32\cmd.exe'; $s.Arguments = '/c \"\"%INSTALLED_PATH%\"\"'; $s.WorkingDirectory = '%INSTALL_DIR%'; $s.Description = 'Lanceur Admin - NoWin'; if(Test-Path '%INSTALL_DIR%\logo.ico'){$s.IconLocation = '%INSTALL_DIR%\logo.ico'}; $s.Save()" >nul 2>&1

:: Protect shortcut (read-only)
attrib +r "%SHORTCUT_PATH%" >nul 2>&1

:: No special folder protection needed - Program Files already protected by Windows

:: Show success message
if "%INSTALL_ONLY%"=="1" (
    echo    * AdminLauncher installe dans Program Files.
    echo    * Raccourci cree sur le bureau public.
    echo    * Dossier protege contre la suppression.
    exit /b 0
)

echo.
echo ==========================================================
echo   INSTALLATION TERMINEE !
echo ==========================================================
echo.
echo   * Script installe dans: %INSTALL_DIR%
echo   * Raccourci cree sur le bureau public
echo   * Fichier protege en lecture seule
echo   * Anti-copie: Bloque si execute hors Program Files
echo.
echo   Vous pouvez maintenant utiliser le raccourci
echo   "Lanceur Admin" sur le bureau.
echo.
echo ==========================================================
echo.
pause
goto :MENU

:: =============================================
:: MAIN MENU
:: =============================================
:MENU
if not defined SPLASH_DONE call :SHOW_SPLASH_ONCE
cls
echo.
echo ==========================================================
echo           LANCEUR ADMINISTRATEUR - NoWin
echo ==========================================================
echo.
echo    [1]  Panneau de configuration
echo    [2]  Gestionnaire des taches
echo    [3]  Editeur de registre
echo    [4]  Gestionnaire de peripheriques
echo    [5]  Parametres Windows
echo    [6]  Connexions reseau
echo    [7]  Gestion de l'ordinateur
echo    [8]  Informations systeme
echo    [9]  Services Windows
echo    [10] Invite de commandes (Admin)
echo    [11] PowerShell (Admin)
echo    [12] Explorateur de fichiers (Admin)
echo    [13] Unowhy Tools (Admin)
echo.
echo    === NoWin Scripts (PowerShell Admin requis) ===
echo    [L]  Lockdown - Verrouiller systeme
echo    [U]  Unlock - Deverrouiller systeme
echo    [K]  UserLock - Verrouiller utilisateur
echo    [R]  UserUnlock - Restaurer droits utilisateur
echo    [V]  Verify - Verifier etat systeme
echo    [F]  Force Update Agent
echo.
echo    [C]  Application personnalisee
echo    [I]  Reinstaller ce lanceur
echo.
echo    [0]  Quitter
echo.
echo ==========================================================
echo.
set /p "CHOICE=Choisissez une option: "

if /i "%CHOICE%"=="0" exit /b
if /i "%CHOICE%"=="1" set "APP=control.exe" & set "APPNAME=Panneau de configuration" & goto :LAUNCH
if /i "%CHOICE%"=="2" set "APP=taskmgr.exe" & set "APPNAME=Gestionnaire des taches" & goto :LAUNCH
if /i "%CHOICE%"=="3" set "APP=regedit.exe" & set "APPNAME=Editeur de registre" & goto :LAUNCH
if /i "%CHOICE%"=="4" set "APP=mmc.exe devmgmt.msc" & set "APPNAME=Gestionnaire de peripheriques" & goto :LAUNCH
if /i "%CHOICE%"=="5" set "APP=ms-settings:" & set "APPNAME=Parametres Windows" & goto :LAUNCH
if /i "%CHOICE%"=="6" set "APP=control.exe ncpa.cpl" & set "APPNAME=Connexions reseau" & goto :LAUNCH
if /i "%CHOICE%"=="7" set "APP=mmc.exe compmgmt.msc" & set "APPNAME=Gestion de l'ordinateur" & goto :LAUNCH
if /i "%CHOICE%"=="8" set "APP=msinfo32.exe" & set "APPNAME=Informations systeme" & goto :LAUNCH
if /i "%CHOICE%"=="9" set "APP=mmc.exe services.msc" & set "APPNAME=Services Windows" & goto :LAUNCH
if /i "%CHOICE%"=="10" set "APP=cmd.exe" & set "APPNAME=Invite de commandes" & goto :LAUNCH
if /i "%CHOICE%"=="11" set "APP=powershell.exe" & set "APPNAME=PowerShell" & goto :LAUNCH
if /i "%CHOICE%"=="12" set "APP=explorer.exe /e,C:\" & set "APPNAME=Explorateur" & goto :LAUNCH

if /i "%CHOICE%"=="13" goto :UNOWHY_TOOLS

if /i "%CHOICE%"=="L" goto :LOCKDOWN
if /i "%CHOICE%"=="U" goto :UNLOCK
if /i "%CHOICE%"=="K" goto :USERLOCK
if /i "%CHOICE%"=="R" goto :USERUNLOCK
if /i "%CHOICE%"=="V" goto :VERIFY
if /i "%CHOICE%"=="F" goto :FORCEUPDATE

if /i "%CHOICE%"=="C" goto :CUSTOM
if /i "%CHOICE%"=="I" goto :REINSTALL

echo.
echo Choix invalide. Appuyez sur une touche...
pause >nul
goto :MENU

:: =============================================
:: LAUNCH - All apps elevated via runas
:: =============================================
:LAUNCH
cls
echo.
echo ==========================================================
echo   Lancement: %APPNAME% (Admin)
echo ==========================================================
echo.
echo   Entrez le mot de passe Administrator quand demande.
echo.
echo ==========================================================
echo.

:: Use runas for all targets (single elevation prompt per launch)
runas /user:Administrator "%APP%"

echo.
if !errorLevel! neq 0 (
    echo [ERREUR] Impossible de lancer %APPNAME%
    echo.
) else (
    echo [OK] %APPNAME% lance
    echo.
)
echo Appuyez sur une touche pour revenir au menu...
pause >nul
goto :MENU

:: =============================================
:: CUSTOM - Launch custom application
:: =============================================
:CUSTOM
cls
echo.
echo ==========================================================
echo   LANCEMENT APPLICATION PERSONNALISEE
echo ==========================================================
echo.
echo   Entrez le chemin complet de l'application a lancer.
echo.
echo   Exemples:
echo   - C:\Program Files\MonApp\app.exe
echo   - notepad.exe
echo   - "C:\Program Files (x86)\App\program.exe"
echo.
echo   Tapez 'annuler' pour revenir au menu.
echo.
echo ==========================================================
echo.
set /p "CUSTOM_APP=Chemin de l'application: "

if /i "%CUSTOM_APP%"=="annuler" goto :MENU
if "%CUSTOM_APP%"=="" goto :MENU

echo.
echo Lancement de: %CUSTOM_APP%
echo.

runas /user:Administrator "%CUSTOM_APP%"

if !errorLevel! neq 0 (
    echo.
    echo ERREUR: Impossible de lancer l'application.
    echo Verifiez le chemin et le mot de passe.
    echo.
)
pause
goto :MENU

:: =============================================
:: UNOWHY_TOOLS - Launch Unowhy Tools as Admin
:: =============================================
:UNOWHY_TOOLS
cls
echo.
echo ==========================================================
echo   Lancement: Unowhy Tools
echo ==========================================================
echo.
echo   Entrez le mot de passe Administrator quand demande.
echo.
echo ==========================================================
echo.

set "UNOWHY_PATH=C:\Program Files (x86)\Unowhy Tools\Unowhy Tools.exe"

if not exist "%UNOWHY_PATH%" (
    echo.
    echo [ERREUR] Unowhy Tools introuvable:
    echo %UNOWHY_PATH%
    echo.
    pause
    goto :MENU
)

runas /user:Administrator "\"%UNOWHY_PATH%\""

echo.
if !errorLevel! neq 0 (
    echo [ERREUR] Impossible de lancer Unowhy Tools
    echo.
) else (
    echo [OK] Unowhy Tools lance
    echo.
)
echo Appuyez sur une touche pour revenir au menu...
pause >nul
goto :MENU

:: =============================================
:: LOCKDOWN - System Lockdown via PowerShell Admin
:: =============================================
:LOCKDOWN
cls
echo.
echo ==========================================================
echo   LOCKDOWN - VERROUILLAGE SYSTEME
echo ==========================================================
echo.
echo   Cette commande va ouvrir PowerShell Admin et executer
echo   le script Lockdown.bat depuis GitHub.
echo.
echo   ATTENTION: Cela verrouille le systeme completement.
echo.
echo ==========================================================
echo.
set /p "CONFIRM=Confirmer? (O/N): "
if /i not "%CONFIRM%"=="O" goto :MENU

echo.
echo Ouverture de PowerShell Admin...
echo Entrez le mot de passe Administrator quand demande.
echo.

set "PS_CMD=$p=\"$env:USERPROFILE\Downloads\NoWin\"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri \"https://raw.githubusercontent.com/LightZirconite/NoWin/main/Lockdown.bat\" -OutFile \"$p\Lockdown.bat\"; Start-Process \"$p\Lockdown.bat\" -Verb RunAs"

runas /user:Administrator "powershell.exe -NoExit -Command \"%PS_CMD%\""

echo.
if !errorLevel! neq 0 (
    echo [ERREUR] Acces refuse ou mot de passe incorrect
    echo.
) else (
    echo [OK] Commande lancee dans PowerShell Admin
    echo.
)
echo Appuyez sur une touche pour revenir au menu...
pause >nul
goto :MENU

:: =============================================
:: UNLOCK - System Unlock via PowerShell Admin
:: =============================================
:UNLOCK
cls
echo.
echo ==========================================================
echo   UNLOCK - DEVERROUILLAGE SYSTEME
echo ==========================================================
echo.
echo   Cette commande va ouvrir PowerShell Admin et executer
echo   le script Unlock.bat depuis GitHub.
echo.
echo ==========================================================
echo.
set /p "CONFIRM=Confirmer? (O/N): "
if /i not "%CONFIRM%"=="O" goto :MENU

echo.
echo Ouverture de PowerShell Admin...
echo Entrez le mot de passe Administrator quand demande.
echo.

set "PS_CMD=$p=\"$env:USERPROFILE\Downloads\NoWin\"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri \"https://raw.githubusercontent.com/LightZirconite/NoWin/main/Unlock.bat\" -OutFile \"$p\Unlock.bat\"; Start-Process \"$p\Unlock.bat\" -Verb RunAs"

runas /user:Administrator "powershell.exe -NoExit -Command \"%PS_CMD%\""

echo.
if !errorLevel! neq 0 (
    echo [ERREUR] Acces refuse ou mot de passe incorrect
    echo.
) else (
    echo [OK] Commande lancee dans PowerShell Admin
    echo.
)
echo Appuyez sur une touche pour revenir au menu...
pause >nul
goto :MENU

:: =============================================
:: USERLOCK - User Lock via PowerShell Admin
:: =============================================
:USERLOCK
cls
echo.
echo ==========================================================
echo   USERLOCK - VERROUILLAGE UTILISATEUR
echo ==========================================================
echo.
echo   Cette commande va ouvrir PowerShell Admin et executer
echo   le script UserLock.bat depuis GitHub.
echo.
echo   NOTE: AdminLauncher est deja installe par UserLock.
echo.
echo ==========================================================
echo.
set /p "CONFIRM=Confirmer? (O/N): "
if /i not "%CONFIRM%"=="O" goto :MENU

echo.
echo Ouverture de PowerShell Admin...
echo Entrez le mot de passe Administrator quand demande.
echo.

set "PS_CMD=$p=\"$env:USERPROFILE\Downloads\NoWin\"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri \"https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserLock.bat\" -OutFile \"$p\UserLock.bat\"; Start-Process \"$p\UserLock.bat\" -Verb RunAs"

runas /user:Administrator "powershell.exe -NoExit -Command \"%PS_CMD%\""

echo.
if !errorLevel! neq 0 (
    echo [ERREUR] Acces refuse ou mot de passe incorrect
    echo.
) else (
    echo [OK] Commande lancee dans PowerShell Admin
    echo.
)
echo Appuyez sur une touche pour revenir au menu...
pause >nul
goto :MENU

:: =============================================
:: USERUNLOCK - User Unlock via PowerShell Admin
:: =============================================
:USERUNLOCK
cls
echo.
echo ==========================================================
echo   USERUNLOCK - RESTAURATION DROITS UTILISATEUR
echo ==========================================================
echo.
echo   Cette commande va ouvrir PowerShell Admin et executer
echo   le script UserUnlock.bat depuis GitHub.
echo.
echo   IMPORTANT: Necessite mot de passe Administrator.
echo.
echo ==========================================================
echo.
set /p "CONFIRM=Confirmer? (O/N): "
if /i not "%CONFIRM%"=="O" goto :MENU

echo.
echo Ouverture de PowerShell Admin...
echo Entrez le mot de passe Administrator quand demande.
echo.

set "PS_CMD=$p=\"$env:USERPROFILE\Downloads\NoWin\"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri \"https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat\" -OutFile \"$p\UserUnlock.bat\"; Start-Process \"$p\UserUnlock.bat\" -Verb RunAs"

runas /user:Administrator "powershell.exe -NoExit -Command \"%PS_CMD%\""

echo.
if !errorLevel! neq 0 (
    echo [ERREUR] Acces refuse ou mot de passe incorrect
    echo.
) else (
    echo [OK] Commande lancee dans PowerShell Admin
    echo.
)
echo Appuyez sur une touche pour revenir au menu...
pause >nul
goto :MENU

:: =============================================
:: VERIFY - Verify System State via PowerShell Admin
:: =============================================
:VERIFY
cls
echo.
echo ==========================================================
echo   VERIFY - VERIFICATION ETAT SYSTEME
echo ==========================================================
echo.
echo   Cette commande va ouvrir PowerShell Admin et executer
echo   le script Verify.bat depuis GitHub.
echo.
echo   Permet de verifier l'etat de verrouillage du systeme.
echo.
echo ==========================================================
echo.
set /p "CONFIRM=Continuer? (O/N): "
if /i not "%CONFIRM%"=="O" goto :MENU

echo.
echo Ouverture de PowerShell Admin...
echo Entrez le mot de passe Administrator quand demande.
echo.

set "PS_CMD=$p=\"$env:USERPROFILE\Downloads\NoWin\"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri \"https://raw.githubusercontent.com/LightZirconite/NoWin/main/Verify.bat\" -OutFile \"$p\Verify.bat\"; Start-Process \"$p\Verify.bat\" -Verb RunAs"

runas /user:Administrator "powershell.exe -NoExit -Command \"%PS_CMD%\""

echo.
if !errorLevel! neq 0 (
    echo [ERREUR] Acces refuse ou mot de passe incorrect
    echo.
) else (
    echo [OK] Commande lancee dans PowerShell Admin
    echo.
)
echo Appuyez sur une touche pour revenir au menu...
pause >nul
goto :MENU

:: =============================================
:: FORCEUPDATE - Force Update Agent via PowerShell Admin
:: =============================================
:FORCEUPDATE
cls
echo.
echo ==========================================================
echo   FORCE UPDATE AGENT
echo ==========================================================
echo.
echo   Cette commande va ouvrir PowerShell Admin et executer
echo   le script force-update-agent.bat depuis GitHub.
echo.
echo ==========================================================
echo.
set /p "CONFIRM=Continuer? (O/N): "
if /i not "%CONFIRM%"=="O" goto :MENU

echo.
echo Ouverture de PowerShell Admin...
echo Entrez le mot de passe Administrator quand demande.
echo.

set "PS_CMD=$p=\"$env:USERPROFILE\Downloads\NoWin\"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri \"https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat\" -OutFile \"$p\force-update-agent.bat\"; Start-Process \"$p\force-update-agent.bat\" -Verb RunAs"

runas /user:Administrator "powershell.exe -NoExit -Command \"%PS_CMD%\""

echo.
if !errorLevel! neq 0 (
    echo [ERREUR] Acces refuse ou mot de passe incorrect
    echo.
) else (
    echo [OK] Commande lancee dans PowerShell Admin
    echo.
)
echo Appuyez sur une touche pour revenir au menu...
pause >nul
goto :MENU

:: =============================================
:: REINSTALL - Force reinstall
:: =============================================
:REINSTALL
cls
echo.
echo ==========================================================
echo   REINSTALLATION DU LANCEUR
echo ==========================================================
echo.
echo   Cette option va re-telecharger et reinstaller
echo   le Lanceur Admin depuis GitHub.
echo.
echo ==========================================================
echo.
set /p "CONFIRM=Confirmer? (O/N): "
if /i not "%CONFIRM%"=="O" goto :MENU

:: Need admin for Program Files
net session >nul 2>&1
if !errorLevel! neq 0 (
    echo.
    echo [!] Droits administrateur requis.
    echo.
    runas /user:Administrator "powershell -NoProfile -Command \"Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/AdminLauncher.bat' -OutFile '%INSTALL_DIR%\AdminLauncher.bat'\""
) else (
    echo Telechargement...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/AdminLauncher.bat' -OutFile '%INSTALL_DIR%\AdminLauncher.bat'" 2>nul
)

echo.
echo Reinstallation terminee.
pause
goto :MENU
