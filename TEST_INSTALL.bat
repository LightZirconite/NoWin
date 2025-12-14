@echo off
chcp 65001 >nul 2>&1
:: ============================================
:: TEST ADMIN LAUNCHER INSTALLATION
:: ============================================

echo ==========================================
echo   TEST ADMINLAUNCHER --INSTALL MODE
echo ==========================================
echo.

:: Get script directory
set "SCRIPT_DIR=%~dp0"
set "TEMP_LAUNCHER=%TEMP%\AdminLauncher_test.bat"

echo [1/2] Copie du script dans TEMP...
echo     Source: %SCRIPT_DIR%AdminLauncher.bat
echo     Destination: %TEMP_LAUNCHER%

if not exist "%SCRIPT_DIR%AdminLauncher.bat" (
    echo     [ERREUR] Fichier source introuvable!
    pause
    exit /b 1
)

copy /y "%SCRIPT_DIR%AdminLauncher.bat" "%TEMP_LAUNCHER%"
if %errorLevel% neq 0 (
    echo     [ERREUR] Echec de la copie - Code erreur: %errorLevel%
    pause
    exit /b 1
)

if exist "%TEMP_LAUNCHER%" (
    echo [2/2] Execution en mode --install...
    echo.
    echo === DEBUT OUTPUT ADMINLAUNCHER ===
    call "%TEMP_LAUNCHER%" --install
    echo.
    echo === FIN OUTPUT ADMINLAUNCHER ===
    echo.
    
    :: Cleanup
    del /f /q "%TEMP_LAUNCHER%" >nul 2>&1
    
    echo.
    echo ==========================================
    echo   TEST COMPLETE
    echo ==========================================
    echo.
    echo Verification:
    if exist "C:\Program Files\NoWin\AdminLauncher.bat" (
        echo   [OK] AdminLauncher installe dans Program Files
    ) else (
        echo   [ERREUR] AdminLauncher NON trouve dans Program Files
    )
    
    if exist "C:\Users\Public\Desktop\Lanceur Admin.lnk" (
        echo   [OK] Raccourci cree sur le bureau
    ) else (
        echo   [ERREUR] Raccourci NON trouve
    )
) else (
    echo [ERREUR] Impossible de copier AdminLauncher.bat
)

echo.
pause
