@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: ADMINLAUNCHER.BAT - Self-Installing Admin Launcher
:: Version 2.7 - ASCII-only (encoding fix)
:: ============================================
:: This script:
:: 1. Auto-installs itself to Program Files\NoWin if not already there
:: 2. Creates a protected desktop shortcut
:: 3. Launches apps as Administrator via runas (password in terminal)
::
:: Usage:
::   AdminLauncher.bat              - Normal: install if needed, then menu
::   AdminLauncher.bat --install    - Install only, no menu (for UserLock)

title Lanceur Administrateur - NoWin

:: Check for --install parameter (silent install, no menu)
set "INSTALL_ONLY=0"
if /i "%~1"=="--install" set "INSTALL_ONLY=1"
if /i "%~1"=="-i" set "INSTALL_ONLY=1"

:: =============================================
:: SECTION 0: SELF-INSTALLATION CHECK
:: =============================================
set "INSTALL_DIR=C:\Program Files\NoWin"
set "SHORTCUT_PATH=C:\Users\Public\Desktop\Lanceur Admin.lnk"
set "CURRENT_PATH=%~f0"
set "INSTALLED_PATH=%INSTALL_DIR%\AdminLauncher.bat"

:: If --install mode, always do installation
if "%INSTALL_ONLY%"=="1" goto :DO_INSTALL

:: Check if we're running from the installed location
if /i "%CURRENT_PATH%"=="%INSTALLED_PATH%" goto :MENU

:: Not installed - check if installation exists
if exist "%INSTALLED_PATH%" goto :MENU

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
if %errorLevel% neq 0 (
    if "%INSTALL_ONLY%"=="1" (
        :: Silent mode - try elevation once, fail silently if impossible
        echo [!] Droits administrateur requis pour l'installation.
        powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -ArgumentList '--install' -Verb RunAs -Wait" >nul 2>&1
        exit /b %errorLevel%
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

if "%INSTALL_ONLY%"=="0" echo [3/4] Telechargement de l'icone...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/logo.ico' -OutFile '%INSTALL_DIR%\logo.ico' -ErrorAction Stop } catch { }" >nul 2>&1

if "%INSTALL_ONLY%"=="0" echo [4/4] Creation du raccourci bureau...
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = '%INSTALLED_PATH%'; $s.WorkingDirectory = '%INSTALL_DIR%'; $s.Description = 'Lanceur Admin - NoWin'; if(Test-Path '%INSTALL_DIR%\logo.ico'){$s.IconLocation = '%INSTALL_DIR%\logo.ico'}; $s.Save()" >nul 2>&1

:: Protect shortcut (read-only + system)
attrib +r +s "%SHORTCUT_PATH%" >nul 2>&1

:: Protect folder (deny delete for Users group)
:: Get Users group name dynamically
for /f "tokens=*" %%g in ('powershell -NoProfile -Command "(New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-545')).Translate([System.Security.Principal.NTAccount]).Value.Split('\')[-1]"') do (
    icacls "%INSTALL_DIR%" /deny "%%g:(DE)" >nul 2>&1
)

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
echo   * Dossier protege contre la suppression
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
cls
echo.
echo ==========================================================
echo |           LANCEUR ADMINISTRATEUR - NoWin                 |
echo ==========================================================
echo |                                                          |
echo |   [1]  Panneau de configuration                          |
echo |   [2]  Gestionnaire des taches                           |
echo |   [3]  Editeur de registre                               |
echo |   [4]  Gestionnaire de peripheriques                     |
echo |   [5]  Parametres Windows                                |
echo |   [6]  Connexions reseau                                 |
echo |   [7]  Gestion de l'ordinateur                           |
echo |   [8]  Informations systeme                              |
echo |   [9]  Services Windows                                  |
echo |   [10] Invite de commandes (Admin)                       |
echo |   [11] PowerShell (Admin)                                |
echo |   [12] Explorateur de fichiers (Admin)                   |
echo |                                                          |
echo |   [C]  Application personnalisee                         |
echo |   [U]  Lancer UserUnlock - restaurer droits              |
echo |   [I]  Reinstaller ce lanceur                            |
echo |                                                          |
echo |   [0]  Quitter                                           |
echo |                                                          |
echo ==========================================================
echo.
set /p "CHOICE=Choisissez une option: "

