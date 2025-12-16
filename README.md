# NoWin v3.0 - System Lockdown Suite

📖 [Documentation complète](DOCS.md) | 🔑 **Mot de passe admin:** `uyy`

---

## 🔒 Lockdown - Bloquer réinitialisation PC

```powershell
# Avec confirmation
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Lockdown.bat" -OutFile "$p\Lockdown.bat"; Start-Process "$p\Lockdown.bat" -Verb RunAs
```

```powershell
# Mode silencieux (--yes)
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Lockdown.bat" -OutFile "$p\Lockdown.bat"; Start-Process "$p\Lockdown.bat" -ArgumentList "--yes" -Verb RunAs
```

## 🔓 Unlock - Restaurer système

⚠️ **Important** : Unlock ne peut PAS restaurer `winre.wim` automatiquement. Vous devez le copier depuis un média d'installation Windows.

```powershell
# Avec confirmation
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Unlock.bat" -OutFile "$p\Unlock.bat"; Start-Process "$p\Unlock.bat" -Verb RunAs
```

```powershell
# Mode silencieux (--yes)
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Unlock.bat" -OutFile "$p\Unlock.bat"; Start-Process "$p\Unlock.bat" -ArgumentList "--yes" -Verb RunAs
```

## ✅ Verify - Vérifier état système

```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Verify.bat" -OutFile "$p\Verify.bat"; Start-Process "$p\Verify.bat" -ArgumentList "--yes" -Verb RunAs
```

## 👤 UserLock - Restreindre utilisateur

```powershell
# Avec confirmation
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserLock.bat" -OutFile "$p\UserLock.bat"; Start-Process "$p\UserLock.bat" -Verb RunAs
```

```powershell
# Mode silencieux (--yes)
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserLock.bat" -OutFile "$p\UserLock.bat"; Start-Process "$p\UserLock.bat" -ArgumentList "--yes" -Verb RunAs
```

## 👤 UserUnlock - Restaurer droits admin

⚠️ **Recommandé** : Utilisez le mode `--yes` pour éviter que la fenêtre se ferme avant confirmation.

```powershell
# Mode silencieux (RECOMMANDÉ)
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat" -OutFile "$p\UserUnlock.bat"; Start-Process "$p\UserUnlock.bat" -ArgumentList "--yes" -Verb RunAs
```

```powershell
# Mode silencieux (--yes)
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat" -OutFile "$p\UserUnlock.bat"; Start-Process "$p\UserUnlock.bat" -ArgumentList "--yes" -Verb RunAs
```

## 🔄 Force Update Agent

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

## ⚙️ Usage

**Réappliquer après modifications :**
```
Unlock → Lockdown
UserUnlock → UserLock
```

**⚠️ Restauration WinRE après Unlock :**
1. Lockdown supprime `winre.wim` définitivement
2. Unlock ne peut PAS le restaurer automatiquement
3. Vous devez copier `winre.wim` depuis un média d'installation Windows
4. Voir instructions détaillées dans [DOCS.md](DOCS.md)

**Accès admin :**
- Utilisez le raccourci "Lanceur Admin" (créé par UserLock)
- Ou tapez `runas /user:Administrator cmd` (mdp: `uyy`)




