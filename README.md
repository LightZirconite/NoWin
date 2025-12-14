# NoWin - System Lockdown Suite v2.2

> Toolkit de restriction système Windows pour environnements gérés.

📖 [Documentation détaillée](DOCS.md)

---

## 🔒 Lockdown (Verrouillage Système)
Bloque WinRE, réinitialisation, Safe Mode, USB boot, WiFi disconnect.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Lockdown.bat" -OutFile "$p\Lockdown.bat"; Start-Process "$p\Lockdown.bat" -Verb RunAs
```

## 🔓 Unlock (Déverrouillage)
Restaure toutes les fonctionnalités bloquées par Lockdown.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Unlock.bat" -OutFile "$p\Unlock.bat"; Start-Process "$p\Unlock.bat" -Verb RunAs
```

## ✅ Verify (Vérification)
Affiche un rapport complet de l'état de sécurité.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Verify.bat" -OutFile "$p\Verify.bat"; Start-Process "$p\Verify.bat" -Verb RunAs
```

## 👤 UserLock (Restriction Utilisateur)
Passe l'utilisateur en standard, active le compte Admin (mdp: `uyy`).
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserLock.bat" -OutFile "$p\UserLock.bat"; Start-Process "$p\UserLock.bat" -Verb RunAs
```

## 👤 UserUnlock (Restauration Utilisateur)
Restaure les droits admin de l'utilisateur.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat" -OutFile "$p\UserUnlock.bat"; Start-Process "$p\UserUnlock.bat" -Verb RunAs
```

## 🔄 Force Update Agent (MeshCentral)
Met à jour l'agent MeshCentral.
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat" -OutFile "$p\force-update-agent.bat"; Start-Process "$p\force-update-agent.bat" -Verb RunAs
```

---

## 📥 Télécharger Tout
```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; $b="https://raw.githubusercontent.com/LightZirconite/NoWin/main"
New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue
@("Lockdown.bat","Unlock.bat","Verify.bat","UserLock.bat","UserUnlock.bat","force-update-agent.bat")|%{Invoke-WebRequest "$b/$_" -OutFile "$p\$_"; Write-Host "OK: $_" -ForegroundColor Green}
```

---

**⚠️ Exécuter PowerShell en Administrateur** | **🔑 Mot de passe Admin:** `uyy`
