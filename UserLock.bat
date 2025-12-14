@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: USERLOCK.BAT - Advanced User Privilege Lockdown
:: Version 2.5 - Enhanced Error Handling & Safety Checks
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
echo     USER PRIVILEGE LOCKDOWN v2.5
echo ==========================================
echo.

:: =============================================
:: SECTION 0: DETECT GROUP NAMES (Language-Independent)
:: =============================================
echo Detection des groupes systeme...

:: Get the actual name of the Administrators group using SID (works in ALL languages)
set "ADMIN_GROUP="
for /f "tokens=*" %%g in ('powershell -NoProfile -Command "(New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([System.Security.Principal.NTAccount]).Value.Split('\')[-1]"') do (
    set "ADMIN_GROUP=%%g"
)

:: Get the actual name of the Users group using SID
set "USERS_GROUP="
for /f "tokens=*" %%g in ('powershell -NoProfile -Command "(New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-545')).Translate([System.Security.Principal.NTAccount]).Value.Split('\')[-1]"') do (
    set "USERS_GROUP=%%g"
)

if "!ADMIN_GROUP!"=="" (
    echo [ERREUR] Impossible de detecter le groupe Administrateurs.
    pause
    exit /b
)
echo    * Groupe admin: [!ADMIN_GROUP!]
echo    * Groupe users: [!USERS_GROUP!]
echo.

:: =============================================
:: SECTION 0B: DETECT TARGET USER
:: =============================================
echo Detection de l'utilisateur cible...

:: Method 1: Check explorer.exe owner (most reliable for detecting real user)
set "TARGET_USER="
for /f "tokens=*" %%u in ('powershell -NoProfile -Command "$p = Get-Process explorer -ErrorAction SilentlyContinue ^| Select-Object -First 1; if($p){$proc = Get-CimInstance Win32_Process ^| Where-Object {$_.ProcessId -eq $p.Id}; if($proc){$owner = Invoke-CimMethod -InputObject $proc -MethodName GetOwner; $owner.User}}"') do (
    if not "%%u"=="" if /i not "%%u"=="Administrator" if /i not "%%u"=="Administrateur" set "TARGET_USER=%%u"
)

:: Method 2: If no explorer, get first non-system local user
if not defined TARGET_USER (
    for /f "tokens=*" %%u in ('powershell -NoProfile -Command "$users = Get-LocalUser ^| Where-Object {$_.Enabled -and $_.Name -notmatch 'Administrator^|Guest^|DefaultAccount^|WDAGUtilityAccount^|Support'}; if($users){($users ^| Select-Object -First 1).Name}"') do (
        if not "%%u"=="" set "TARGET_USER=%%u"
    )
)

if not defined TARGET_USER (
    echo [ERREUR] Aucun utilisateur cible trouve.
    pause
    exit /b
)

echo Utilisateur detecte: [!TARGET_USER!]

:: Get the SID of target user for registry operations
set "TARGET_SID="
for /f "tokens=*" %%s in ('powershell -NoProfile -Command "$u = Get-LocalUser -Name '!TARGET_USER!' -ErrorAction SilentlyContinue; if($u){$u.SID.Value}"') do (
    set "TARGET_SID=%%s"
)
echo    * SID: !TARGET_SID!
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

:: Verify Administrator is truly active
net user Administrator | findstr /i "active" | findstr /i "Yes" >nul 2>&1
if %errorLevel% neq 0 (
    echo    * ERREUR CRITIQUE: Administrator n'est pas actif.
    echo    * Impossible de continuer sans compte admin de secours.
    pause
    exit /b
)

:: HIDE Administrator from LOGIN SCREEN ONLY (still visible in UAC!)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v Administrator /t REG_DWORD /d 0 /f >nul 2>&1

echo    * Administrator active, CACHE de l'ecran login.
echo    * VISIBLE dans UAC (entrez mdp: %ADMIN_PASS%).
echo    * Utilisez le Lanceur Admin pour lancer des apps.

