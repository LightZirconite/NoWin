# NoWin - Documentation Détaillée

[← Retour au README](README.md)

---

## 🔒 Lockdown.bat (v2.2)

### Fonctionnalités

| Section | Description |
|---------|-------------|
| WinRE Destruction | Supprime winre.wim, ReAgent.xml, corrompt la partition Recovery |
| BCD Hardening | Désactive recovery, auto-repair, timeout=0 |
| USB/CD Block | Désactive les services USBSTOR et cdrom |
| IFEO Blocks | Bloque systemreset, rstrui, recoverydrive, dism, sfc, msconfig |
| Safe Mode Block | Supprime les options safeboot du BCD |
| Advanced Startup | Bloque le menu Shift+Restart |
| System Restore | Désactive VSS, shadow copies |
| Sleep/Hibernation | Complètement désactivé (PC toujours allumé) |
| Wake-on-LAN | Activé pour gestion à distance (MeshCentral) |
| WiFi Protection | L'utilisateur peut changer de réseau mais pas se déconnecter |

### Exécutables bloqués (IFEO)
- `systemreset.exe` - Réinitialisation système
- `rstrui.exe` - Restauration système
- `recoverydrive.exe` - Création lecteur de récupération
- `srtasks.exe` - Push Button Reset
- `ReAgentc.exe` - Configuration WinRE
- `msconfig.exe` - Configuration système
- `dism.exe` - Deployment Image Servicing
- `sfc.exe` - System File Checker
- `netsh.exe` - Configuration réseau (pour WiFi lock)

---

## 🔓 Unlock.bat (v2.2)

### Restaurations effectuées
- WinRE (si `winre.wim` fourni à côté du script)
- Configuration BCD par défaut
- USB/CD réactivés
- Tous les blocs IFEO supprimés
- System Restore, Safe Mode, Advanced Startup
- Sleep/Hibernation (30min AC, 15min batterie)
- Contrôle WiFi complet

### Restaurer WinRE manuellement
Si `winre.wim` est absent, placez-en un à côté de `Unlock.bat`.

**Source:** ISO Windows → `sources\install.wim` → extraire `Windows\System32\Recovery\winre.wim`

---

## ✅ Verify.bat (v2.2)

### Sections vérifiées (14)
1. État WinRE
2. Configuration BCD
3. USB/Boot externe
4. Blocs IFEO (10+ exécutables)
5. État System Restore
6. Accès Safe Mode
7. Options Advanced Startup
8. Accès CMD Recovery
9. Visibilité UI (pages Settings)
10. Restrictions utilisateur
11. Installation périphériques
12. Power/Sleep/Wake-on-LAN
13. **Protection WiFi**
14. Résumé avec scores

---

## 👤 UserLock.bat (v2.2)

### Actions effectuées
- Active le compte Administrator intégré (mdp: `uyy`)
- Retire l'utilisateur courant du groupe Administrators
- Configure UAC selon le choix (installation apps avec mdp admin ou non)

### Restrictions appliquées
| Restriction | Clé registre |
|-------------|--------------|
| Panneau de configuration | `NoControlPanel` |
| Gestionnaire des tâches | `DisableTaskMgr` |
| Éditeur de registre | `DisableRegistryTools` |
| Boîte Exécuter | `NoRun` |
| Date/Heure | `NoDateTimeControlPanel` |
| Mode développeur | `ApplicationManagement` |
| Propriétés système | `NoPropertiesMyComputer` |
| AutoPlay | `NoDriveTypeAutoRun` |
| Windows Script Host | `Enabled=0` |
| Bureau à distance | `fDenyTSConnections` |

### Prompts interactifs
1. **Confirmation O/N** avant de procéder
2. **Option installation** - Permet d'installer des apps avec le mot de passe admin

---

## 👤 UserUnlock.bat (v2.2)

### Actions effectuées
- Promeut l'utilisateur au groupe Administrators
- Supprime toutes les restrictions de UserLock
- Désactive le compte Administrator intégré

---

## 🔑 Credentials

| Compte | Mot de passe |
|--------|--------------|
| Administrator intégré | `uyy` |

---

## 🛡️ Sécurité BIOS/UEFI

**Ne peut PAS être configuré par script.** Actions manuelles requises :

1. Entrer dans le setup BIOS/UEFI (F2, F12, DEL au démarrage)
2. Définir un mot de passe Superviseur/Admin
3. Désactiver le boot USB dans l'ordre de démarrage
4. Activer Secure Boot

---

## 📡 Gestion à distance (MeshCentral)

Ces scripts sont optimisés pour MeshCentral :
- **Wake-on-LAN activé** - Réveiller le PC à distance
- **Sleep/Hibernation désactivé** - PC toujours disponible
- **WiFi disconnect bloqué** - Utilisateur ne peut pas se déconnecter

---

## 🔧 Dépannage

| Problème | Solution |
|----------|----------|
| "Ransomware found" | L'exclusion Defender est incluse dans les commandes |
| "Cannot open file" | Utiliser PowerShell, pas CMD |
| Script ne s'élève pas | Lancer PowerShell en Admin d'abord |
| WinRE ne se restaure pas | Placer un `winre.wim` valide à côté de Unlock.bat |
| WiFi toujours accessible | Redémarrer Explorer ou le PC |

---

## 📝 Historique des versions

| Version | Changements |
|---------|-------------|
| 2.2 | Protection WiFi, fix encodage UTF-8, support PowerShell, exclusion Defender intégrée |
| 2.1 | Désactivation Sleep/Hibernation, Wake-on-LAN |
| 2.0 | Réécriture complète, destruction WinRE améliorée |
| 1.0 | Version initiale |

---

## ⚖️ Avertissement légal

Ces scripts sont destinés à l'**administration système légitime** :
- Environnements d'entreprise gérés
- Ordinateurs d'écoles/bibliothèques
- Systèmes kiosque
- Contrôle parental

**NE PAS UTILISER** à des fins malveillantes.
