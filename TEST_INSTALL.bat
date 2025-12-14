@echo off
chcp 65001 >nul 2>&1
:: ============================================
:: TEST ADMIN LAUNCHER INSTALLATION
:: ============================================

echo ==========================================
echo   TEST ADMINLAUNCHER --INSTALL MODE
echo ==========================================
echo.

:: Simulate UserLock calling AdminLauncher
set "TEMP_LAUNCHER=%TEMP%\AdminLauncher_test.bat"

echo [1/2] Copie du script dans TEMP...
copy /y "AdminLauncher.bat" "%TEMP_LAUNCHER%" >nul 2>&1

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