if /i "%CHOICE%"=="0" exit /b
if /i "%CHOICE%"=="1" set "APP=control.exe" & set "APPNAME=Panneau de configuration" & goto :LAUNCH
if /i "%CHOICE%"=="2" set "APP=taskmgr.exe" & set "APPNAME=Gestionnaire des taches" & goto :LAUNCH
if /i "%CHOICE%"=="3" set "APP=regedit.exe" & set "APPNAME=Editeur de registre" & goto :LAUNCH
if /i "%CHOICE%"=="4" set "APP=mmc.exe devmgmt.msc" & set "APPNAME=Gestionnaire de peripheriques" & goto :LAUNCH
if /i "%CHOICE%"=="5" set "APP=cmd.exe /c start ms-settings:" & set "APPNAME=Parametres Windows" & goto :LAUNCH
if /i "%CHOICE%"=="6" set "APP=control.exe ncpa.cpl" & set "APPNAME=Connexions reseau" & goto :LAUNCH
if /i "%CHOICE%"=="7" set "APP=mmc.exe compmgmt.msc" & set "APPNAME=Gestion de l'ordinateur" & goto :LAUNCH
if /i "%CHOICE%"=="8" set "APP=msinfo32.exe" & set "APPNAME=Informations systeme" & goto :LAUNCH
if /i "%CHOICE%"=="9" set "APP=mmc.exe services.msc" & set "APPNAME=Services Windows" & goto :LAUNCH
if /i "%CHOICE%"=="10" set "APP=cmd.exe" & set "APPNAME=Invite de commandes" & goto :LAUNCH_CMD
if /i "%CHOICE%"=="11" set "APP=powershell.exe" & set "APPNAME=PowerShell" & goto :LAUNCH_CMD
if /i "%CHOICE%"=="12" set "APP=explorer.exe /e," & set "APPNAME=Explorateur" & goto :LAUNCH

if /i "%CHOICE%"=="C" goto :CUSTOM
if /i "%CHOICE%"=="U" goto :USERUNLOCK
if /i "%CHOICE%"=="I" goto :REINSTALL

echo.
echo Choix invalide. Appuyez sur une touche...
pause >nul
goto :MENU

:: =============================================
:: LAUNCH - Standard applications via runas
:: =============================================
:LAUNCH
cls
echo.
echo ==========================================================
echo   Lancement: %APPNAME%
echo ==========================================================
echo.
echo   Entrez le mot de passe Administrator quand demande.
echo.
echo ==========================================================
echo.

runas /user:Administrator "%APP%"

if %errorLevel% neq 0 (
    echo.
    echo ==========================================================
    echo   ERREUR: Impossible de lancer %APPNAME%
    echo ==========================================================
    echo.
    echo   Causes possibles:
    echo   - Mot de passe incorrect
    echo   - Le compte Administrator est desactive
    echo   - L'application n'existe pas
    echo.
    pause
)
goto :MENU

:: =============================================
:: LAUNCH_CMD - CMD/PowerShell keep window open
:: =============================================
:LAUNCH_CMD
cls
echo.
echo ==========================================================
echo   Lancement: %APPNAME% - Admin
echo ==========================================================
echo.
echo   Entrez le mot de passe Administrator quand demande.
echo.
echo   NOTE: Une nouvelle fenetre va s'ouvrir.
echo.
echo ==========================================================
echo.

if /i "%APP%"=="cmd.exe" (
    runas /user:Administrator "cmd.exe /k title CMD Administrator - NoWin"
) else (
    runas /user:Administrator "powershell.exe -NoExit -Command $Host.UI.RawUI.WindowTitle='PowerShell Admin - NoWin'"
)

if %errorLevel% neq 0 (
    echo.
    echo ERREUR: Mot de passe incorrect ou compte desactive.
    echo.
    pause
)
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

if %errorLevel% neq 0 (
    echo.
    echo ERREUR: Impossible de lancer l'application.
    echo Verifiez le chemin et le mot de passe.
    echo.
)
pause
goto :MENU

:: =============================================
:: USERUNLOCK - Download and run UserUnlock
:: =============================================
:USERUNLOCK
cls
echo.
echo ==========================================================
echo   RESTAURATION DES DROITS ADMINISTRATEUR
echo ==========================================================
echo.
echo   Cette option va:
echo   1. Telecharger UserUnlock.bat depuis GitHub
echo   2. L'executer en tant qu'Administrator
echo.
echo   Cela restaurera vos droits administrateur complets.
echo.
echo ==========================================================
echo.
set /p "CONFIRM=Confirmer? (O/N): "
if /i not "%CONFIRM%"=="O" goto :MENU

echo.
echo Telechargement de UserUnlock.bat...

set "TEMP_DIR=%TEMP%\NoWin"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat' -OutFile '%TEMP_DIR%\UserUnlock.bat'" 2>nul

if not exist "%TEMP_DIR%\UserUnlock.bat" (
    echo.
    echo ERREUR: Impossible de telecharger UserUnlock.bat
    echo Verifiez votre connexion internet.
    echo.
    pause
    goto :MENU
)

echo Telechargement OK.
echo.
echo Lancement de UserUnlock.bat en tant qu'Administrator...
echo.

runas /user:Administrator "cmd.exe /c \"%TEMP_DIR%\UserUnlock.bat\""

if %errorLevel% neq 0 (
    echo.
    echo ERREUR: Mot de passe incorrect ou compte desactive.
    echo.
    pause
)
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
if %errorLevel% neq 0 (
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
