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
echo    -> Success. Password set.

echo.
echo [2/2] Demoting user [%TARGET_USER%] to Standard User...
net localgroup Administrators "%TARGET_USER%" /delete
if %errorLevel% equ 0 (
    echo    -> Success. %TARGET_USER% is now a Standard User.
) else (
    echo    -> ERROR: Could not remove user from Administrators group.
    echo       (Maybe they are not in the group or name is wrong?)
)

echo.
echo ==========================================
echo DONE. You must LOG OFF and LOG BACK IN for changes to apply.
echo To perform admin tasks, use the 'Administrator' account.
echo ==========================================
pause
exit /b
