@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: USERUNLOCK.BAT - Complete User Privilege Restore
:: Version 2.5 - Matches UserLock v2.5
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

echo ==========================================
echo     USER PRIVILEGE RESTORE v2.5
echo ==========================================
echo.

if "%AUTO_YES%"=="1" goto confirm_done
echo ==========================================
echo.
choice /c on /n /m "Continuer? (o/n): "
if errorlevel 2 (
    echo.
    echo [ANNULE] Operation annulee par l'utilisateur.
    echo.
    pause
    exit /b 1
)
echo.
:confirm_done

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
    if "%AUTO_YES%"=="1" (timeout /t 2 /nobreak >nul) else (pause)
    exit /b
)
echo    * Groupe admin: [!ADMIN_GROUP!]
echo    * Groupe users: [!USERS_GROUP!]
echo.

:: =============================================
:: SECTION 1: IDENTIFY TARGET USER
:: =============================================
echo Detection de l'utilisateur a restaurer...
echo.

:: Method 1: Get ALL standard users (not admins)
set "TARGET_USER="
set "FOUND_USERS=0"

for /f "usebackq tokens=*" %%u in (`powershell -NoProfile -Command "Get-LocalUser | Where-Object {$_.Enabled -eq $true -and $_.Name -notmatch '^(Administrator|Administrateur|Guest|DefaultAccount|WDAGUtilityAccount|Support)$'} | ForEach-Object { $user = $_.Name; $isAdmin = (Get-LocalGroupMember -Group '!ADMIN_GROUP!' -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*\' + $user }).Count -gt 0; if(-not $isAdmin) { $user } }"`) do (
    if not defined TARGET_USER set "TARGET_USER=%%u"
    set /a FOUND_USERS+=1
)

:: Fallback: If ALL users are admins, pick first non-system user anyway
if not defined TARGET_USER (
    for /f "usebackq tokens=*" %%u in (`powershell -NoProfile -Command "Get-LocalUser | Where-Object {$_.Enabled -eq $true -and $_.Name -notmatch '^(Administrator|Administrateur|Guest|DefaultAccount|WDAGUtilityAccount|Support)$'} | Select-Object -First 1 -ExpandProperty Name"`) do (
        set "TARGET_USER=%%u"
    )
)

if not defined TARGET_USER (
    echo [ERREUR] Aucun utilisateur a restaurer trouve.
    echo Seuls des comptes systeme existent (Administrator, Guest, etc.).
    if "%AUTO_YES%"=="1" (timeout /t 2 /nobreak >nul) else (pause)
    exit /b
)

:: Get the SID of target user for registry operations
set "TARGET_SID="
for /f "usebackq tokens=*" %%s in (`powershell -NoProfile -Command "(Get-LocalUser -Name '!TARGET_USER!' -ErrorAction SilentlyContinue).SID.Value"`) do (
    set "TARGET_SID=%%s"
)

echo Utilisateur detecte: [!TARGET_USER!]
if defined TARGET_SID echo    * SID: !TARGET_SID!

:: Check if user is already admin
net localgroup "!ADMIN_GROUP!" 2>nul | findstr /i /c:"!TARGET_USER!" >nul
if %errorLevel% equ 0 (
    echo    * Statut: Deja ADMINISTRATEUR
) else (
    echo    * Statut: Utilisateur standard
)

echo.
echo Ce script va:
echo  1. Supprimer TOUTES les restrictions de [!TARGET_USER!]
echo  2. Restaurer les droits Administrateur a [!TARGET_USER!]
echo  3. DESACTIVER et RENDRE VISIBLE le compte 'Administrator'
echo.

if "%AUTO_YES%"=="1" (
    echo [AUTO] Restauration de [!TARGET_USER!]...
    goto :CONTINUE_RESTORE
)

:ASK_CONFIRM
set /p "CONFIRM=[!TARGET_USER!] est le bon utilisateur a restaurer ? (O/N): "
if /i "%CONFIRM%"=="N" (
    echo.
    echo Liste de TOUS les utilisateurs locaux:
    echo =====================================
    set "USER_COUNT=0"
    for /f "skip=4 tokens=1" %%u in ('net user 2^>nul') do (
        if not "%%u"=="The" if not "%%u"=="---" if not "%%u"=="" (
            set /a USER_COUNT+=1
            echo   [!USER_COUNT!] %%u
            set "USER_!USER_COUNT!=%%u"
        )
    )
    echo.
    set /p "USER_CHOICE=Entrez le numero de l'utilisateur (1-!USER_COUNT!): "
    
    :: Validate and set target user
    if defined USER_!USER_CHOICE! (
        for /f "tokens=*" %%a in ("!USER_%USER_CHOICE%!") do set "TARGET_USER=%%a"
        echo.
        echo Utilisateur selectionne: [!TARGET_USER!]
        echo.
    ) else (
        echo Choix invalide, utilisation de [%TARGET_USER%]
    )
    goto :PROCEED
)
if /i "%CONFIRM%" neq "O" (
    if /i "%CONFIRM%" neq "Y" goto :ASK_CONFIRM
)

:PROCEED
:CONTINUE_RESTORE

