@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: USERLOCK.BAT - Advanced User Privilege Lockdown
:: Version 2.3 - Hidden Support Account
:: ============================================
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" 2>nul
    if !errorLevel! neq 0 (
        echo ERROR: Administrator privileges required.
        pause
    )
    exit /b
)

echo ==========================================
echo     USER PRIVILEGE LOCKDOWN v2.3
echo ==========================================
echo.

:: =============================================
:: SECTION 0: DETECT USER
:: =============================================
set "TARGET_USER=%USERNAME%"
echo Utilisateur detecte: [%TARGET_USER%]
echo.

:: =============================================
:: SECTION 1: ASK ABOUT APP INSTALLATION
:: =============================================
echo ==========================================
echo    OPTION: INSTALLATION D'APPLICATIONS
echo ==========================================
echo.
echo [O] OUI = BLOQUER l'installation (plus securise)
echo     -> Toute demande d'elevation sera REFUSEE automatiquement
echo.
echo [N] NON = AUTORISER l'installation
echo     -> Un compte admin cache sera cree avec le MEME mot de passe
echo     -> L'utilisateur pourra installer sans connaitre le mdp admin
echo.
set "ALLOW_INSTALL=0"
set /p "INSTALL_CHOICE=Bloquer l'installation d'applications ? (O/N): "
if /i "%INSTALL_CHOICE%"=="N" set "ALLOW_INSTALL=1"
echo.

:: =============================================
:: SECTION 2: GET USER PASSWORD (if install allowed)
:: =============================================
set "USER_PASS="
if "%ALLOW_INSTALL%"=="1" (
    echo ==========================================
    echo    MOT DE PASSE UTILISATEUR
    echo ==========================================
    echo.
    echo Pour permettre l'installation, entrez le mot de passe
    echo actuel de [%TARGET_USER%].
    echo.
    echo Ce mot de passe sera utilise pour creer un compte admin cache.
    echo L'utilisateur pourra installer des apps avec SON mot de passe.
    echo.
    set /p "USER_PASS=Mot de passe de %TARGET_USER%: "
    echo.
)

:: =============================================
:: SECTION 3: ENABLE BUILT-IN ADMINISTRATOR
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
echo    * Administrator active (cache). Mot de passe: %ADMIN_PASS%

:: =============================================
:: SECTION 3B: CREATE HIDDEN INSTALLER ACCOUNT (if install allowed)
:: =============================================
if "%ALLOW_INSTALL%"=="1" (
    echo.
    echo [1b] Creation du compte Installateur cache...
    
    :: Create a hidden admin account named "Support" with user's password
    net user Support "%USER_PASS%" /add >nul 2>&1
    net user Support /active:yes >nul 2>&1
    
    :: Add to Administrators group (English and French)
    net localgroup Administrators Support /add >nul 2>&1
    net localgroup Administrateurs Support /add >nul 2>&1
    
    :: Hide from login screen
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v Support /t REG_DWORD /d 0 /f >nul 2>&1
    
    echo    * Compte "Support" cree ^(cache^) avec le meme mot de passe.
    echo    * L'utilisateur peut installer en selectionnant "Support" dans l'UAC.
)

:: =============================================
:: SECTION 4: CONFIGURE UAC SETTINGS
:: =============================================
echo.
echo [2] Configuration UAC...

:: Force UAC to list admins (so admin accounts appear in UAC prompt)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI" /v EnumerateAdministrators /t REG_DWORD /d 1 /f >nul 2>&1

:: Require elevation for all admin operations (always prompt)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 1 /f >nul 2>&1

:: ALWAYS allow admin credential prompt (so AdminLauncher works)
:: The difference is: with Support account = user knows password, without = only admin knows "uyy"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser /t REG_DWORD /d 1 /f >nul 2>&1

if "%ALLOW_INSTALL%"=="1" (
    echo    * UAC: L'utilisateur verra "Support" et entrera SON mot de passe.
) else (
    echo    * UAC: L'utilisateur devra connaitre le mdp "Administrator" (uyy).
    echo    * Le Lanceur Admin permet de lancer les apps bloquees.
)

:: Enable UAC (ensure it's on)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1

:: =============================================
:: SECTION 5: DEMOTE USER TO STANDARD
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
:: SECTION 11: INSTALL ADMIN LAUNCHER
:: =============================================
echo.
echo [10] Installation du Lanceur Admin...

:: Create NoWin folder in Program Files (protected location)
set "NOWIN_DIR=C:\Program Files\NoWin"
if not exist "%NOWIN_DIR%" mkdir "%NOWIN_DIR%" >nul 2>&1

:: Download AdminLauncher.bat
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/AdminLauncher.bat' -OutFile '%NOWIN_DIR%\AdminLauncher.bat'" >nul 2>&1
if exist "%NOWIN_DIR%\AdminLauncher.bat" (
    echo    * AdminLauncher.bat installe dans Program Files.
) else (
    echo    * ERREUR: Impossible de telecharger AdminLauncher.bat
)

:: Download icon if available
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/logo.ico' -OutFile '%NOWIN_DIR%\logo.ico'" >nul 2>&1

:: Create desktop shortcut for all users
set "SHORTCUT_PATH=C:\Users\Public\Desktop\Lanceur Admin.lnk"
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = '%NOWIN_DIR%\AdminLauncher.bat'; $s.WorkingDirectory = '%NOWIN_DIR%'; $s.Description = 'Lanceur Admin - NoWin'; if(Test-Path '%NOWIN_DIR%\logo.ico'){$s.IconLocation = '%NOWIN_DIR%\logo.ico'}; $s.Save()" >nul 2>&1

:: Make shortcut read-only and system (harder to delete)
attrib +r +s "%SHORTCUT_PATH%" >nul 2>&1

if exist "%SHORTCUT_PATH%" (
    echo    * Raccourci cree sur le bureau public.
) else (
    echo    * ATTENTION: Raccourci non cree.
)

:: Protect the NoWin folder (deny delete for Users)
icacls "%NOWIN_DIR%" /deny "Users:(DE)" >nul 2>&1
icacls "%NOWIN_DIR%" /deny "Utilisateurs:(DE)" >nul 2>&1
echo    * Dossier NoWin protege contre la suppression.

:: =============================================
:: SECTION 12: RESTRICT BOOT OPTIONS
:: =============================================
echo.
echo [11] Restriction options de demarrage...

:: Block F8/boot menu access
bcdedit /set {current} bootmenupolicy Standard >nul 2>&1
bcdedit /timeout 0 >nul 2>&1
echo    * Menu boot restreint.

:: =============================================
:: SECTION 13: FINAL OUTPUT
:: =============================================
echo.
echo ==========================================
echo     USER LOCKDOWN TERMINE (v2.3)
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
echo  [+] Lanceur Admin installe sur le bureau
if "%ALLOW_INSTALL%"=="1" (
echo  [ ] Installation: AUTORISEE via compte "Support"
) else (
echo  [X] Installation: BLOQUEE
)
echo.
echo ==========================================
echo    COMPTES ADMINISTRATEUR
echo ==========================================
echo.
echo  Compte: Administrator
echo  Mdp: %ADMIN_PASS%
if "%ALLOW_INSTALL%"=="1" (
echo.
echo  Compte: Support (pour installation)
echo  Mdp: [meme que %TARGET_USER%]
)
echo.
echo ==========================================
echo.
echo Le "Lanceur Admin" sur le bureau permet d'ouvrir
echo les applications bloquees avec le mot de passe admin.
echo.
echo Deconnexion dans 10 secondes...
timeout /t 10
shutdown /l
