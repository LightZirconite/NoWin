@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: ============================================
:: USERUNLOCK.BAT - Complete User Privilege Restore
:: Version 3.0 - Full System Unlock
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
    if errorlevel 1 (
        echo [ERREUR] Impossible d'obtenir les droits administrateur.
        echo.
        echo SOLUTION:
        echo  1. Clic droit sur ce script
        echo  2. Choisir "Executer en tant qu'administrateur"
        echo.
        if "%AUTO_YES%"=="1" (timeout /t 2 /nobreak >nul) else (pause)
    )
    exit /b
)

echo ==========================================
echo     USER PRIVILEGE RESTORE v3.0
echo ==========================================

:: =============================================
:: SECTION 0: DETECT GROUP NAMES
:: =============================================
echo Detection des groupes systeme...

:: Get Administrators group name using SID
set "ADMIN_GROUP="
for /f "tokens=*" %%g in ('powershell -NoProfile -Command "(New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([System.Security.Principal.NTAccount]).Value.Split('\\')[-1]"') do (
    set "ADMIN_GROUP=%%g"
)

:: Get Users group name using SID
set "USERS_GROUP="
for /f "tokens=*" %%g in ('powershell -NoProfile -Command "(New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-545')).Translate([System.Security.Principal.NTAccount]).Value.Split('\\')[-1]"') do (
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
echo.
echo Detection de l'utilisateur a restaurer...
echo.

:: Get CURRENT logged-in user (session actuelle)
set "TARGET_USER=%USERNAME%"

:: Verify user exists and is valid
for /f "usebackq tokens=*" %%u in (`powershell -NoProfile -Command "Get-LocalUser -Name '%USERNAME%' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name"`) do (
    set "TARGET_USER=%%u"
)

if not defined TARGET_USER (
    echo [ERREUR] Impossible de detecter l'utilisateur actuel.
    if "%AUTO_YES%"=="1" (timeout /t 2 /nobreak >nul) else (pause)
    exit /b
)

:: Get user SID
set "TARGET_SID="
set "TARGET_USER_CMD=!TARGET_USER!"
for /f "usebackq tokens=*" %%s in (`powershell -NoProfile -Command "(Get-LocalUser -Name '%TARGET_USER_CMD%' -ErrorAction SilentlyContinue).SID.Value"`) do (
    set "TARGET_SID=%%s"
)

echo Utilisateur detecte: [!TARGET_USER!] (session actuelle)
if defined TARGET_SID echo    * SID: !TARGET_SID!

:: Check current admin status
net localgroup "!ADMIN_GROUP!" 2>nul | findstr /i /c:"!TARGET_USER!" >nul
if not errorlevel 1 (
    echo    * Statut: Deja ADMINISTRATEUR
) else (
    echo    * Statut: Utilisateur standard
)

echo.
echo Ce script va TOUT debloquer pour [!TARGET_USER!] (VOUS):
echo  [+] Restaurer droits Administrateur
echo  [+] Debloquer Panneau de configuration
echo  [+] Debloquer Editeur de registre
echo  [+] Debloquer Gestionnaire de taches
echo  [+] Debloquer Boite Executer
echo  [+] Debloquer Parametres Windows
echo  [+] Debloquer Date/Heure
echo  [+] Debloquer Reseau
echo  [+] Debloquer Installation logiciels
echo  [+] Restaurer fond d'ecran / ecran de veille
echo  [+] Reactiver Windows Script Host
echo  [+] Supprimer compte Support cache
echo  [+] Desactiver compte Administrator
echo  [+] Supprimer Lanceur Admin
echo.

if "%AUTO_YES%"=="1" (
    echo [AUTO] Restauration de [!TARGET_USER!]...
    goto :CONTINUE_RESTORE
)

