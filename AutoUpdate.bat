@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
:: ============================================
:: AUTOUPDATE.BAT - NoWin smart updater
:: Version 4.2.0
:: ============================================

set "SCRIPT_DIR=%~dp0"
set "REPO_OWNER=LightZirconite"
set "REPO_NAME=NoWin"
set "REPO_REF=main"
if defined NOWIN_GITHUB_REF set "REPO_REF=%NOWIN_GITHUB_REF%"

set "REPO_API_META=https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%"
set "REPO_API_CONTENTS=https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/contents?ref=%REPO_REF%"
set "REPO_RAW=https://raw.githubusercontent.com/%REPO_OWNER%/%REPO_NAME%/%REPO_REF%"

set "TASK_NAME=NoWin_AutoUpdate"
set "LOG_DIR=C:\ProgramData\NoWin"
set "LOG_FILE=%LOG_DIR%\autoupdate.log"
set "STATE_FILE=%SCRIPT_DIR%.last_remote_pushed_at"
set "LOCAL_VERSION_FILE=%SCRIPT_DIR%VERSION"
set "SELF_SCRIPT=%SCRIPT_DIR%AutoUpdate.bat"
set "SELF_NEXT=%SCRIPT_DIR%AutoUpdate.next.bat"

set "FILES_TO_UPDATE=NoWin.bat Lockdown.bat Unlock.bat Verify.bat UserLock.bat UserUnlock.bat AdminLauncher.bat UninstallAdmin.bat Watchdog.bat AutoUpdate.bat force-update-agent.bat README.md DOCS.md VERSION"

set "SILENT=0"
set "FORCE=0"
set "REMOTE_NEWER=0"
set "REMOTE_STATE="
set "REMOTE_VERSION=unknown"

call :apply_staged_self_update >nul 2>&1

if /i "%~1"=="--run" (
    set "SILENT=1"
    goto :run_check_apply
)
if /i "%~1"=="--check" goto :check_only
if /i "%~1"=="--update" goto :update_now
if /i "%~1"=="--force" (
    set "FORCE=1"
    goto :update_now
)
if /i "%~1"=="--install" goto :install_task
if /i "%~1"=="--uninstall" goto :uninstall_task

goto :menu

:menu
call :ensure_log_dir >nul 2>&1
cls
echo ==========================================================
echo        NoWin v4.2 - SMART AUTO UPDATE
echo ==========================================================
echo.
call :get_local_version
echo Version locale : %LOCAL_VERSION%
echo Depot distant : %REPO_OWNER%/%REPO_NAME% ^(branche: %REPO_REF%^)
if defined NOWIN_GITHUB_TOKEN (
    echo Authentification : token detecte
) else (
    echo Authentification : anonyme
)
echo.
echo [1] Verifier les mises a jour
echo [2] Mettre a jour maintenant
echo [3] Installer l'auto-update quotidien ^(03:30, SYSTEM^)
echo [4] Desinstaller l'auto-update
echo [0] Quitter
echo.
set /p "CHOIX=Choix: "
if "%CHOIX%"=="1" (
    call :check_only
    pause
    goto :menu
)
if "%CHOIX%"=="2" (
    call :update_now
    pause
    goto :menu
)
if "%CHOIX%"=="3" (
    call :install_task
    pause
    goto :menu
)
if "%CHOIX%"=="4" (
    call :uninstall_task
    pause
    goto :menu
)
exit /b

:check_only
call :ensure_log_dir >nul 2>&1
call :check_update
if errorlevel 1 (
    echo [ERREUR] Impossible de verifier le depot GitHub.
    call :log "Check failed: repo unavailable"
    exit /b 1
)
if "%REMOTE_NEWER%"=="1" (
    echo [UPDATE] Mise a jour disponible. Etat distant: %REMOTE_VERSION%
) else (
    echo [OK] Deja a jour. Etat distant: %REMOTE_VERSION%
)
call :log "Check complete: remote=%REMOTE_VERSION% newer=%REMOTE_NEWER%"
exit /b 0

