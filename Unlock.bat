@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: UNLOCK.BAT - Complete System Recovery Restore
:: Version 2.2 - Matches Lockdown v2.2
:: ============================================
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ========================================
    echo    ELEVATION REQUISE
    echo ========================================
    echo.
    echo Ce script necessite des droits ADMINISTRATEUR.
    echo Tentative d'elevation automatique...
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" 2>nul
    if !errorLevel! neq 0 (
        echo [ERREUR] Impossible d'obtenir les droits administrateur.
        echo.
        echo Causes possibles:
        echo  - Le popup UAC a ete refuse ou n'est pas apparu
        echo  - Vous n'etes pas connecte avec un compte administrateur
        echo  - UAC est desactive dans les parametres systeme
        echo.
        echo SOLUTION:
        echo  1. Clic droit sur ce script
        echo  2. Choisir "Executer en tant qu'administrateur"
        echo  3. Accepter le popup UAC
        echo.
        pause
    )
    exit /b
)

echo ==========================================
echo     SYSTEM UNLOCK v2.2
echo ==========================================
echo.

:: =============================================
:: SECTION 1: RESTORE WINRE
:: =============================================
echo [1] Restoring WinRE (Recovery Environment)...

set "WINRE_TARGET=C:\Windows\System32\Recovery\winre.wim"
set "WINRE_SOURCE=%~dp0winre.wim"

:: Create Recovery directory if missing
if not exist "C:\Windows\System32\Recovery" mkdir "C:\Windows\System32\Recovery" >nul 2>&1

:: Restore winre.wim if available
if not exist "%WINRE_TARGET%" (
    if exist "%WINRE_SOURCE%" (
        echo    * Restoring winre.wim from script directory...
        copy /y "%WINRE_SOURCE%" "%WINRE_TARGET%" >nul
        if %errorLevel% equ 0 (echo       -> winre.wim restored.) else (echo       -> Failed to copy winre.wim.)
    ) else (
        echo    * WARNING: winre.wim not found.
        echo      To fully restore WinRE, place a valid winre.wim next to this script.
        echo      Source: Windows install media - sources\install.wim\Windows\System32\Recovery\winre.wim
    )
)

:: Enable WinRE
reagentc /enable >nul 2>&1
if %errorLevel% equ 0 (echo    * WinRE enabled via reagentc.) else (echo    * WinRE enable failed - image may be missing.)

echo    * WinRE restoration complete.

:: =============================================
:: SECTION 2: RESTORE BCD SETTINGS
:: =============================================
echo.
echo [2] Restoring Boot Configuration (BCD)...

:: 2.1 Re-enable recovery
bcdedit /set {current} recoveryenabled Yes >nul 2>&1
bcdedit /set {default} recoveryenabled Yes >nul 2>&1
bcdedit /deletevalue {globalsettings} recoveryenabled >nul 2>&1

:: 2.2 Restore boot status policy
bcdedit /set {current} bootstatuspolicy DisplayAllFailures >nul 2>&1
bcdedit /set {default} bootstatuspolicy DisplayAllFailures >nul 2>&1

:: 2.3 Re-enable automatic repair
bcdedit /deletevalue {current} autorecoveryenabled >nul 2>&1
bcdedit /deletevalue {default} autorecoveryenabled >nul 2>&1

:: 2.4 Restore boot timeout (default 30 seconds)
bcdedit /timeout 30 >nul 2>&1

:: 2.5 Restore boot menu policy
bcdedit /set {default} bootmenupolicy Standard >nul 2>&1
bcdedit /set {current} bootmenupolicy Standard >nul 2>&1

:: 2.6 DISABLE advanced options flags (use /set false as fallback, /deletevalue may fail)
:: First try to set to false (always works), then try to delete
bcdedit /set {globalsettings} advancedoptions false >nul 2>&1
bcdedit /set {globalsettings} optionsedit false >nul 2>&1
:: Also try deletevalue as secondary cleanup
bcdedit /deletevalue {globalsettings} advancedoptions >nul 2>&1
bcdedit /deletevalue {globalsettings} optionsedit >nul 2>&1