:ASK_CONFIRM
set /p "CONFIRM=[!TARGET_USER!] est le bon utilisateur? (O/N): "
if /i "%CONFIRM%"=="N" (
    echo.
    echo Liste de TOUS les utilisateurs:
    echo ==================================
    set "USER_COUNT=0"
    
    for /f "usebackq tokens=*" %%u in (`powershell -NoProfile -Command "Get-LocalUser | Where-Object {$_.Enabled -eq $true} | Select-Object -ExpandProperty Name"`) do (
        set /a "USER_COUNT+=1"
        echo   [!USER_COUNT!] %%u
        set "USER_!USER_COUNT!=%%u"
    )
    
    echo.
    set /p "USER_CHOICE=Numero (1-!USER_COUNT!): "
    if defined USER_!USER_CHOICE! (
        for /f "tokens=*" %%a in ("!USER_%USER_CHOICE%!") do set "TARGET_USER=%%a"
        echo.
        echo Utilisateur selectionne: [!TARGET_USER!]
        echo.
        :: Re-get SID for new user
        set "TARGET_SID="
        set "TARGET_USER_CMD=!TARGET_USER!"
        for /f "usebackq tokens=*" %%s in (`powershell -NoProfile -Command "(Get-LocalUser -Name '%TARGET_USER_CMD%' -ErrorAction SilentlyContinue).SID.Value"`) do (
            set "TARGET_SID=%%s"
        )
        if defined TARGET_SID echo    * SID: !TARGET_SID!
        echo.
    )
    goto :PROCEED
)
if /i "%CONFIRM%" neq "O" (
    if /i "%CONFIRM%" neq "Y" goto :ASK_CONFIRM
)

:PROCEED
:CONTINUE_RESTORE

:: =============================================
:: SECTION 2: LOAD USER REGISTRY
:: =============================================
echo.
echo [1] Preparation registre utilisateur...

set "REG_ROOT=HKU\!TARGET_SID!"
set "USER_REG_LOADED=0"

if defined TARGET_SID (
    reg query "!REG_ROOT!" >nul 2>&1
    if errorlevel 1 (
        :: User not logged in - load NTUSER.DAT
        set "NTUSER_PATH="
        set "TARGET_SID_CMD=!TARGET_SID!"
        for /f "tokens=*" %%p in ('powershell -NoProfile -Command "$prof = Get-WmiObject Win32_UserProfile | Where-Object {$_.SID -eq '%TARGET_SID_CMD%'}; if($prof){$prof.LocalPath}"') do (
            set "NTUSER_PATH=%%p\NTUSER.DAT"
        )
        if exist "!NTUSER_PATH!" (
            reg load "HKU\!TARGET_SID!" "!NTUSER_PATH!" >nul 2>&1
            if not errorlevel 1 (
                set "USER_REG_LOADED=1"
                echo    * Registre charge: !NTUSER_PATH!
            ) else (
                echo    * Impossible de charger registre
                set "REG_ROOT=HKCU"
            )
        ) else (
            set "REG_ROOT=HKCU"
        )
    ) else (
        set "USER_REG_LOADED=0"
        echo    * Utilisateur connecte - acces direct
    )
) else (
    set "REG_ROOT=HKCU"
)

echo    * Cible: !REG_ROOT!
echo.

:: =============================================
:: SECTION 3: REMOVE ALL USER RESTRICTIONS
:: =============================================
echo [2] Suppression restrictions utilisateur...

:: Control Panel
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /f >nul 2>&1
echo    * Panneau de configuration

:: Registry Editor
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /f >nul 2>&1
echo    * Editeur de registre

:: Task Manager
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /f >nul 2>&1
echo    * Gestionnaire de taches

:: Run Box
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoRun /f >nul 2>&1
echo    * Boite Executer

:: Drives Access
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDrives /f >nul 2>&1
echo    * Acces disques

:: Settings Pages
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f >nul 2>&1
echo    * Pages parametres

:: Date/Time
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDateTimeControlPanel /f >nul 2>&1
echo    * Date/Heure

:: Computer Properties
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoPropertiesMyComputer /f >nul 2>&1
echo    * Proprietes ordinateur

:: AutoRun
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /f >nul 2>&1
echo    * AutoRun