:update_now
call :ensure_log_dir >nul 2>&1
call :check_update
if errorlevel 1 (
    echo [ERREUR] Impossible de verifier le depot GitHub.
    call :log "Update aborted: repo unavailable"
    exit /b 1
)
if "%FORCE%"=="1" set "REMOTE_NEWER=1"
if not "%REMOTE_NEWER%"=="1" (
    echo [OK] Aucune mise a jour necessaire.
    call :log "Update skipped: already up to date"
    exit /b 0
)
if "%SILENT%"=="0" (
    choice /c on /n /m "Appliquer la mise a jour maintenant? (o/n): "
    if errorlevel 2 (
        echo [ANNULE] Mise a jour annulee.
        call :log "Update cancelled by user"
        exit /b 1
    )
)
call :apply_update
exit /b %errorlevel%

:run_check_apply
call :ensure_log_dir >nul 2>&1
call :check_update
if errorlevel 1 (
    call :log "Scheduled run: repo unavailable"
    exit /b 0
)
if "%REMOTE_NEWER%"=="1" (
    call :log "Scheduled run: update available (%REMOTE_VERSION%)"
    call :apply_update
) else (
    call :log "Scheduled run: already up to date (%REMOTE_VERSION%)"
)
exit /b 0

:check_update
set "REMOTE_NEWER=0"
set "REMOTE_STATE="
set "REMOTE_VERSION=unknown"
set "LOCAL_STATE="

call :get_local_version
call :get_repo_pushed_at
if errorlevel 1 exit /b 1

if exist "%STATE_FILE%" (
    for /f "usebackq delims=" %%L in ("%STATE_FILE%") do if not "%%L"=="" set "LOCAL_STATE=%%L"
)

set "REMOTE_VERSION=repo:%REMOTE_STATE%"
if not defined LOCAL_STATE (
    set "REMOTE_NEWER=1"
) else (
    if /i "%LOCAL_STATE%"=="%REMOTE_STATE%" (
        set "REMOTE_NEWER=0"
    ) else (
        set "REMOTE_NEWER=1"
    )
)
exit /b 0

:get_repo_pushed_at
set "REMOTE_STATE="
for /f "delims=" %%S in ('powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $h=@{'User-Agent'='NoWin-Updater'}; if($env:NOWIN_GITHUB_TOKEN){$h['Authorization']='Bearer '+$env:NOWIN_GITHUB_TOKEN}; (Invoke-RestMethod -Uri '%REPO_API_META%' -Headers $h -TimeoutSec 20).pushed_at" 2^>nul') do set "REMOTE_STATE=%%S"
if not defined REMOTE_STATE exit /b 1
exit /b 0

:apply_update
set "UPDATED=0"
set "UPDATE_FILES="
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%T"
set "STAGING=%TEMP%\NoWinStage_%RANDOM%%RANDOM%"
set "BACKUP_ROOT=%SCRIPT_DIR%backup"
set "BACKUP_DIR=%BACKUP_ROOT%\%STAMP%"

if not exist "%BACKUP_ROOT%" mkdir "%BACKUP_ROOT%" >nul 2>&1
if not exist "%STAGING%" mkdir "%STAGING%" >nul 2>&1
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1

call :resolve_update_files
if not defined UPDATE_FILES set "UPDATE_FILES=%FILES_TO_UPDATE%"

call :log "Update start: remote=%REMOTE_VERSION%"
call :log "Update file set: %UPDATE_FILES%"

for %%F in (!UPDATE_FILES!) do (
    call :download_file %%F "%STAGING%\%%F"
    if errorlevel 1 (
        call :log "Update failed while downloading %%F"
        goto :apply_cleanup
    )
)

for %%F in (!UPDATE_FILES!) do (
    if exist "%SCRIPT_DIR%%%F" copy /y "%SCRIPT_DIR%%%F" "%BACKUP_DIR%\%%F" >nul 2>&1
)

for %%F in (!UPDATE_FILES!) do (
    if /i "%%F"=="AutoUpdate.bat" (
        copy /y "%STAGING%\%%F" "%SELF_NEXT%" >nul 2>&1
        if errorlevel 1 (
            call :log "Update failed while staging AutoUpdate.next.bat"
            goto :rollback
        )
    ) else (
        copy /y "%STAGING%\%%F" "%SCRIPT_DIR%%%F" >nul 2>&1
        if errorlevel 1 (
            call :log "Update failed while copying %%F"
            goto :rollback
        )
    )
)

set "UPDATED=1"
call :log "Update success: backup=%BACKUP_DIR%"
if defined REMOTE_STATE > "%STATE_FILE%" echo %REMOTE_STATE%
if exist "%SELF_NEXT%" call :log "Updater refresh staged in AutoUpdate.next.bat"
if "%SILENT%"=="0" echo [OK] Mise a jour terminee.
goto :apply_cleanup

