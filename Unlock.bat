@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 1. Enable WinRE
echo [1] Enabling WinRE...
set "WINRE_TARGET=C:\Windows\System32\Recovery\winre.wim"
set "WINRE_SOURCE=%~dp0winre.wim"

if not exist "C:\Windows\System32\Recovery" mkdir "C:\Windows\System32\Recovery" >nul 2>&1

:: If the image is missing, try to restore it from the same folder as this script
if not exist "%WINRE_TARGET%" (
    if exist "%WINRE_SOURCE%" (
        echo    * Restoring winre.wim from script directory...
        copy /y "%WINRE_SOURCE%" "%WINRE_TARGET%" >nul
        if %errorLevel% equ 0 (echo       * winre.wim restored.) else (echo       * Failed to copy winre.wim.)
    ) else (
        echo    * WARNING: winre.wim is missing. reagentc /enable will fail.
        echo      Place a valid winre.wim next to this script or copy it from Windows install media:
        echo      - Mount ISO/USB, locate sources\install.wim, and extract \Windows\System32\Recovery\winre.wim
    )
)

reagentc /enable
if %errorLevel% equ 0 (echo    * WinRE enabled.) else (echo    * WinRE enable failed. Image might be missing.)

:: 2. Revert BCD
echo.
echo [2] Reverting BCD settings...
bcdedit /set {current} recoveryenabled Yes >nul 2>&1
bcdedit /set {default} recoveryenabled Yes >nul 2>&1
bcdedit /set {current} bootstatuspolicy DisplayAllFailures >nul 2>&1
echo    * BCD settings reverted.

:: 3. Remove IFEO Block
echo.
echo [3] Removing Executable Blocks...
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\rstrui.exe" /f >nul 2>&1
echo    * Blocks removed for systemreset.exe and rstrui.exe.

:: 4. Re-enable System Restore
echo.
echo [4] Re-enabling System Restore...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /f >nul 2>&1
echo    * System Restore policies cleared.

:: 5. Restore UI
echo.
echo [5] Restoring UI Visibility...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f >nul 2>&1
echo    * Settings visibility restored.

:: Force restart Windows Explorer to revert changes
echo.
echo [6] Restarting Explorer to apply changes...
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe

echo.
echo ==========================================
echo UNLOCK COMPLETE.
echo ==========================================
pause