:: Windows Script Host
reg delete "!REG_ROOT!\Software\Microsoft\Windows Script Host\Settings" /v Enabled /f >nul 2>&1
echo    * Windows Script Host

:: Screensaver
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v NoDispScrSavPage /f >nul 2>&1
echo    * Ecran de veille

:: Wallpaper
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /f >nul 2>&1
echo    * Fond d'ecran

:: Network Hood
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetHood /f >nul 2>&1
echo    * Voisinage reseau

:: Network Connections
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetworkConnections /f >nul 2>&1
echo    * Connexions reseau

:: Device Manager MMC
reg delete "!REG_ROOT!\Software\Policies\Microsoft\MMC\{74246bfc-4c96-11d0-abef-0020af6b0b7a}" /f >nul 2>&1
echo    * Gestionnaire peripheriques

:: =============================================
:: SECTION 4: REMOVE SYSTEM-WIDE RESTRICTIONS
:: =============================================
echo.
echo [3] Suppression restrictions systeme...

:: Control Panel (system)
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /f >nul 2>&1
echo    * Panneau config (systeme)

:: Registry Tools (system)
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /f >nul 2>&1
echo    * Editeur registre (systeme)

:: Task Manager (system)
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /f >nul 2>&1
echo    * Gestionnaire taches (systeme)

:: Command Prompt
reg delete "HKLM\Software\Policies\Microsoft\Windows\System" /v DisableCMD /f >nul 2>&1
echo    * Invite de commandes

:: Windows Defender (re-enable)
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /f >nul 2>&1
echo    * Windows Defender

:: Windows Update (re-enable)
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f >nul 2>&1
echo    * Windows Update

:: =============================================
:: SECTION 5: RESTORE UAC
:: =============================================
echo.
echo [4] Restauration UAC...

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f >nul 2>&1
echo    * UAC reactive

:: =============================================
:: SECTION 6: PROMOTE TO ADMINISTRATOR
:: =============================================
echo.
echo [5] Promotion Administrateur...

set "PROMOTE_SUCCESS=0"
net localgroup "!ADMIN_GROUP!" "!TARGET_USER!" /add >nul 2>&1
if not errorlevel 1 set "PROMOTE_SUCCESS=1"

if "!PROMOTE_SUCCESS!"=="1" (
    echo    * [!TARGET_USER!] est maintenant Administrateur
) else (
    echo    * Deja Administrateur ou erreur
)

:: =============================================
:: SECTION 7: CLEAN UP HIDDEN ACCOUNTS
:: =============================================
echo.
echo [6] Nettoyage comptes caches...

:: Delete Support account
net user Support /delete >nul 2>&1
if not errorlevel 1 (
    echo    * Compte Support supprime
) else (
    echo    * Compte Support inexistant
)

:: Remove hidden account registry entries
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v Support /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v Administrator /f >nul 2>&1
echo    * Comptes caches nettoyes

:: Disable Administrator account (if target is different)
if /i not "!TARGET_USER!"=="Administrator" (
    if /i not "!TARGET_USER!"=="Administrateur" (
        net user Administrator /active:no >nul 2>&1
        echo    * Compte Administrator desactive
    )
)

:: =============================================
:: SECTION 8: RESTORE BOOT OPTIONS
:: =============================================
echo.
echo [7] Restauration options demarrage...

bcdedit /timeout 30 >nul 2>&1
echo    * Timeout boot: 30s

:: =============================================
:: SECTION 9: FINAL CLEANUP
:: =============================================
echo.
echo [8] Nettoyage final politiques...

:: Batch remove remaining Explorer policies
for %%R in (NoControlPanel NoRun NoDrives NoNetHood NoNetworkConnections SettingsPageVisibility NoDateTimeControlPanel NoPropertiesMyComputer NoDriveTypeAutoRun) do (
    reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v %%R /f >nul 2>&1
)

:: Batch remove System policies
for %%R in (DisableRegistryTools DisableTaskMgr NoDispScrSavPage) do (
    reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v %%R /f >nul 2>&1
)

:: Remove ActiveDesktop policies
reg delete "!REG_ROOT!\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /f >nul 2>&1

