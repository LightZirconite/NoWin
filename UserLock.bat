@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ==========================================
echo        USER PRIVILEGE LOCKDOWN
echo ==========================================
echo.

:: 1. Identify User
set "TARGET_USER=%USERNAME%"
echo Detected current user: [%TARGET_USER%]
echo.
:: 2. Enable built-in Administrator
echo [1/2] Enabling built-in Administrator account...
net user Administrator uyy /active:yes
if %errorLevel% neq 0 (
    echo FAILED to enable Administrator account. Aborting to prevent lockout.
    pause
    exit /b
)
echo    * Success. Password set.

:: NOTE: We do NOT hide the Administrator account anymore.
:: Hiding it via SpecialAccounts causes the UAC "No" button issue (lockout)
:: because Windows thinks there are no active admins available.

echo.
echo [1.6] Optimizing UAC (Show Admin List)...
:: Force UAC to list admins (so you might just click and type password) even if hidden
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI" /v EnumerateAdministrators /t REG_DWORD /d 1 /f >nul 2>&1
echo    * UAC enumeration enabled.

echo.
echo [2/2] Demoting user [%TARGET_USER%] to Standard User...
:: Ensure user is in the standard Users group (try English and French names) to prevent lockout
set "ADDED_TO_USERS=0"
net localgroup Users "%TARGET_USER%" /add >nul 2>&1
if %errorLevel% equ 0 set "ADDED_TO_USERS=1"
net localgroup Utilisateurs "%TARGET_USER%" /add >nul 2>&1
if %errorLevel% equ 0 set "ADDED_TO_USERS=1"

if "%ADDED_TO_USERS%"=="1" (
    echo    * User added to Users/Utilisateurs group.
) else (
    echo    * WARNING: Could not add to Users group. Proceeding anyway...
)

:: Remove from Administrators (try English and French names)
net localgroup Administrators "%TARGET_USER%" /delete >nul 2>&1
net localgroup Administrateurs "%TARGET_USER%" /delete >nul 2>&1

:: Verify removal by checking if they are NO LONGER in the group
set "IS_ADMIN=0"
net user "%TARGET_USER%" | findstr /i "Administrators Administrateurs" >nul
if %errorLevel% equ 0 set "IS_ADMIN=1"

if "%IS_ADMIN%"=="0" (
    echo    * Success. %TARGET_USER% is now a Standard User.
) else (
    echo    * ERROR: Could not remove user from Administrators group.
    echo       (Maybe they are not in the group or name is wrong?)
)

echo.
echo ==========================================
echo DONE. Logging off to apply changes...
echo To perform admin tasks, use the 'Administrator' account.
echo ==========================================
timeout /t 3
shutdown /l
