@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: ADMINLAUNCHER.BAT - Launch Apps as Admin via Console
:: Version 2.5 - No UAC Popup, Password in Terminal
:: ============================================
:: This script allows launching applications as Administrator
:: by entering the password directly in the terminal (runas)
:: This bypasses the UAC popup completely.

title Lanceur Administrateur - NoWin

:MENU
cls
echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║           LANCEUR ADMINISTRATEUR - NoWin                 ║
echo ║                   (Mot de passe: uyy)                    ║
echo ╠══════════════════════════════════════════════════════════╣
echo ║                                                          ║
echo ║   [1]  Panneau de configuration                          ║
echo ║   [2]  Gestionnaire des taches                           ║
echo ║   [3]  Editeur de registre                               ║
echo ║   [4]  Gestionnaire de peripheriques                     ║
echo ║   [5]  Parametres Windows                                ║
echo ║   [6]  Connexions reseau                                 ║
echo ║   [7]  Gestion de l'ordinateur                           ║
echo ║   [8]  Informations systeme                              ║
echo ║   [9]  Services Windows                                  ║
echo ║   [10] Invite de commandes (Admin)                       ║
echo ║   [11] PowerShell (Admin)                                ║
echo ║   [12] Explorateur de fichiers (Admin)                   ║
echo ║                                                          ║
echo ║   [C]  Application personnalisee                         ║
echo ║   [U]  Lancer UserUnlock (restaurer droits)              ║
echo ║                                                          ║
echo ║   [0]  Quitter                                           ║
echo ║                                                          ║
echo ╚══════════════════════════════════════════════════════════╝
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
echo ══════════════════════════════════════════════════════════
echo   Lancement: %APPNAME%
echo ══════════════════════════════════════════════════════════
echo.
echo   Entrez le mot de passe Administrator quand demande.
echo   (Mot de passe par defaut: uyy)
echo.
echo ══════════════════════════════════════════════════════════
echo.

:: Use runas to launch with password prompt in console
runas /user:Administrator "%APP%"

if %errorLevel% neq 0 (
    echo.
    echo ══════════════════════════════════════════════════════════
    echo   ERREUR: Impossible de lancer %APPNAME%
    echo ══════════════════════════════════════════════════════════
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
echo ══════════════════════════════════════════════════════════
echo   Lancement: %APPNAME% (Admin)
echo ══════════════════════════════════════════════════════════
echo.
echo   Entrez le mot de passe Administrator quand demande.
echo   (Mot de passe par defaut: uyy)
echo.
echo   NOTE: Une nouvelle fenetre va s'ouvrir.
echo.
echo ══════════════════════════════════════════════════════════
echo.

if /i "%APP%"=="cmd.exe" (
    runas /user:Administrator "cmd.exe /k title CMD Administrator - NoWin"
) else (
    runas /user:Administrator "powershell.exe -NoExit -Command \"$Host.UI.RawUI.WindowTitle = 'PowerShell Administrator - NoWin'\""
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
echo ══════════════════════════════════════════════════════════
echo   LANCEMENT APPLICATION PERSONNALISEE
echo ══════════════════════════════════════════════════════════
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
echo ══════════════════════════════════════════════════════════
echo.
set /p "CUSTOM_APP=Chemin de l'application: "

if /i "%CUSTOM_APP%"=="annuler" goto :MENU
if "%CUSTOM_APP%"=="" goto :MENU

echo.
echo Lancement de: %CUSTOM_APP%
echo.
echo Entrez le mot de passe Administrator (uyy):
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
echo ══════════════════════════════════════════════════════════
echo   RESTAURATION DES DROITS ADMINISTRATEUR
echo ══════════════════════════════════════════════════════════
echo.
echo   Cette option va:
echo   1. Telecharger UserUnlock.bat depuis GitHub
echo   2. L'executer en tant qu'Administrator
echo.
echo   Cela restaurera vos droits administrateur complets.
echo.
echo ══════════════════════════════════════════════════════════
echo.
set /p "CONFIRM=Confirmer? (O/N): "
if /i not "%CONFIRM%"=="O" goto :MENU

echo.
echo Telechargement de UserUnlock.bat...

:: Create temp directory
set "TEMP_DIR=%TEMP%\NoWin"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: Download UserUnlock.bat
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
echo Entrez le mot de passe Administrator (uyy):
echo.

runas /user:Administrator "cmd.exe /c \"%TEMP_DIR%\UserUnlock.bat\""

if %errorLevel% neq 0 (
    echo.
    echo ERREUR: Mot de passe incorrect ou compte desactive.
    echo.
    pause
)
goto :MENU