:: Remove Script Host block
reg delete "!REG_ROOT!\Software\Microsoft\Windows Script Host\Settings" /v Enabled /f >nul 2>&1

:: Remove MMC restrictions
reg delete "!REG_ROOT!\Software\Policies\Microsoft\MMC" /f >nul 2>&1

:: Enable Remote Desktop
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1
echo    * Toutes politiques supprimees

:: Unload registry if loaded
if "!USER_REG_LOADED!"=="1" (
    reg unload "HKU\!TARGET_SID!" >nul 2>&1
    echo    * Registre decharge
)

:: =============================================
:: SECTION 10: REMOVE ADMIN LAUNCHER
:: =============================================
echo.
echo [9] Suppression Lanceur Admin...

:: Remove desktop shortcut
set "SHORTCUT_PATH=C:\Users\Public\Desktop\Lanceur Admin.lnk"
if exist "%SHORTCUT_PATH%" (
    attrib -r -s "%SHORTCUT_PATH%" >nul 2>&1
    del /f /q "%SHORTCUT_PATH%" >nul 2>&1
    if not exist "%SHORTCUT_PATH%" (
        echo    * Raccourci supprime
    ) else (
        echo    * Raccourci non supprime
    )
) else (
    echo    * Raccourci inexistant
)

:: Remove NoWin folder
set "NOWIN_DIR=C:\Program Files\NoWin"
if exist "%NOWIN_DIR%" (
    icacls "%NOWIN_DIR%" /remove:d "!USERS_GROUP!" >nul 2>&1
    rd /s /q "%NOWIN_DIR%" >nul 2>&1
    if not exist "%NOWIN_DIR%" (
        echo    * Dossier NoWin supprime
    ) else (
        echo    * Dossier NoWin non supprime
    )
) else (
    echo    * Dossier NoWin inexistant
)

:: =============================================
:: FINAL SUMMARY
:: =============================================
echo.
echo ==========================================
echo     UNLOCK TERMINE - SUCCES
echo ==========================================
echo.
echo Utilisateur [!TARGET_USER!] completement restaure:
echo.
echo  [+] Droits Administrateur
echo  [+] Panneau de configuration
echo  [+] Editeur de registre
echo  [+] Gestionnaire de taches
echo  [+] Boite Executer
echo  [+] Parametres Windows
echo  [+] Installation logiciels
echo  [+] Parametres reseau
echo  [+] Date et heure
echo  [+] Fond d'ecran / Ecran de veille
echo  [+] Windows Script Host
echo  [+] Gestionnaire peripheriques
echo  [-] Lanceur Admin supprime
echo  [+] Bureau a distance active
echo  [+] UAC reactive
echo  [+] Windows Defender reactive
echo.
echo ==========================================
echo     DECONNEXION REQUISE
echo ==========================================
echo.
echo Pour finaliser:
echo  1. Deconnectez-vous de Windows
echo  2. Reconnectez-vous avec [!TARGET_USER!]
echo.

if "%AUTO_YES%"=="1" (
    choice /c on /t 10 /d n /m "Deconnexion auto dans 10s (o=maintenant / n=annuler)"
    if not errorlevel 2 (
        echo.
        echo [AUTO] Deconnexion...
        timeout /t 2 /nobreak >nul
        shutdown /l
    )
    echo.
    echo [INFO] Pensez a vous deconnecter manuellement.
    pause
    exit /b 0
) else (
    choice /c onrl /m "Action? (o=Quitter / n=Quitter / r=Redemarrer / l=Deconnecter)"
    if errorlevel 4 (
        echo.
        echo [INFO] Deconnexion...
        timeout /t 2 /nobreak >nul
        shutdown /l
        exit /b 0
    )
    if errorlevel 3 (
        echo.
        echo [INFO] Redemarrage du PC...
        timeout /t 2 /nobreak >nul
        shutdown /r /t 0
        exit /b 0
    )
    echo.
    echo [INFO] Pensez a vous deconnecter/redemarrer manuellement.
    pause
    exit /b 0
)
