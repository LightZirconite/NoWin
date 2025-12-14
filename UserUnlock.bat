@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: USERUNLOCK.BAT - Complete User Privilege Restore
:: Version 2.3 - Matches UserLock v2.3
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
echo     USER PRIVILEGE RESTORE v2.2
echo ==========================================
echo.

:: =============================================
:: SECTION 1: IDENTIFY TARGET USER
:: =============================================
echo Detection de l'utilisateur standard...
echo.

:: Detect the first NON-Administrator standard user
set "TARGET_USER="
for /f "tokens=1" %%u in ('net user ^| findstr /v /i "Administrator Guest DefaultAccount WDAGUtilityAccount Support" ^| findstr /r "^[A-Za-z]"') do (
    if not defined TARGET_USER (
        for /f "tokens=*" %%g in ('net localgroup Administrateurs ^| findstr /v /i "%%u" 2^>nul') do (
            set "TARGET_USER=%%u"
        )
    )
)

:: Fallback: if no standard user found, use current user
if not defined TARGET_USER set "TARGET_USER=%USERNAME%"

echo Utilisateur STANDARD detecte: [%TARGET_USER%]
echo.
echo Ce script va:
echo  1. Supprimer TOUTES les restrictions de [%TARGET_USER%]
echo  2. Restaurer les droits Administrateur a [%TARGET_USER%]
echo  3. DESACTIVER le compte 'Administrator' integre
echo.

:ASK_CONFIRM
set /p "CONFIRM=[%TARGET_USER%] est le bon utilisateur a restaurer ? (O/N): "
if /i "%CONFIRM%"=="N" (
    echo.
    echo Liste de TOUS les utilisateurs locaux:
    echo =====================================
    set "USER_COUNT=0"
    for /f "skip=4 tokens=1" %%u in ('net user') do (
        if not "%%u"=="---" (
            if not "%%u"=="" (
                set /a USER_COUNT+=1
                echo   [!USER_COUNT!] %%u
                set "USER_!USER_COUNT!=%%u"
            )
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

:: =============================================
:: SECTION 2: RESTORE SYSTEM ACCESS
:: =============================================
echo.
echo [1] Suppression des restrictions systeme...

:: 2.1 Remove Control Panel block
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /f >nul 2>&1
echo    * Panneau de configuration debloque.

:: 2.2 Remove Registry Editor block
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /f >nul 2>&1
echo    * Editeur de registre debloque.

:: 2.3 Remove Task Manager block
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /f >nul 2>&1
echo    * Gestionnaire de taches debloque.

:: 2.4 Remove Run dialog block
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoRun /f >nul 2>&1
echo    * Boite Executer debloquee.

:: 2.5 Remove drive hiding
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDrives /f >nul 2>&1
echo    * Lecteurs visibles.

:: 2.6 Remove Settings app restrictions
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f >nul 2>&1
echo    * Application Settings debloquee.

:: 2.7 Remove date/time block
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDateTimeControlPanel /f >nul 2>&1
echo    * Date/heure debloquee.

:: 2.8 Re-enable Developer Mode access
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowAllTrustedApps /f >nul 2>&1
echo    * Mode developpeur accessible.

:: 2.9 Remove system properties block
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoPropertiesMyComputer /f >nul 2>&1
echo    * Proprietes systeme debloquees.

:: 2.10 Re-enable AutoPlay/AutoRun
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /f >nul 2>&1
echo    * AutoPlay/AutoRun reactive.

:: 2.11 Re-enable Windows Script Host
reg delete "HKCU\Software\Microsoft\Windows Script Host\Settings" /v Enabled /f >nul 2>&1
echo    * Windows Script Host reactive.

:: 2.12 Re-enable screensaver changes
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v NoDispScrSavPage /f >nul 2>&1
echo    * Ecran de veille modifiable.

:: 2.13 Re-enable wallpaper changes
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /f >nul 2>&1
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
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetHood /f >nul 2>&1
echo    * Voisinage reseau visible.

:: 4.2 Re-enable network settings
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoNetworkConnections /f >nul 2>&1
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
reg delete "HKCU\Software\Policies\Microsoft\MMC\{74246bfc-4c96-11d0-abef-0020af6b0b7a}" /f >nul 2>&1
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
echo [6] Promotion de [%TARGET_USER%] en Administrateur...

set "PROMOTE_SUCCESS=0"

net localgroup Administrators "%TARGET_USER%" /add >nul 2>&1
if %errorLevel% equ 0 set "PROMOTE_SUCCESS=1"

net localgroup Administrateurs "%TARGET_USER%" /add >nul 2>&1
if %errorLevel% equ 0 set "PROMOTE_SUCCESS=1"

if "%PROMOTE_SUCCESS%"=="1" (
    echo    * Succes. %TARGET_USER% est maintenant Administrateur.
) else (
    echo    * ERREUR: Impossible d'ajouter au groupe Administrateurs.
)

:: =============================================
:: SECTION 8: DISABLE BUILT-IN ADMINISTRATOR AND SUPPORT ACCOUNT
:: =============================================
echo.
echo [7] Desactivation des comptes admin...

:: Delete the hidden Support account if it exists
net user Support /delete >nul 2>&1
if %errorLevel% equ 0 (
    echo    * Compte "Support" supprime.
) else (
    echo    * Compte "Support" n'existait pas.
)

:: Remove Support from SpecialAccounts
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v Support /f >nul 2>&1

:: Safety Check: Do not disable if target is the Administrator account
if /i "%TARGET_USER%"=="Administrator" goto :SKIP_DISABLE
if /i "%TARGET_USER%"=="Administrateur" goto :SKIP_DISABLE

if "%PROMOTE_SUCCESS%"=="1" (
    net user Administrator /active:no >nul 2>&1
    echo    * Compte Administrator desactive.
) else (
    echo    * ATTENTION: Promotion echouee. Compte Administrator reste actif.
)
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

:: Remove any remaining Explorer restrictions
for %%R in (NoControlPanel NoRun NoDrives NoNetHood NoNetworkConnections SettingsPageVisibility NoDateTimeControlPanel NoPropertiesMyComputer NoDriveTypeAutoRun) do (
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v %%R /f >nul 2>&1
)

:: Remove System policies for this user
for %%R in (DisableRegistryTools DisableTaskMgr NoDispScrSavPage) do (
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v %%R /f >nul 2>&1
)

:: Remove ActiveDesktop policies
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /f >nul 2>&1

:: Remove Windows Script Host block
reg delete "HKCU\Software\Microsoft\Windows Script Host\Settings" /v Enabled /f >nul 2>&1

:: Re-enable Remote Desktop (optional)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1

echo    * Toutes les politiques nettoyees.

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
    :: Remove protection first
    icacls "%NOWIN_DIR%" /remove:d "Users" >nul 2>&1
    icacls "%NOWIN_DIR%" /remove:d "Utilisateurs" >nul 2>&1
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
echo     USER UNLOCK TERMINE (v2.3)
echo ==========================================
echo.
echo Utilisateur [%TARGET_USER%] entierement restaure:
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
echo.
echo Deconnexion dans 5 secondes...
timeout /t 5
shutdown /l

:CONFIRM_AGAIN
echo.
echo Nouvelle cible: [%TARGET_USER%]
goto :ASK_CONFIRM
