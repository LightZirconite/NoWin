@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ==========================================
echo        USER PRIVILEGE RESTORE
echo ==========================================
echo.

:: 1. Identify User
set "TARGET_USER=%USERNAME%"

:: Try to detect the real logged-on user (ignoring the Admin account used for UAC)
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "$u=(Get-WmiObject Win32_ComputerSystem).UserName; if($u){$u.Split('\')[1]}"`) do (
    if not "%%a"=="" set "TARGET_USER=%%a"
)

echo Detected target user: [%TARGET_USER%]
echo.
echo This script will:
echo  1. Give Administrator rights back to [%TARGET_USER%].
echo  2. DISABLE the built-in 'Administrator' account.
echo.

:ASK_CONFIRM
set /p "CONFIRM=Is [%TARGET_USER%] the correct user to promote? (Y/N): "
if /i "%CONFIRM%"=="N" (
    echo.
    set /p "TARGET_USER=Please enter the exact username to promote: "
    goto :CONFIRM_AGAIN
)
if /i "%CONFIRM%" neq "Y" goto :ASK_CONFIRM

:PROCEED
echo.
echo [1/2] Promoting user [%TARGET_USER%] to Administrator...
set "PROMOTE_SUCCESS=0"

net localgroup Administrators "%TARGET_USER%" /add >nul 2>&1
if %errorLevel% equ 0 set "PROMOTE_SUCCESS=1"

net localgroup Administrateurs "%TARGET_USER%" /add >nul 2>&1
if %errorLevel% equ 0 set "PROMOTE_SUCCESS=1"

if "%PROMOTE_SUCCESS%"=="1" (
    echo    * Success. %TARGET_USER% is now an Administrator.
) else (
    echo    * ERROR: Could not add user to Administrators group.
    echo      (Check if running as Admin, or if group names differ).
)

echo.
echo [2/2] Disabling built-in Administrator account...

:: Safety Check: Do not disable if we just promoted 'Administrator' (Self-target)
if /i "%TARGET_USER%"=="Administrator" goto :SKIP_DISABLE
if /i "%TARGET_USER%"=="Administrateur" goto :SKIP_DISABLE

:: We only disable it if we successfully promoted the user
if "%PROMOTE_SUCCESS%"=="1" (
    net user Administrator /active:no
    echo    * Success. Built-in Admin disabled.

    :: Reset UAC Enumeration
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI" /v EnumerateAdministrators /f >nul 2>&1
    echo    * UAC enumeration reset.
) else (
    echo    * WARNING: Promotion failed.
    echo       Keeping built-in Administrator active for safety.
)

:SKIP_DISABLE
echo.
echo ==========================================
echo DONE. Logging off to apply changes...
echo ==========================================
timeout /t 3
shutdown /l

:CONFIRM_AGAIN
echo.
echo New target is: [%TARGET_USER%]
goto :ASK_CONFIRM
