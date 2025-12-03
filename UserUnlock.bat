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
echo Detected current user: [%TARGET_USER%]
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
net localgroup Administrators "%TARGET_USER%" /add
if %errorLevel% equ 0 (
    echo    * Success. %TARGET_USER% is now an Administrator.
) else (
    echo    * ERROR: Could not add user to Administrators group.
)

echo.
echo [2/2] Disabling built-in Administrator account...
:: We only disable it if we successfully promoted the user (safety check)
net localgroup Administrators "%TARGET_USER%" | findstr /i "%TARGET_USER%" >nul
if %errorLevel% equ 0 (
    net user Administrator /active:no
    echo    * Success. Built-in Admin disabled.
) else (
    echo    * WARNING: Target user does not seem to be Admin yet.
    echo       Keeping built-in Administrator active for safety.
)

echo.
echo ==========================================
echo DONE. You must LOG OFF and LOG BACK IN for changes to apply.
echo ==========================================
pause
exit /b

:CONFIRM_AGAIN
echo.
echo New target is: [%TARGET_USER%]
goto :ASK_CONFIRM