:: =============================================
:: SECTION 3B: CREATE HIDDEN INSTALLER ACCOUNT (if install allowed)
:: =============================================
if "%ALLOW_INSTALL%"=="1" (
    echo.
    echo [1b] Creation du compte Installateur cache...
    
    :: Create a hidden admin account named "Support" with user's password
    net user Support "%USER_PASS%" /add >nul 2>&1
    net user Support /active:yes >nul 2>&1
    
    :: Add to Administrators group (using detected group name)
    net localgroup "!ADMIN_GROUP!" Support /add >nul 2>&1
    
    :: HIDE Support from LOGIN SCREEN ONLY (still visible in UAC!)
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v Support /t REG_DWORD /d 0 /f >nul 2>&1
    
    echo    * Compte "Support" cree, CACHE de l'ecran login.
    echo    * VISIBLE dans UAC (meme mot de passe que !TARGET_USER!).
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
echo [3] Retrogradation de [!TARGET_USER!] en utilisateur standard...

:: Add to Users group (using detected group name)
net localgroup "!USERS_GROUP!" "!TARGET_USER!" /add >nul 2>&1
echo    * Ajoute au groupe !USERS_GROUP!.

:: Remove from Administrators (using detected group name)
net localgroup "!ADMIN_GROUP!" "!TARGET_USER!" /delete >nul 2>&1

:: Verify removal using PowerShell (language-independent)
set "IS_ADMIN=0"
for /f "tokens=*" %%r in ('powershell -NoProfile -Command "$members = net localgroup '!ADMIN_GROUP!' 2^>$null; if($members -match '!TARGET_USER!'){'YES'}else{'NO'}"') do (
    if /i "%%r"=="YES" set "IS_ADMIN=1"
)

if "!IS_ADMIN!"=="0" (
    echo    * Succes. !TARGET_USER! est maintenant utilisateur standard.
) else (
    echo    * ERREUR CRITIQUE: Impossible de retirer du groupe !ADMIN_GROUP!.
    echo.
    echo    * Le script va s'arreter pour eviter un etat incoherent.
    echo    * Verifiez que le compte Administrator est actif:
    echo      net user Administrator
    pause
    exit /b
)

:: =============================================
:: SECTION 5: RESTRICT SYSTEM ACCESS FOR TARGET USER
:: =============================================
echo.
echo [4] Application des restrictions systeme a [!TARGET_USER!]...

:: Check if target user's registry is already loaded in HKU
set "REG_ROOT=HKU\!TARGET_SID!"
reg query "!REG_ROOT!" >nul 2>&1
if errorlevel 1 (
    :: User not logged in, need to load NTUSER.DAT
    set "NTUSER_PATH="
    for /f "tokens=*" %%p in ('powershell -NoProfile -Command "$prof = Get-WmiObject Win32_UserProfile ^| Where-Object {$_.SID -eq '!TARGET_SID!'}; if($prof){$prof.LocalPath}"') do (
        set "NTUSER_PATH=%%p\NTUSER.DAT"
    )
    if exist "!NTUSER_PATH!" (
        reg load "HKU\!TARGET_SID!" "!NTUSER_PATH!" >nul 2>&1
        if not errorlevel 1 (
            set "USER_REG_LOADED=1"
            echo    * Registre utilisateur charge depuis !NTUSER_PATH!
        ) else (
            echo    * ERREUR: Impossible de charger le registre utilisateur.
            echo    * Les restrictions ne seront PAS appliquees correctement.
            echo.
            echo    * Causes possibles:
            echo      - Le registre est deja charge sous un autre SID
            echo      - Le fichier NTUSER.DAT est corrompu
            echo      - Droits insuffisants
            echo.
            pause
            exit /b
        )
    ) else (
        echo    * ERREUR: NTUSER.DAT introuvable a !NTUSER_PATH!
        echo    * Impossible d'appliquer les restrictions utilisateur.
        echo.
        pause
        exit /b
    )
) else (
    set "USER_REG_LOADED=0"
    echo    * Utilisateur connecte, acces direct a HKU\!TARGET_SID!
)

echo    * Cible registre: !REG_ROOT!

:: 5.1 Block Control Panel access
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Panneau de configuration bloque.

:: 5.2 Block Registry Editor
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Editeur de registre bloque.

:: 5.3 Block Task Manager
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Gestionnaire de taches bloque.

:: NOTE: CMD and PowerShell are NOT blocked - they cannot do admin tasks anyway without elevation

:: 5.4 Block Run dialog
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoRun /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Boite Executer bloquee.

:: 5.5 Block access to Settings app (specific pages only)
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /t REG_SZ /d "hide:recovery;backup;windowsupdate-options;accounts-yourinfo;accounts-email;accounts-signin;accounts-workplace;accounts-otherpeoplesonline" /f >nul 2>&1
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
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetHood /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Voisinage reseau masque.

:: 7.2 Block access to network settings
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetworkConnections /t REG_DWORD /d 1 /f >nul 2>&1
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
reg add "!REG_ROOT!\Software\Policies\Microsoft\MMC\{74246bfc-4c96-11d0-abef-0020af6b0b7a}" /v Restrict_Run /t REG_DWORD /d 1 /f >nul 2>&1
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
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDateTimeControlPanel /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Modification date/heure bloquee.

:: 10.2 Disable Developer Mode
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowAllTrustedApps /t REG_DWORD /d 0 /f >nul 2>&1
echo    * Mode developpeur desactive.

:: 10.3 Block access to Environment Variables
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoPropertiesMyComputer /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Proprietes systeme bloquees.

:: 10.4 Disable AutoPlay/AutoRun (security)
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f >nul 2>&1
echo    * AutoPlay/AutoRun desactive.

:: 10.5 Block Windows Script Host (prevents .vbs, .js malware)
reg add "!REG_ROOT!\Software\Microsoft\Windows Script Host\Settings" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
echo    * Windows Script Host desactive.

:: 10.6 Disable Remote Desktop for this user
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Bureau a distance desactive.

:: 10.7 Block screensaver changes
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v NoDispScrSavPage /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Modification ecran de veille bloquee.

:: 10.8 Block desktop background changes
reg add "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /t REG_DWORD /d 1 /f >nul 2>&1
echo    * Modification fond d'ecran bloquee.

:: Unload the registry hive if we loaded it
if "!USER_REG_LOADED!"=="1" (
    reg unload "HKU\!TARGET_SID!" >nul 2>&1
    echo    * Registre utilisateur decharge.
)

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
icacls "%NOWIN_DIR%" /deny "!USERS_GROUP!:(DE)" >nul 2>&1
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
echo     USER LOCKDOWN TERMINE (v2.5)
echo ==========================================
echo.
echo Utilisateur [!TARGET_USER!] - Restrictions appliquees:
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
echo    COMPTES ADMINISTRATEUR (CACHES ECRAN LOGIN)
echo ==========================================
echo.
echo  Compte: Administrator
echo    - CACHE de l'ecran de connexion
echo    - VISIBLE dans les popups UAC
echo    - Accessible via Lanceur Admin (mot de passe en console)
echo    - Mdp: %ADMIN_PASS%
if "%ALLOW_INSTALL%"=="1" (
echo.
echo  Compte: Support
echo    - CACHE de l'ecran de connexion  
echo    - VISIBLE dans les popups UAC
echo    - L'utilisateur peut installer avec SON mot de passe
)
echo.
echo ==========================================
echo.
echo COMMENT UTILISER:
echo  1. Lanceur Admin (bureau) = mot de passe en console
echo  2. Popup UAC = selectionnez Administrator, mdp: %ADMIN_PASS%
echo  3. Console: runas /user:Administrator cmd
echo.
echo ==========================================
echo    IMPORTANT: DECONNEXION REQUISE
echo ==========================================
echo.
echo Les changements de groupe necessitent une deconnexion
echo pour prendre effet completement.
echo.
echo Appuyez sur une touche pour vous deconnecter...
pause >nul

:: Final verification before logout
echo.
echo Verification finale...
net user Administrator | findstr /i "active" | findstr /i "Yes" >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [ERREUR CRITIQUE] Administrator n'est PAS actif!
    echo Vous allez etre deconnecte SANS compte admin de secours.
    echo.
    echo ANNULATION de la deconnexion.
    echo Utilisez UserUnlock.bat pour restaurer les droits.
    pause
    exit /b
)

echo    * Administrator verifie: ACTIF
echo    * Deconnexion securisee...
shutdown /l
