@echo off
:: ============================================
:: USERLOCK.BAT - Advanced User Privilege Lockdown
:: Version 2.2 - Enhanced Restrictions
:: ============================================
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ==========================================
echo     USER PRIVILEGE LOCKDOWN v2.2
echo ==========================================
echo.

:: =============================================
:: SECTION 0: CONFIRMATION
:: =============================================
set "TARGET_USER=%USERNAME%"
echo Utilisateur detecte: [%TARGET_USER%]
echo.
echo Ce script va:
echo  - Activer le compte Administrator integre (mdp: uyy)
echo  - Retrograder [%TARGET_USER%] en utilisateur standard
echo  - Appliquer des restrictions systeme
echo.
echo ==========================================
echo.
set /p "CONFIRM=Voulez-vous continuer ? (O/N): "
if /i "%CONFIRM%" neq "O" (
    if /i "%CONFIRM%" neq "Y" (
        echo Operation annulee.
        pause
        exit /b
    )
)

:: =============================================
:: SECTION 1: ASK ABOUT APP INSTALLATION
:: =============================================
echo.
echo ==========================================
echo    OPTION: INSTALLATION D'APPLICATIONS
echo ==========================================
echo.
echo L'utilisateur [%TARGET_USER%] ne sera PAS administrateur.
echo.
echo Si vous repondez OUI:
echo  - L'utilisateur POURRA installer des applications
echo  - Il devra entrer le mot de passe ADMIN (uyy) lors de l'UAC
echo  - Il n'aura AUCUN droit admin en dehors de ca
echo.
echo Si vous repondez NON:
echo  - L'utilisateur ne pourra PAS installer d'applications
echo  - Toute demande d'elevation sera automatiquement refusee
echo.
set "ALLOW_INSTALL=0"
set /p "INSTALL_CHOICE=Autoriser l'installation d'apps (avec mdp admin) ? (O/N): "
if /i "%INSTALL_CHOICE%"=="O" set "ALLOW_INSTALL=1"
if /i "%INSTALL_CHOICE%"=="Y" set "ALLOW_INSTALL=1"
echo.

:: =============================================
:: SECTION 2: ENABLE BUILT-IN ADMINISTRATOR
:: =============================================
echo [1] Activation du compte Administrator...

:: Fixed password as requested
set "ADMIN_PASS=uyy"

net user Administrator "%ADMIN_PASS%" /active:yes >nul 2>&1
if %errorLevel% neq 0 (
    echo    * ECHEC activation du compte Administrator. Abandon.
    pause
    exit /b
)
echo    * Administrator active. Mot de passe: %ADMIN_PASS%

:: =============================================
:: SECTION 3: CONFIGURE UAC SETTINGS
:: =============================================
echo.
echo [2] Configuration UAC...

:: Force UAC to list admins
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI" /v EnumerateAdministrators /t REG_DWORD /d 1 /f >nul 2>&1

:: Require elevation for all admin operations (always prompt)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 1 /f >nul 2>&1

:: Behavior for standard users based on install choice
if "%ALLOW_INSTALL%"=="1" (
    :: Allow standard users to be prompted for admin credentials (they enter ADMIN password)
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser /t REG_DWORD /d 1 /f >nul 2>&1
    echo    * UAC: Boite de dialogue avec demande de mot de passe admin.
) else (
    :: Automatically deny elevation for standard users (no prompt)
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser /t REG_DWORD /d 0 /f >nul 2>&1
    echo    * UAC: Elevation automatiquement refusee.
)

