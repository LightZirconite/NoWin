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

echo [3] Blocage Executable (systemreset.exe ^& rstrui.exe) :
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /v Debugger 2>nul
if %errorLevel% equ 0 (
    echo    * OK : systemreset.exe neutralise
) else (
    echo    * ATTENTION : systemreset.exe ACTIF
)
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\rstrui.exe" /v Debugger 2>nul
if %errorLevel% equ 0 (
    echo    * OK : rstrui.exe ^(Restauration^) neutralise
) else (
    echo    * ATTENTION : rstrui.exe ACTIF
)
echo.
echo ------------------------------------------

echo [4] System Restore Policy :
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableSR 2>nul
if %errorLevel% equ 0 (
    echo    * OK : Restauration systeme desactivee par GPO
) else (
    echo    * INFO : Restauration systeme active
)
echo.
echo ------------------------------------------

echo [5] Masquage Visuel (SettingsPageVisibility) :
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility 2>nul
if %errorLevel% equ 0 (
    echo    * OK : Pages masquees ^(hide:recovery;backup^)
) else (
    echo    * INFO : Visible
)
echo.
echo ------------------------------------------

echo [6] User Privileges Check :
set "CHECK_USER=%USERNAME%"
:: Try to detect the real logged-on user
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "$u=(Get-WmiObject Win32_ComputerSystem).UserName; if($u){$u.Split('\')[1]}"`) do (
    if not "%%a"=="" set "CHECK_USER=%%a"
)

net localgroup Administrators | findstr /i "\<%CHECK_USER%\>" >nul
if %errorLevel% equ 0 (
    echo    * WARNING : User [%CHECK_USER%] is an ADMINISTRATOR.
) else (
    echo    * OK : User [%CHECK_USER%] is a STANDARD USER.
)
echo.
echo    * Built-in Administrator status:
net user Administrator | findstr /i "active"

echo.
echo ==========================================
echo Appuyez sur une touche pour fermer...
pause >nul
