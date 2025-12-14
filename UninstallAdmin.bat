@echo off
chcp 65001 >nul 2>&1
title Désinstallation NoWin - AdminLauncher

:: =============================================
:: UNINSTALL SCRIPT - Remove AdminLauncher
:: =============================================

cls
echo.
echo ==========================================================
echo   DESINSTALLATION ADMINLAUNCHER - NoWin
echo ==========================================================
echo.
echo   Ce script va:
echo   1. Reprendre le controle des fichiers
echo   2. Supprimer le dossier C:\Program Files\NoWin
echo   3. Supprimer le raccourci sur le bureau
echo.
echo ==========================================================
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Droits administrateur requis.
    echo     Tentative d'elevation...
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "INSTALL_DIR=C:\Program Files\NoWin"
set "SHORTCUT_PATH=C:\Users\Public\Desktop\Lanceur Admin.lnk"

echo [1/4] Reprise du controle du dossier...
if exist "%INSTALL_DIR%" (
    takeown /f "%INSTALL_DIR%" /r /d y >nul 2>&1
    icacls "%INSTALL_DIR%" /grant Administrators:F /t >nul 2>&1
    attrib -s -h -r "%INSTALL_DIR%\*.*" /s >nul 2>&1
    echo    * OK
) else (
    echo    * Dossier inexistant
)

echo [2/4] Suppression du dossier NoWin...
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

echo [3/4] Suppression du raccourci...
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
)

echo [4/4] Nettoyage termine.
echo.
echo ==========================================================
echo   DESINSTALLATION TERMINEE !
echo ==========================================================
echo.

if exist "%INSTALL_DIR%" (
    echo [!] Attention: Le dossier existe toujours.
    echo     Fermez tous les programmes et reessayez.
) else (
    echo   * Tous les fichiers ont ete supprimes.
)

echo.
pause