:: Enable UAC (ensure it's on)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1

:: =============================================
:: SECTION 4: DEMOTE USER TO STANDARD
:: =============================================
echo.
echo [3] Demoting user [%TARGET_USER%] to Standard User...

:: Add to Users group first (English and French)
set "ADDED_TO_USERS=0"
net localgroup Users "%TARGET_USER%" /add >nul 2>&1
if %errorLevel% equ 0 set "ADDED_TO_USERS=1"
net localgroup Utilisateurs "%TARGET_USER%" /add >nul 2>&1
if %errorLevel% equ 0 set "ADDED_TO_USERS=1"

if "%ADDED_TO_USERS%"=="1" (
    echo    * User added to Users/Utilisateurs group.
) else (
    echo    * WARNING: Could not add to Users group. May already be a member.
)

:: Remove from Administrators (English and French)
net localgroup Administrators "%TARGET_USER%" /delete >nul 2>&1
net localgroup Administrateurs "%TARGET_USER%" /delete >nul 2>&1

:: Verify removal
set "IS_ADMIN=0"
net user "%TARGET_USER%" | findstr /i "Administrators Administrateurs" >nul
if %errorLevel% equ 0 set "IS_ADMIN=1"

if "%IS_ADMIN%"=="0" (
    echo    * Success. %TARGET_USER% is now a Standard User.
) else (
    echo    * ERROR: Could not remove user from Administrators group.
)

:: =============================================
:: SECTION 5: RESTRICT SYSTEM ACCESS FOR STANDARD USERS
:: =============================================
echo.
echo [4] Application des restrictions systeme...

:: 5.1 Block Control Panel access (standard users)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Panneau de configuration bloque.

:: 5.2 Block Registry Editor
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Editeur de registre bloque.

:: 5.3 Block Task Manager
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Gestionnaire de taches bloque.

:: NOTE: CMD and PowerShell are NOT blocked - they cannot do admin tasks anyway without elevation

:: 5.4 Block Run dialog
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoRun /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Boite Executer bloquee.

:: 5.5 Block access to Settings app (specific pages only)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /t REG_SZ /d "hide:recovery;backup;windowsupdate-options;accounts-yourinfo;accounts-email;accounts-signin;accounts-workplace;accounts-otherpeoplesonline" /f >nul 2>&1
echo    * Pages Settings sensibles masquees.

:: =============================================
:: SECTION 6: SOFTWARE INSTALLATION POLICY
:: =============================================
echo.
echo [5] Configuration installation logiciels...

if "%ALLOW_INSTALL%"=="1" (
    :: Allow software installation with admin password
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated /t REG_DWORD /d 0 /f >nul 2>&1
    echo    * Installation autorisee (avec mot de passe admin^).
) else (
    :: Block Windows Installer for standard users
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated /t REG_DWORD /d 0 /f >nul 2>&1
    echo    * Installation MSI bloquee.
)

:: =============================================
:: SECTION 7: NETWORK RESTRICTIONS
:: =============================================
echo.
echo [6] Restrictions reseau...

:: 7.1 Disable network sharing
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetHood /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Voisinage reseau masque.

:: 7.2 Block access to network settings
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetworkConnections /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Parametres reseau bloques.

:: =============================================
:: SECTION 8: DEVICE RESTRICTIONS
:: =============================================
echo.
echo [7] Restrictions peripheriques...

:: 8.1 Block adding new hardware (only if install not allowed)
if "%ALLOW_INSTALL%"=="0" (
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions" /v DenyAll /t REG_DWORD /d 1 /f >nul 2>&1
    echo    * Installation materiel bloquee.
) else (
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions" /v DenyAll /f >nul 2>&1
    echo    * Installation materiel autorisee.
)

:: 8.2 Block Device Manager access
reg add "HKCU\Software\Policies\Microsoft\MMC\{74246bfc-4c96-11d0-abef-0020af6b0b7a}" /v Restrict_Run /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Gestionnaire de peripheriques bloque.

:: =============================================
:: SECTION 9: AUDIT & LOGGING
:: =============================================
echo.
echo [8] Activation audit securite...

:: Enable logon/logoff auditing
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable >nul 2>&1
:: Enable privilege use auditing
auditpol /set /category:"Privilege Use" /success:enable /failure:enable >nul 2>&1
:: Enable object access auditing
auditpol /set /category:"Object Access" /success:enable /failure:enable >nul 2>&1
echo    * Audit securite active.

:: =============================================
:: SECTION 10: ADDITIONAL SECURITY
:: =============================================
echo.
echo [9] Securite supplementaire...

:: 10.1 Block date/time changes
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDateTimeControlPanel /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Modification date/heure bloquee.

:: 10.2 Disable Developer Mode
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowAllTrustedApps /t REG_DWORD /d 0 /f >nul 2>&1
echo    * Mode developpeur desactive.

:: 10.3 Block access to Environment Variables
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoPropertiesMyComputer /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Proprietes systeme bloquees.

:: 10.4 Disable AutoPlay/AutoRun (security)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f >nul 2>&1
echo    * AutoPlay/AutoRun desactive.

:: 10.5 Block Windows Script Host (prevents .vbs, .js malware)
reg add "HKCU\Software\Microsoft\Windows Script Host\Settings" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
echo    * Windows Script Host desactive.

:: 10.6 Disable Remote Desktop for this user
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Bureau a distance desactive.

:: 10.7 Block screensaver changes
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v NoDispScrSavPage /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Modification ecran de veille bloquee.

:: 10.8 Block desktop background changes
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Modification fond d'ecran bloquee.

:: =============================================
:: SECTION 11: RESTRICT BOOT OPTIONS
:: =============================================
echo.
echo [10] Restriction options de demarrage...

:: Block F8/boot menu access
bcdedit /set {current} bootmenupolicy Standard >nul 2>&1
bcdedit /timeout 0 >nul 2>&1
echo    * Menu boot restreint.

:: =============================================
:: SECTION 12: FINAL OUTPUT
:: =============================================
echo.
echo ==========================================
echo     USER LOCKDOWN TERMINE (v2.2)
echo ==========================================
echo.
echo Utilisateur [%TARGET_USER%] - Restrictions appliquees:
echo  [X] Retrograde en utilisateur standard
echo  [X] Panneau de configuration bloque
echo  [X] Editeur de registre bloque
echo  [X] Gestionnaire de taches bloque
echo  [X] Boite Executer bloquee
echo  [X] Pages Settings sensibles masquees
echo  [X] Parametres reseau bloques
echo  [X] Date/heure bloquee
echo  [X] Mode developpeur desactive
echo  [X] AutoPlay/AutoRun desactive
echo  [X] Windows Script Host desactive
if "%ALLOW_INSTALL%"=="1" (
echo  [ ] Installation: AUTORISEE (mot de passe admin requis^)
) else (
echo  [X] Installation: BLOQUEE
)
echo.
echo Compte admin: Administrator
echo Mot de passe: %ADMIN_PASS%
echo.
echo Deconnexion dans 5 secondes...
timeout /t 5
shutdown /l
