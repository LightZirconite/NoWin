@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: UNINSTALLADMIN.BAT - Remove AdminLauncher
:: Version 3.0 - Matches NoWin v3.0
:: ============================================

title Desinstallation AdminLauncher - NoWin v3.0

cls
echo.
echo ==========================================
echo   DESINSTALLATION ADMINLAUNCHER v3.0
echo ==========================================
echo.
echo Ce script va:
echo   1. Reprendre controle des fichiers
echo   2. Supprimer C:\Program Files\NoWin
echo   3. Supprimer raccourci bureau
echo.
echo ==========================================
echo.

:: Check for admin rights
net session >nul 2>&1
if !errorLevel! neq 0 (
    echo.
    echo ========================================
    echo    ELEVATION REQUISE
    echo ========================================
    echo.
    echo Ce script necessite des droits ADMINISTRATEUR.
    echo Tentative d'elevation automatique...
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "INSTALL_DIR=C:\Program Files\NoWin"
set "SHORTCUT_PATH=C:\Users\Public\Desktop\Lanceur Admin.lnk"

echo [1/4] Fermeture des processus en cours...
taskkill /F /FI "WINDOWTITLE eq Lanceur Administrateur - NoWin*" >nul 2>&1
taskkill /F /FI "IMAGENAME eq cmd.exe" /FI "WINDOWTITLE eq Administrateur*" >nul 2>&1
timeout /t 1 /nobreak >nul
echo    * OK

echo [2/4] Reprise du controle du dossier...
if exist "%INSTALL_DIR%" (
    takeown /f "%INSTALL_DIR%" /r /d y >nul 2>&1
    icacls "%INSTALL_DIR%" /grant Administrators:F /t >nul 2>&1
    attrib -s -h -r "%INSTALL_DIR%\*.*" /s >nul 2>&1
    echo    * OK
) else (
    echo    * Dossier inexistant
)

echo [3/4] Suppression du dossier NoWin...
if exist "%INSTALL_DIR%" (
    rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
    if exist "%INSTALL_DIR%" (
        echo    * ERREUR: Impossible de supprimer
    ) else (
        echo    * OK
    )
) else (
    echo    * Deja supprime
)

echo [4/4] Suppression du raccourci...
if exist "%SHORTCUT_PATH%" (
    attrib -r -s "%SHORTCUT_PATH%" >nul 2>&1
    del /f /q "%SHORTCUT_PATH%" >nul 2>&1
    if exist "%SHORTCUT_PATH%" (
        echo    * ERREUR: Impossible de supprimer
    ) else (
        echo    * OK
    )
) else (
    echo    * Deja supprime
echo   DESINSTALLATION TERMINEE (v3.0)
echo ==========================================
echo.

if exist "%INSTALL_DIR%" (
    echo [!] ATTENTION: Dossier existe toujours.
    echo     Fermez tous les programmes et reessayez.
) else (
    echo  [+] Tous les fichiers supprimes.
)

echo.
echo ==========================================    echo [!] Attention: Le dossier existe toujours.
    echo     Fermez tous les programmes et reessayez.
) else (
    echo   * Tous les fichiers ont ete supprimes.
)

echo.
pause