:: =============================================
:: SECTION 2: RESTORE SYSTEM ACCESS FOR TARGET USER
:: =============================================
echo.
echo [1] Suppression des restrictions systeme pour [!TARGET_USER!]...

:: Check if target user's registry is already loaded in HKU
set "REG_ROOT=HKU\!TARGET_SID!"
set "USER_REG_LOADED=0"

if defined TARGET_SID (
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
                echo    * ATTENTION: Impossible de charger le registre.
                set "REG_ROOT=HKCU"
            )
        ) else (
            echo    * ATTENTION: NTUSER.DAT introuvable.
            set "REG_ROOT=HKCU"
        )
    ) else (
        echo    * Utilisateur connecte, acces direct a HKU\!TARGET_SID!
    )
) else (
    set "REG_ROOT=HKCU"
)

echo    * Cible registre: !REG_ROOT!

:: 2.1 Remove Control Panel block
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /f >nul 2>&1
echo    * Panneau de configuration debloque.

:: 2.2 Remove Registry Editor block
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /f >nul 2>&1
echo    * Editeur de registre debloque.

:: 2.3 Remove Task Manager block
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /f >nul 2>&1
echo    * Gestionnaire de taches debloque.

:: 2.4 Remove Run dialog block
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoRun /f >nul 2>&1
echo    * Boite Executer debloquee.

:: 2.5 Remove drive hiding
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDrives /f >nul 2>&1
echo    * Lecteurs visibles.

:: 2.6 Remove Settings app restrictions
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f >nul 2>&1
echo    * Application Settings debloquee.

:: 2.7 Remove date/time block
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDateTimeControlPanel /f >nul 2>&1
echo    * Date/heure debloquee.

:: 2.8 Re-enable Developer Mode access
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowAllTrustedApps /f >nul 2>&1
echo    * Mode developpeur accessible.

:: 2.9 Remove system properties block
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoPropertiesMyComputer /f >nul 2>&1
echo    * Proprietes systeme debloquees.

:: 2.10 Re-enable AutoPlay/AutoRun
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /f >nul 2>&1
echo    * AutoPlay/AutoRun reactive.

:: 2.11 Re-enable Windows Script Host
reg delete "!REG_ROOT!\Software\Microsoft\Windows Script Host\Settings" /v Enabled /f >nul 2>&1
echo    * Windows Script Host reactive.

:: 2.12 Re-enable screensaver changes
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v NoDispScrSavPage /f >nul 2>&1
echo    * Ecran de veille modifiable.

:: 2.13 Re-enable wallpaper changes
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /f >nul 2>&1
echo    * Fond d'ecran modifiable.

:: =============================================
:: SECTION 3: RESTORE SOFTWARE INSTALLATION
:: =============================================
echo.
echo [2] Restauration installation logiciels...

:: 3.1 Re-enable Windows Installer
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated /f >nul 2>&1
echo    * Windows Installer active.

:: =============================================
:: SECTION 4: RESTORE NETWORK ACCESS
:: =============================================
echo.
echo [3] Restauration acces reseau...

:: 4.1 Re-enable network sharing
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetHood /f >nul 2>&1
echo    * Voisinage reseau visible.

:: 4.2 Re-enable network settings
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetworkConnections /f >nul 2>&1
echo    * Connexions reseau activees.

:: =============================================
:: SECTION 5: RESTORE DEVICE ACCESS
:: =============================================
echo.
echo [4] Restauration acces peripheriques...

:: 5.1 Re-enable hardware installation
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions" /v DenyAll /f >nul 2>&1
echo    * Installation materiel activee.

:: 5.2 Re-enable Device Manager
reg delete "!REG_ROOT!\Software\Policies\Microsoft\MMC\{74246bfc-4c96-11d0-abef-0020af6b0b7a}" /f >nul 2>&1
echo    * Gestionnaire de peripheriques active.

:: =============================================
:: SECTION 6: RESTORE UAC TO DEFAULTS
:: =============================================
echo.
echo [5] Restauration parametres UAC...

:: 6.1 Reset UAC enumeration
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI" /v EnumerateAdministrators /f >nul 2>&1

:: 6.2 Reset UAC behavior
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser /t REG_DWORD /d 3 /f >nul 2>&1

echo    * Parametres UAC restaures.

:: =============================================
:: SECTION 7: PROMOTE USER TO ADMINISTRATOR
:: =============================================
echo.
echo [6] Promotion de [!TARGET_USER!] en Administrateur...

set "PROMOTE_SUCCESS=0"

:: Use detected admin group name
net localgroup "!ADMIN_GROUP!" "!TARGET_USER!" /add >nul 2>&1
if !errorLevel! equ 0 set "PROMOTE_SUCCESS=1"

if "!PROMOTE_SUCCESS!"=="1" (
    echo    * Succes. !TARGET_USER! est maintenant Administrateur.
) else (
    echo    * ERREUR ou deja membre du groupe !ADMIN_GROUP!.
)

:: =============================================
:: SECTION 8: DISABLE BUILT-IN ADMINISTRATOR AND SUPPORT ACCOUNT
:: =============================================
echo.
echo [7] Gestion des comptes admin caches...

