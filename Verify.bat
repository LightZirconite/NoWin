@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ==========================================
echo        VERIFICATION AVANCEE (ULTIMATE)
echo ==========================================
echo.

echo [1] ETAT WinRE (Moteur de recuperation) :
reagentc /info | findstr /i "status"
echo.
echo ------------------------------------------

echo [2] Protection BCD (Boot Configuration) :
bcdedit /enum {current} | findstr /i "recoveryenabled bootstatuspolicy"
echo (Attendu : recoveryenabled No / bootstatuspolicy IgnoreAllFailures)
echo.
echo ------------------------------------------

echo [3] Blocage Executable (systemreset.exe) :
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /v Debugger 2>nul
if %errorLevel% equ 0 (
    echo   -> OK : Redirection active (L'executable est neutralise)
) else (
    echo   -> ATTENTION : Pas de blocage executable
)
echo.
echo ------------------------------------------

echo [4] Masquage Visuel (SettingsPageVisibility) :
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility 2>nul
if %errorLevel% equ 0 (
    echo   -> OK : Pages masquees (hide:recovery;backup)
) else (
    echo   -> INFO : Visible
)

echo.
echo ==========================================
echo Appuyez sur une touche pour fermer...
pause >nul
