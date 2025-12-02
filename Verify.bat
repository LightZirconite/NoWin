@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ==========================================
echo        VERIFICATION DU VERROUILLAGE
echo ==========================================
echo.

echo [1] ETAT WinRE (Doit etre 'Disabled' ou 'Desactive') :
reagentc /info
echo.
echo ------------------------------------------
echo.

echo [2] Protection Panneau de Config (NoControlPanel) :
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel 2>nul
if %errorLevel% equ 0 (
    echo   -> OK : La cle existe (Verrouille si 0x1)
) else (
    echo   -> INFO : La cle n'existe pas (Deverrouille)
)
echo.
echo ------------------------------------------
echo.

echo [3] Protection Page Parametres (SettingsPageVisibility) :
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility 2>nul
if %errorLevel% equ 0 (
    echo   -> OK : La cle existe (Verrouille si hide:recovery)
) else (
    echo   -> INFO : La cle n'existe pas (Deverrouille)
)

echo.
echo ==========================================
echo Appuyez sur une touche pour fermer...
pause >nul