:: 2.7 Re-enable bootlog
bcdedit /deletevalue {current} bootlog >nul 2>&1

echo    * BCD settings restored.

:: =============================================
:: SECTION 3: RESTORE USB/EXTERNAL BOOT
:: =============================================
echo.
echo [3] Restoring External Boot Sources...

:: 3.1 Re-enable USB storage
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
echo    * USB Storage devices enabled.

:: 3.2 Re-enable CD/DVD
reg add "HKLM\SYSTEM\CurrentControlSet\Services\cdrom" /v Start /t REG_DWORD /d 1 /f >nul 2>&1
echo    * CD/DVD devices enabled.

:: 3.3 Remove Secure Boot restriction
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\SecureBoot" /v AvailableUpdates /f >nul 2>&1

:: 3.4 Remove setup/oobe blocks
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\setup.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\oobe.exe" /f >nul 2>&1

echo    * External boot sources restored.

:: =============================================
:: SECTION 4: REMOVE ALL IFEO BLOCKS
:: =============================================
echo.
echo [4] Removing Executable Blocks...

:: Remove all recovery executable blocks
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\rstrui.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\recoverydrive.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\srtasks.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\winre.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ReAgentc.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\StartupRepairOffline.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\FreshStart.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msconfig.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\recenv.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\dism.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sfc.exe" /f >nul 2>&1

echo    * All executable blocks removed.

:: =============================================
:: SECTION 5: RESTORE SYSTEM RESTORE
:: =============================================
echo.
echo [5] Re-enabling System Restore...

:: 5.1 Remove GPO restrictions
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /f >nul 2>&1

:: 5.2 Re-enable System Protection services
reg add "HKLM\SYSTEM\CurrentControlSet\Services\swprv" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\VSS" /v Start /t REG_DWORD /d 3 /f >nul 2>&1

:: 5.3 Start services
net start swprv >nul 2>&1
net start VSS >nul 2>&1

echo    * System Restore re-enabled.

:: =============================================
:: SECTION 6: RESTORE SAFE MODE ACCESS
:: =============================================
echo.
echo [6] Restoring Safe Mode Access...

:: 6.1 Restore Safe Mode alternate shell
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Minimal" /v AlternateShell /t REG_SZ /d "cmd.exe" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network" /v AlternateShell /t REG_SZ /d "cmd.exe" /f >nul 2>&1

echo    * Safe Mode access restored.

:: =============================================
:: SECTION 7: RESTORE ADVANCED STARTUP OPTIONS
:: =============================================
echo.
echo [7] Restoring Advanced Startup Options...

:: 7.1 Re-enable Shift+Restart
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableAdvancedStartup /f >nul 2>&1

:: 7.2 Re-enable UEFI firmware settings access
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" /v DisableUEFIFirmwareSettings /f >nul 2>&1

:: 7.3 Re-enable firmware settings menu
powershell -NoProfile -Command "Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name 'DisableFirmwareSettingsMenu' -Force -ErrorAction SilentlyContinue"

echo    * Advanced startup options restored.

:: =============================================
:: SECTION 8: RESTORE COMMAND PROMPT ACCESS
:: =============================================
echo.
echo [8] Restoring Command Prompt Access...

:: 8.1 Re-enable Command Prompt
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v DisableCMD /f >nul 2>&1

:: 8.2 Re-enable Recovery Console
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRecoveryConsole /f >nul 2>&1

echo    * Command Prompt access restored.

:: =============================================
:: SECTION 9: RESTORE UI VISIBILITY
:: =============================================
echo.
echo [9] Restoring UI Visibility...

:: 9.1 Remove Settings page hiding
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f >nul 2>&1
reg delete "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f >nul 2>&1

