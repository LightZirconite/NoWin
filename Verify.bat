@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: VERIFY.BAT - Complete System Status Verification
:: Version 2.5 - Matches Lockdown v2.2 / UserLock v2.5
:: ============================================

:: Check for --yes argument (bypass confirmations)
set "AUTO_YES=0"
if /i "%~1"=="--yes" set "AUTO_YES=1"

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

echo.
echo ============================================================
echo          VERIFICATION COMPLETE DU SYSTEME v3.0
echo ============================================================
echo.

:: =============================================
:: SECTION 1: WINRE STATUS
:: =============================================
echo [1] ETAT WinRE (Environnement de recuperation) :
echo ------------------------------------------------------------
reagentc /info 2>nul | findstr /i "status"
echo.
echo    Fichiers WinRE:
echo    * C:\Windows\System32\Recovery\winre.wim
if exist "C:\Windows\System32\Recovery\winre.wim" (echo       -> [!] PRESENT - Non securise) else (echo       -> [OK] ABSENT)
echo    * C:\Recovery\WindowsRE\winre.wim
if exist "C:\Recovery\WindowsRE\winre.wim" (echo       -> [!] PRESENT - Non securise) else (echo       -> [OK] ABSENT)
echo    * C:\Recovery\ (dossier)
if exist "C:\Recovery" (echo       -> [!] PRESENT - Non securise) else (echo       -> [OK] ABSENT)
echo.
echo    Configuration ReAgent:
echo    * C:\Windows\System32\Recovery\ReAgent.xml
if exist "C:\Windows\System32\Recovery\ReAgent.xml" (echo       -> [!] PRESENT) else (echo       -> [OK] ABSENT)
echo.

:: =============================================
:: SECTION 2: BCD STATUS
:: =============================================
echo [2] PROTECTION BCD (Boot Configuration) :
echo ------------------------------------------------------------
echo    Parametres actuels:
bcdedit /enum {current} 2>nul | findstr /i "recoveryenabled bootstatuspolicy"
bcdedit /enum {current} 2>nul | findstr /i "recoverysequence"
echo.
echo    Attendu si securise: recoveryenabled=No, bootstatuspolicy=IgnoreAllFailures
echo    Lien recoverysequence: doit etre absent
echo.
echo    Boot timeout:
bcdedit 2>nul | findstr /i "timeout"
echo    (0 = securise, >0 = permet acces menu boot)
echo.

:: =============================================
:: SECTION 3: USB/EXTERNAL BOOT (NOT BLOCKED BY LOCKDOWN v3.0)
:: =============================================
echo [3] BLOCAGE USB / BOOT EXTERNE (NON GERE PAR LOCKDOWN v3.0) :
echo ------------------------------------------------------------
echo    USB Storage (USBSTOR):
reg query "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start 2>nul | findstr "Start"
echo    (Start=4 -> BLOQUE, Start=3 -> ACTIF)
echo.
echo    CD/DVD (cdrom):
reg query "HKLM\SYSTEM\CurrentControlSet\Services\cdrom" /v Start 2>nul | findstr "Start"
echo    (Start=4 -> BLOQUE, Start=1 -> ACTIF)
echo.
echo    NOTE: Lockdown v3.0 ne bloque plus USB/CD.
echo          Utilisez UserLock si necessaire.
echo.

:: =============================================
:: SECTION 4: IFEO BLOCKS STATUS
:: =============================================
echo [4] BLOCAGE EXECUTABLES (IFEO) :
echo ------------------------------------------------------------

set "BLOCKED_COUNT=0"

:: Check systemreset.exe
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /v Debugger >nul 2>&1
if %errorLevel% equ 0 (
    echo    * systemreset.exe       [OK] BLOQUE
    set /a BLOCKED_COUNT+=1
) else (
    echo    * systemreset.exe       [!] ACTIF
)

