@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 1. Disable WinRE (The Engine)
echo [1] Disabling WinRE...
reagentc /disable
if %errorLevel% equ 0 (echo    * WinRE disabled.) else (echo    * WinRE disable failed or already disabled.)

:: 1.1 Hard Disable: Delete the WinRE image so it cannot be re-enabled easily
:: When disabled, the file is moved to C:\Windows\System32\Recovery\winre.wim
:: Deleting this ensures that even 'reagentc /enable' will fail without a source image.
if exist "C:\Windows\System32\Recovery\winre.wim" (
    echo    * Found winre.wim. Deleting for hard disable...
    takeown /f "C:\Windows\System32\Recovery\winre.wim" >nul 2>&1
    icacls "C:\Windows\System32\Recovery\winre.wim" /grant administrators:F >nul 2>&1
    del /f /q "C:\Windows\System32\Recovery\winre.wim"
    if exist "C:\Windows\System32\Recovery\winre.wim" (echo       * Failed to delete winre.wim.) else (echo       * winre.wim deleted.)
)

:: 2. BCD Hardening (Boot Configuration)
echo.
echo [2] Hardening BCD...
:: Disable recovery in bootloader
bcdedit /set {current} recoveryenabled No >nul 2>&1
bcdedit /set {default} recoveryenabled No >nul 2>&1
:: Prevent auto-triggering recovery on boot failures
bcdedit /set {current} bootstatuspolicy IgnoreAllFailures >nul 2>&1
echo    * BCD policies updated.

:: 3. IFEO Blocking (The Executable)
echo.
echo [3] Blocking Recovery Executables...
:: Redirect systemreset.exe to a dummy command so it cannot run
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo SYSTEM RESET BLOCKED BY ADMINISTRATOR ^& pause" /f >nul 2>&1
:: Redirect rstrui.exe (System Restore) to a dummy command
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\rstrui.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo SYSTEM RESTORE BLOCKED BY ADMINISTRATOR ^& pause" /f >nul 2>&1
echo    * IFEO debuggers set for systemreset.exe and rstrui.exe.

:: 4. Disable System Restore & Shadow Copies
echo.
echo [4] Disabling System Restore...
:: Disable System Restore via Policy
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableConfig /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableSR /t REG_DWORD /d 1 /f >nul 2>&1
echo    * System Restore policies set.
:: Delete existing Shadow Copies (Restore Points)
echo    * Deleting existing Shadow Copies (this may take a moment)...
vssadmin delete shadows /all /quiet >nul 2>&1
echo    * Shadow Copies deleted.

:: 5. UI Hiding (The Settings App)
echo.
echo [5] Hiding Recovery UI...
:: Hide Recovery and Backup pages in Settings
:: Note: We remove NoControlPanel to allow Settings app access
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /t REG_SZ /d "hide:recovery;backup" /f >nul 2>&1
echo    * Settings pages hidden.

:: Force restart Windows Explorer to apply changes
echo.
echo [6] Restarting Explorer to apply changes...
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe

echo.
echo ==========================================
echo LOCKDOWN COMPLETE.
echo ==========================================
pause
