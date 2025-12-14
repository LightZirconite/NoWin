@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: ADMINLAUNCHER.BAT - Launch Blocked Apps as Admin
:: Version 2.3 - Integrated with UserLock
:: ============================================
:: This script allows admins to launch blocked applications
:: by entering the admin password (uyy)

:MENU
cls
echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║           LANCEUR ADMINISTRATEUR - NoWin                 ║
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
echo ║   [0]  Quitter                                           ║
echo ║                                                          ║
echo ╚══════════════════════════════════════════════════════════╝
echo.
set /p "CHOICE=Choisissez une option (0-12): "

if "%CHOICE%"=="0" exit /b
if "%CHOICE%"=="1" set "APP=control.exe" & set "APPNAME=Panneau de configuration" & goto :LAUNCH
if "%CHOICE%"=="2" set "APP=taskmgr.exe" & set "APPNAME=Gestionnaire des taches" & goto :LAUNCH
if "%CHOICE%"=="3" set "APP=regedit.exe" & set "APPNAME=Editeur de registre" & goto :LAUNCH
if "%CHOICE%"=="4" set "APP=devmgmt.msc" & set "APPNAME=Gestionnaire de peripheriques" & goto :LAUNCH
if "%CHOICE%"=="5" set "APP=ms-settings:" & set "APPNAME=Parametres Windows" & goto :LAUNCH_SETTINGS
if "%CHOICE%"=="6" set "APP=ncpa.cpl" & set "APPNAME=Connexions reseau" & goto :LAUNCH
if "%CHOICE%"=="7" set "APP=compmgmt.msc" & set "APPNAME=Gestion de l'ordinateur" & goto :LAUNCH
if "%CHOICE%"=="8" set "APP=msinfo32.exe" & set "APPNAME=Informations systeme" & goto :LAUNCH
if "%CHOICE%"=="9" set "APP=services.msc" & set "APPNAME=Services Windows" & goto :LAUNCH
if "%CHOICE%"=="10" set "APP=cmd.exe" & set "APPNAME=Invite de commandes" & goto :LAUNCH
if "%CHOICE%"=="11" set "APP=powershell.exe" & set "APPNAME=PowerShell" & goto :LAUNCH
if "%CHOICE%"=="12" set "APP=explorer.exe" & set "APPNAME=Explorateur" & goto :LAUNCH

echo.
echo Choix invalide. Appuyez sur une touche...
pause >nul
goto :MENU

:LAUNCH
echo.
echo Lancement de: %APPNAME%
echo.
echo Une fenetre UAC va apparaitre.
echo Selectionnez "Administrator" et entrez le mot de passe.
echo.
timeout /t 2 >nul

:: Launch with elevation request
powershell -NoProfile -Command "Start-Process '%APP%' -Verb RunAs" 2>nul

if %errorLevel% neq 0 (
    echo.
    echo ERREUR: Impossible de lancer %APPNAME%.
    echo L'elevation a peut-etre ete refusee.
    echo.
    pause
)
goto :MENU

:LAUNCH_SETTINGS
echo.
echo Lancement de: %APPNAME%
echo.
timeout /t 1 >nul

:: Settings app needs special handling
powershell -NoProfile -Command "Start-Process 'ms-settings:'" 2>nul
goto :MENU