:: Check rstrui.exe
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\rstrui.exe" /v Debugger >nul 2>&1
if %errorLevel% equ 0 (
    echo    * rstrui.exe            [OK] BLOQUE
    set /a BLOCKED_COUNT+=1
) else (
    echo    * rstrui.exe            [!] ACTIF
)

:: Check recoverydrive.exe
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\recoverydrive.exe" /v Debugger >nul 2>&1
if %errorLevel% equ 0 (
    echo    * recoverydrive.exe     [OK] BLOQUE
    set /a BLOCKED_COUNT+=1
) else (
    echo    * recoverydrive.exe     [!] ACTIF
)

:: Check msconfig.exe
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msconfig.exe" /v Debugger >nul 2>&1
if %errorLevel% equ 0 (
    echo    * msconfig.exe          [OK] BLOQUE
    set /a BLOCKED_COUNT+=1
) else (
    echo    * msconfig.exe          [!] ACTIF
)

:: Check dism.exe
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\dism.exe" /v Debugger >nul 2>&1
if %errorLevel% equ 0 (
    echo    * dism.exe              [OK] BLOQUE
    set /a BLOCKED_COUNT+=1
) else (
    echo    * dism.exe              [!] ACTIF
)

:: Check sfc.exe
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sfc.exe" /v Debugger >nul 2>&1
if %errorLevel% equ 0 (
    echo    * sfc.exe               [OK] BLOQUE
    set /a BLOCKED_COUNT+=1
) else (
    echo    * sfc.exe               [!] ACTIF
)

:: Check ReAgentc.exe
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ReAgentc.exe" /v Debugger >nul 2>&1
if %errorLevel% equ 0 (
    echo    * ReAgentc.exe          [OK] BLOQUE
    set /a BLOCKED_COUNT+=1
) else (
    echo    * ReAgentc.exe          [!] ACTIF
)

echo.
echo    Total executables bloques: %BLOCKED_COUNT%/7
echo.

:: =============================================
:: SECTION 5: SYSTEM RESTORE STATUS
:: =============================================
echo [5] RESTAURATION SYSTEME :
echo ------------------------------------------------------------
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableSR 2>nul
if %errorLevel% equ 0 (
    echo    * [OK] Restauration systeme desactivee par GPO
) else (
    echo    * [!] Restauration systeme ACTIVE
)
echo.
echo    Services VSS/SWPRV:
sc query VSS 2>nul | findstr "STATE"
sc query swprv 2>nul | findstr "STATE"
echo    (STOPPED ou DISABLED = securise)
echo.

:: =============================================
:: SECTION 6: SAFE MODE STATUS
:: =============================================
echo [6] MODE SANS ECHEC :
echo ------------------------------------------------------------
reg query "HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Minimal" /v AlternateShell 2>nul
echo    (Vide ou absent = bloque)
echo.

:: =============================================
:: SECTION 7: ADVANCED STARTUP STATUS
:: =============================================
echo [7] OPTIONS DE DEMARRAGE AVANCEES :
echo ------------------------------------------------------------
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableAdvancedStartup 2>nul
if %errorLevel% equ 0 (
    echo    * [OK] Shift+Restart BLOQUE
) else (
    echo    * [!] Shift+Restart ACTIF
)
echo.
bcdedit /enum {globalsettings} 2>nul | findstr /i "advancedoptions optionsedit"
echo    (false = securise)
echo.

:: =============================================
:: SECTION 8: UI VISIBILITY STATUS
:: =============================================
echo [8] MASQUAGE INTERFACE :
echo ------------------------------------------------------------
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility 2>nul
if %errorLevel% equ 0 (
    echo    * [OK] Pages Settings masquees
) else (
    echo    * [!] Pages Settings VISIBLES
)
echo.

:: =============================================
:: SECTION 9: USER PRIVILEGES STATUS
:: =============================================
echo [9] PRIVILEGES UTILISATEUR :
echo ------------------------------------------------------------

