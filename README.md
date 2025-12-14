# NoWin - System Lockdown Suite v2.3

> Toolkit de restriction système Windows pour environnements gérés.

📖 [Documentation détaillée](DOCS.md)

---

## 🔒 Lockdown (Verrouillage Système)
Bloque WinRE, réinitialisation, Safe Mode, USB boot, WiFi disconnect.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Lockdown.bat" -OutFile "$p\Lockdown.bat"; if($?){Start-Process "$p\Lockdown.bat" -Verb RunAs; exit}else{Write-Host "ERREUR de telechargement" -ForegroundColor Red; pause}
```

## 🔓 Unlock (Déverrouillage)
Restaure toutes les fonctionnalités bloquées par Lockdown.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Unlock.bat" -OutFile "$p\Unlock.bat"; if($?){Start-Process "$p\Unlock.bat" -Verb RunAs; exit}else{Write-Host "ERREUR de telechargement" -ForegroundColor Red; pause}
```

## ✅ Verify (Vérification)
Affiche un rapport complet de l'état de sécurité.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Verify.bat" -OutFile "$p\Verify.bat"; if($?){Start-Process "$p\Verify.bat" -Verb RunAs; exit}else{Write-Host "ERREUR de telechargement" -ForegroundColor Red; pause}
```

## 👤 UserLock (Restriction Utilisateur)
Passe l'utilisateur en standard, installe le **Lanceur Admin** sur le bureau.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserLock.bat" -OutFile "$p\UserLock.bat"; if($?){Start-Process "$p\UserLock.bat" -Verb RunAs; exit}else{Write-Host "ERREUR de telechargement" -ForegroundColor Red; pause}
```

## 👤 UserUnlock (Restauration Utilisateur)
Restaure les droits admin, supprime le Lanceur Admin.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat" -OutFile "$p\UserUnlock.bat"; if($?){Start-Process "$p\UserUnlock.bat" -Verb RunAs; exit}else{Write-Host "ERREUR de telechargement" -ForegroundColor Red; pause}
```

## 🔄 Force Update Agent (MeshCentral)
Met à jour l'agent MeshCentral.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat" -OutFile "$p\force-update-agent.bat"; if($?){Start-Process "$p\force-update-agent.bat" -Verb RunAs; exit}else{Write-Host "ERREUR de telechargement" -ForegroundColor Red; pause}
```

---

## 📥 Télécharger Tout
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; $b="https://raw.githubusercontent.com/LightZirconite/NoWin/main"
New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue
@("Lockdown.bat","Unlock.bat","Verify.bat","UserLock.bat","UserUnlock.bat","AdminLauncher.bat","force-update-agent.bat")|%{Invoke-WebRequest "$b/$_" -OutFile "$p\$_"; Write-Host "OK: $_" -ForegroundColor Green}
```

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

**⚠️ Exécuter PowerShell en Administrateur** | **🔑 Mot de passe Admin:** `uyy`