:: Delete the hidden Support account if it exists
net user Support /delete >nul 2>&1
if !errorLevel! equ 0 (
    echo    * Compte "Support" supprime.
) else (
    echo    * Compte "Support" n'existait pas.
)

:: Remove SpecialAccounts entries (cleanup, no effect if not hidden)
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v Support /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v Administrator /f >nul 2>&1
echo    * Nettoyage des comptes caches (si presents).

:: Safety Check: Do not disable if target is the Administrator account
if /i "!TARGET_USER!"=="Administrator" goto :SKIP_DISABLE
if /i "!TARGET_USER!"=="Administrateur" goto :SKIP_DISABLE

:: Disable Administrator account
net user Administrator /active:no >nul 2>&1
echo    * Compte Administrator desactive.
goto :CONTINUE

:SKIP_DISABLE
echo    * Ignore: Impossible de desactiver Administrator si c'est la cible.

:CONTINUE

:: =============================================
:: SECTION 9: RESTORE BOOT OPTIONS
:: =============================================
echo.
echo [8] Restauration options de demarrage...

bcdedit /timeout 30 >nul 2>&1
echo    * Timeout boot restaure.

:: =============================================
:: SECTION 10: CLEAN UP EXPLORER POLICIES
:: =============================================
echo.
echo [9] Nettoyage des politiques restantes...

:: Remove any remaining Explorer restrictions from target user
for %%R in (NoControlPanel NoRun NoDrives NoNetHood NoNetworkConnections SettingsPageVisibility NoDateTimeControlPanel NoPropertiesMyComputer NoDriveTypeAutoRun) do (
    reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v %%R /f >nul 2>&1
)

:: Remove System policies for target user
for %%R in (DisableRegistryTools DisableTaskMgr NoDispScrSavPage) do (
    reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v %%R /f >nul 2>&1
)

:: Remove ActiveDesktop policies
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /f >nul 2>&1

:: Remove Windows Script Host block
reg delete "!REG_ROOT!\Software\Microsoft\Windows Script Host\Settings" /v Enabled /f >nul 2>&1

:: Remove MMC restrictions
reg delete "!REG_ROOT!\Software\Policies\Microsoft\MMC\{74246bfc-4c96-11d0-abef-0020af6b0b7a}" /f >nul 2>&1

:: Re-enable Remote Desktop (optional)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1

echo    * Toutes les politiques nettoyees.

:: Unload the registry hive if we loaded it
if "!USER_REG_LOADED!"=="1" (
    reg unload "HKU\!TARGET_SID!" >nul 2>&1
    echo    * Registre utilisateur decharge.
)

:: =============================================
:: SECTION 11: REMOVE ADMIN LAUNCHER
:: =============================================
echo.
echo [10] Suppression du Lanceur Admin...

:: Remove desktop shortcut
set "SHORTCUT_PATH=C:\Users\Public\Desktop\Lanceur Admin.lnk"
attrib -r -s "%SHORTCUT_PATH%" >nul 2>&1
del /f /q "%SHORTCUT_PATH%" >nul 2>&1
if not exist "%SHORTCUT_PATH%" (
    echo    * Raccourci supprime.
) else (
    echo    * ATTENTION: Raccourci non supprime.
)

:: Remove NoWin folder from Program Files
set "NOWIN_DIR=C:\Program Files\NoWin"
if exist "%NOWIN_DIR%" (
    :: Remove protection first (using detected group name)
    icacls "%NOWIN_DIR%" /remove:d "!USERS_GROUP!" >nul 2>&1
    rd /s /q "%NOWIN_DIR%" >nul 2>&1
    if not exist "%NOWIN_DIR%" (
        echo    * Dossier NoWin supprime.
    ) else (
        echo    * ATTENTION: Dossier NoWin non supprime.
    )
) else (
    echo    * Dossier NoWin n'existait pas.
)

:: =============================================
:: SECTION 12: FINAL OUTPUT
:: =============================================
echo.
echo ==========================================
echo     USER UNLOCK TERMINE (v3.0)
echo ==========================================
echo.
echo Utilisateur [!TARGET_USER!] entierement restaure:
echo  [+] Droits Administrateur accordes
echo  [+] Panneau de configuration
echo  [+] Editeur de registre
echo  [+] Gestionnaire de taches
echo  [+] Boite Executer
echo  [+] Application Settings
echo  [+] Installation logiciels
echo  [+] Parametres reseau
echo  [+] Date/heure
echo  [+] Fond d'ecran / Ecran de veille
echo  [+] Windows Script Host
echo  [-] Lanceur Admin supprime
echo  [+] Bureau a distance
echo  [+] Administrator visible sur ecran connexion
echo.
if "%AUTO_YES%"=="1" (
    echo.
    echo [AUTO] Deconnexion dans 5 secondes...
    timeout /t 5 /nobreak >nul
    shutdown /l
) else (
    echo.
    echo Appuyez sur une touche pour vous deconnecter...
    pause >nul
    shutdown /l
)

:CONFIRM_AGAIN
echo.
echo Nouvelle cible: [!TARGET_USER!]
goto :ASK_CONFIRM