:: Detect Administrators group name (language-independent)
set "ADMIN_GROUP="
for /f "tokens=*" %%g in ('powershell -NoProfile -Command "(New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([System.Security.Principal.NTAccount]).Value.Split('\')[-1]"') do (
    set "ADMIN_GROUP=%%g"
)

set "CHECK_USER=%USERNAME%"
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "$u=(Get-WmiObject Win32_ComputerSystem).UserName; if($u){$u.Split('\')[1]}"`) do (
    if not "%%a"=="" set "CHECK_USER=%%a"
)

echo    Utilisateur actuel: [%CHECK_USER%]
if defined ADMIN_GROUP (
    net localgroup "!ADMIN_GROUP!" 2>nul | findstr /i /c:"%CHECK_USER%" >nul
) else (
    net localgroup Administrators 2>nul | findstr /i /c:"%CHECK_USER%" >nul
)
if %errorLevel% equ 0 (
    echo    * [!] ADMINISTRATEUR - Non restreint
) else (
    echo    * [OK] UTILISATEUR STANDARD - Restreint
)
echo.
echo    Compte Administrator integre:
net user Administrator 2>nul | findstr /i "active"

:: Check if Administrator is hidden from login screen (should be hidden, but visible in UAC)
set "ADMIN_HIDDEN=0"
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v Administrator 2>nul | findstr "0x0" >nul
if %errorLevel% equ 0 set "ADMIN_HIDDEN=1"
if "!ADMIN_HIDDEN!"=="1" (
    echo    * [OK] Administrator CACHE ecran login (visible UAC^)
) else (
    echo    * [!] Administrator VISIBLE partout
)
echo.

:: =============================================
:: SECTION 10: USER RESTRICTIONS STATUS
:: =============================================
echo [10] RESTRICTIONS UTILISATEUR (si UserLock actif) :
echo ------------------------------------------------------------

:: Control Panel
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel 2>nul >nul
if %errorLevel% equ 0 (
    echo    * Panneau de configuration    [OK] BLOQUE
) else (
    echo    * Panneau de configuration    [!] ACTIF
)

:: Registry
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools 2>nul >nul
if %errorLevel% equ 0 (
    echo    * Editeur de registre         [OK] BLOQUE
) else (
    echo    * Editeur de registre         [!] ACTIF
)

:: Task Manager
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr 2>nul >nul
if %errorLevel% equ 0 (
    echo    * Gestionnaire de taches      [OK] BLOQUE
) else (
    echo    * Gestionnaire de taches      [!] ACTIF
)

:: Run
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoRun 2>nul >nul
if %errorLevel% equ 0 (
    echo    * Boite Executer              [OK] BLOQUE
) else (
    echo    * Boite Executer              [!] ACTIF
)

:: Date/Time
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDateTimeControlPanel 2>nul >nul
if %errorLevel% equ 0 (
    echo    * Date/Heure                  [OK] BLOQUE
) else (
    echo    * Date/Heure                  [!] MODIFIABLE
)

:: Windows Script Host
reg query "HKCU\Software\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul >nul
if %errorLevel% equ 0 (
    echo    * Windows Script Host         [OK] DESACTIVE
) else (
    echo    * Windows Script Host         [!] ACTIF
)

:: AutoPlay
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun 2>nul >nul
if %errorLevel% equ 0 (
    echo    * AutoPlay/AutoRun            [OK] DESACTIVE
) else (
    echo    * AutoPlay/AutoRun            [!] ACTIF
)

echo.

:: =============================================
:: SECTION 11: DEVICE INSTALLATION STATUS
:: =============================================
echo [11] INSTALLATION PERIPHERIQUES :
echo ------------------------------------------------------------
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions" /v DenyAll 2>nul >nul
if %errorLevel% equ 0 (
    echo    * [OK] Installation materiel BLOQUEE
) else (
    echo    * [!] Installation materiel AUTORISEE
)
echo.

:: =============================================
:: SECTION 12: POWER/SLEEP STATUS
:: =============================================
echo [12] VEILLE / WAKE-ON-LAN :
echo ------------------------------------------------------------
echo    Hibernation:
powercfg /a 2>nul | findstr /i "Hibernate"
echo.
echo    Sleep timeouts (AC/DC):
powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 2>nul | findstr "Power Setting"
echo    (0x00000000 = Jamais = securise)
echo.
echo    Wake-on-LAN (cartes reseau):
powershell -NoProfile -Command "$a=Get-NetAdapter|Where{$_.Status -eq 'Up'}|Select -First 1; if($a){$wol=Get-NetAdapterPowerManagement -Name $a.Name -ErrorAction SilentlyContinue; if($wol.WakeOnMagicPacket -eq 'Enabled'){'    * [OK] Wake-on-LAN ACTIVE'}else{'    * [!] Wake-on-LAN DESACTIVE'}}else{'    * Aucune carte detectee'}"
echo.

:: =============================================
:: SECTION 13: WIFI PROTECTION (NOT HANDLED BY LOCKDOWN v3.0)
:: =============================================
echo [13] PROTECTION WIFI (NON GEREE PAR LOCKDOWN v3.0) :
echo ------------------------------------------------------------

:: Network Connections folder blocked
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetworkConnections 2>nul >nul
if %errorLevel% equ 0 (
    echo    * Dossier Connexions reseau   [OK] BLOQUE
) else (
    echo    * Dossier Connexions reseau   [!] ACCESSIBLE
)

echo.
echo    NOTE: Lockdown v3.0 ne gere plus les restrictions WiFi.
echo          Utilisez UserLock pour ces fonctionnalites.
echo.

:: =============================================
:: SECTION 14: SUMMARY
:: =============================================
echo ============================================================
echo                    RESUME DE SECURITE
echo ============================================================
echo.

:: Count protections
set "LOCKDOWN_SCORE=0"
set "USERLOCK_SCORE=0"

:: Lockdown checks
if not exist "C:\Windows\System32\Recovery\winre.wim" set /a LOCKDOWN_SCORE+=1
reg query "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start 2>nul | findstr "0x4" >nul && set /a LOCKDOWN_SCORE+=1
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\systemreset.exe" /v Debugger >nul 2>&1 && set /a LOCKDOWN_SCORE+=1
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableSR >nul 2>&1 && set /a LOCKDOWN_SCORE+=1
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableAdvancedStartup >nul 2>&1 && set /a LOCKDOWN_SCORE+=1

:: UserLock checks
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel >nul 2>&1 && set /a USERLOCK_SCORE+=1
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr >nul 2>&1 && set /a USERLOCK_SCORE+=1
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoRun >nul 2>&1 && set /a USERLOCK_SCORE+=1
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDateTimeControlPanel >nul 2>&1 && set /a USERLOCK_SCORE+=1

echo    LOCKDOWN Protection Score: %LOCKDOWN_SCORE%/5 (Focus: Reset prevention)
if %LOCKDOWN_SCORE% GEQ 4 (
    echo    -> SYSTEME BIEN PROTEGE contre la reinitialisation
) else if %LOCKDOWN_SCORE% GEQ 2 (
    echo    -> PROTECTION PARTIELLE
) else (
    echo    -> SYSTEME NON PROTEGE
)
echo.
echo    USERLOCK Restriction Score: %USERLOCK_SCORE%/4
if %USERLOCK_SCORE% GEQ 3 (
    echo    -> UTILISATEUR BIEN RESTREINT
) else if %USERLOCK_SCORE% GEQ 1 (
    echo    -> UTILISATEUR PARTIELLEMENT RESTREINT
) else (
    echo    -> UTILISATEUR NON RESTREINT
)
echo.
echo ============================================================
echo    NOTE: Pour une securite complete, configurez un mot de
echo          passe BIOS/UEFI manuellement sur la machine.
echo ============================================================
echo.
if "%AUTO_YES%"=="1" (echo [AUTO] Verification terminee.) else (pause)