:rollback
call :log "Rollback started"
for %%F in (!UPDATE_FILES!) do (
    if exist "%BACKUP_DIR%\%%F" copy /y "%BACKUP_DIR%\%%F" "%SCRIPT_DIR%%%F" >nul 2>&1
)
call :log "Rollback finished"
if "%SILENT%"=="0" echo [ERREUR] Mise a jour interrompue. Rollback applique.

:apply_cleanup
if exist "%STAGING%" rd /s /q "%STAGING%" >nul 2>&1
if "%UPDATED%"=="1" (
    exit /b 0
) else (
    exit /b 1
)

:resolve_update_files
set "UPDATE_FILES="
for /f "delims=" %%L in ('powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $allow='%FILES_TO_UPDATE%'.Split(' '); $h=@{'User-Agent'='NoWin-Updater'}; if($env:NOWIN_GITHUB_TOKEN){$h['Authorization']='Bearer '+$env:NOWIN_GITHUB_TOKEN}; $items=Invoke-RestMethod -Uri '%REPO_API_CONTENTS%' -Headers $h -TimeoutSec 20; $names=@($items | Where-Object {$_.type -eq 'file'} | ForEach-Object {$_.name}); $picked=@(); foreach($f in $allow){ if($names -contains $f){ $picked += $f } }; Write-Output ($picked -join ' ')" 2^>nul') do set "UPDATE_FILES=%%L"
exit /b 0

:apply_staged_self_update
if not exist "%SELF_NEXT%" exit /b 0
start "" /b cmd /c "ping 127.0.0.1 -n 2 >nul & copy /y \"%SELF_NEXT%\" \"%SELF_SCRIPT%\" >nul 2>&1 & del /f /q \"%SELF_NEXT%\" >nul 2>&1"
exit /b 0

:download_file
set "FILE_NAME=%~1"
set "OUT_FILE=%~2"
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $u='%REPO_RAW%/%FILE_NAME%'; $h=@{'User-Agent'='NoWin-Updater'}; if($env:NOWIN_GITHUB_TOKEN){$h['Authorization']='Bearer '+$env:NOWIN_GITHUB_TOKEN}; Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $h -OutFile '%OUT_FILE%'" >nul 2>&1
if errorlevel 1 exit /b 1
for %%Z in ("%OUT_FILE%") do if %%~zZ LSS 1 exit /b 1
exit /b 0

:install_task
call :require_admin || exit /b 1
call :ensure_log_dir >nul 2>&1
set "TASK_SCRIPT=%SCRIPT_DIR%AutoUpdate.bat"
if not exist "%TASK_SCRIPT%" set "TASK_SCRIPT=%~f0"
schtasks /create /tn "%TASK_NAME%" /tr "\"%TASK_SCRIPT%\" --run" /sc daily /st 03:30 /ru SYSTEM /rl HIGHEST /f >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Installation de la tache planifiee impossible.
    call :log "Task install failed"
    exit /b 1
)
echo [OK] Auto-update installe. Verification quotidienne a 03:30 (SYSTEM).
call :log "Task installed successfully"
exit /b 0

:uninstall_task
call :require_admin || exit /b 1
call :ensure_log_dir >nul 2>&1
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
if errorlevel 1 (
    echo [INFO] Tache non presente ou suppression impossible.
    call :log "Task uninstall: not found or failed"
    exit /b 1
)
echo [OK] Auto-update desinstalle.
call :log "Task removed successfully"
exit /b 0

:get_local_version
set "LOCAL_VERSION=0.0.0"
if exist "%LOCAL_VERSION_FILE%" (
    for /f "usebackq delims=" %%V in ("%LOCAL_VERSION_FILE%") do if not "%%V"=="" set "LOCAL_VERSION=%%V"
)
exit /b 0

:require_admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERREUR] Action admin requise. Lancez ce script en tant qu'administrateur.
    exit /b 1
)
exit /b 0

:ensure_log_dir
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
if not exist "%LOG_DIR%" set "LOG_DIR=%TEMP%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
set "LOG_FILE=%LOG_DIR%\autoupdate.log"
exit /b 0

:log
if not exist "%LOG_DIR%" call :ensure_log_dir >nul 2>&1
>> "%LOG_FILE%" echo [%date% %time%] %~1
if "%SILENT%"=="0" echo %~1
exit /b 0