echo    * UI visibility restored.

:: =============================================
:: SECTION 10: REMOVE ADDITIONAL HARDENING
:: =============================================
echo.
echo [10] Removing Additional Restrictions...

:: 10.1 Re-enable Windows Update features
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DisableOSUpgrade /f >nul 2>&1

:: 10.2 Re-enable Push-button reset
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent\recovery" /v Disabled /f >nul 2>&1

:: 10.3 Re-enable automatic maintenance
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v MaintenanceDisabled /f >nul 2>&1

:: 10.4 Re-enable Windows Error Recovery
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Windows" /v NoInteractiveServices /f >nul 2>&1

:: 10.5 Re-enable BitLocker recovery options
reg delete "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v UseAdvancedStartup /f >nul 2>&1

echo    * Additional restrictions removed.

:: =============================================
:: SECTION 11: RESTORE SLEEP/HIBERNATION
:: =============================================
echo.
echo [11] Restoring Sleep and Hibernation...

:: 11.1 Re-enable hibernation
powercfg /hibernate on >nul 2>&1
echo    * Hibernation enabled.

:: 11.2 Restore default sleep timeouts (30 min AC, 15 min battery)
powercfg /change standby-timeout-ac 30 >nul 2>&1
powercfg /change standby-timeout-dc 15 >nul 2>&1
echo    * Sleep timeouts restored.

:: 11.3 Re-enable hybrid sleep
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 1 >nul 2>&1

:: 11.4 Re-enable fast startup
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 1 /f >nul 2>&1

:: 11.5 Apply power scheme changes
powercfg /setactive SCHEME_CURRENT >nul 2>&1

echo    * Sleep/Hibernation restored.

:: =============================================
:: SECTION 12: RESTORE WIFI ACCESS
:: =============================================
echo.
echo [12] Restoring WiFi Access...

:: 12.1 Restore Network Connections folder access
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetworkConnections /f >nul 2>&1
echo    * Network Connections folder restored.

:: 12.2 Show Network icon in system tray
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCANetwork /f >nul 2>&1
echo    * Network tray icon restored.

:: 12.3 Re-enable WiFi toggle
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" /v NC_ShowSharedAccessUI /f >nul 2>&1

:: 12.4 Unblock netsh.exe
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\netsh.exe" /f >nul 2>&1
echo    * netsh.exe unblocked.

:: 12.5 Re-enable TCP/IP configuration
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" /v NC_AllowAdvancedTCPIPConfig /f >nul 2>&1

:: 12.6 Restore settings pages visibility
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f >nul 2>&1
echo    * Settings pages restored.

:: 12.7 Re-enable Airplane Mode
reg delete "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Connectivity" /v AllowAirplaneMode /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Connectivity" /v AllowAirplaneMode /f >nul 2>&1
echo    * Airplane Mode re-enabled.

:: 12.8 Re-enable network adapter changes
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" /v NC_LanChangeProperties /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" /v NC_EnableAdminProhibits /f >nul 2>&1
echo    * Network adapter settings restored.

echo    * WiFi access fully restored.

:: =============================================
:: SECTION 13: RESTART EXPLORER
:: =============================================
echo.
echo [13] Restarting Explorer to apply changes...
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe

echo.
echo ==========================================
echo       UNLOCK COMPLETE (v2.2)
echo ==========================================
echo.
echo Restored features:
echo  [+] WinRE / Recovery Environment
echo  [+] USB Boot / External Media
echo  [+] Safe Mode
echo  [+] Advanced Startup Options (Shift+Restart)
echo  [+] System Reset / Fresh Start
echo  [+] System Restore / Shadow Copies
echo  [+] Recovery Command Prompt
echo  [+] DISM / SFC tools
echo  [+] Sleep / Hibernation
echo  [+] WiFi Access (full control)
echo.
echo NOTE: A reboot is recommended to fully apply changes.
echo.
pause
