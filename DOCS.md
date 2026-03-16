# NoWin - Documentation Détaillée

[← Retour au README](README.md)

---

## 🌟 NoWin.bat (v4.2) - Orchestrateur Central

### Fonctionnalites

- Menu intelligent pour lancer tout l'ecosysteme.
- Mode commande directe (CLI) sans interface.
- Propagation de `--yes` vers les scripts compatibles (`Lockdown`, `Unlock`, `UserLock`, `UserUnlock`, `Verify`, `force-update-agent`).
- Integration AutoUpdate (check/update/install/uninstall) directement depuis NoWin.
- Pre-check AutoUpdate automatique en mode `--yes` (option `--skip-update` pour desactiver).

### Exemples CLI

- `NoWin.bat lockdown --yes`
- `NoWin.bat verify --yes`
- `NoWin.bat autoupdate-check`
- `NoWin.bat autoupdate-update --yes`
- `NoWin.bat watchdog-install`

---

## 🔒 Lockdown.bat (v3.0)

### Nouvelle Philosophie

**Focus : Empêcher la réinitialisation du PC UNIQUEMENT**

Les restrictions utilisateur (Control Panel, WiFi, etc.) ont été déplacées vers **UserLock.bat**.

### Fonctionnalités

| Section             | Description                                                           | Changement v3.0              |
| ------------------- | --------------------------------------------------------------------- | ---------------------------- |
| WinRE Destruction   | Supprime winre.wim sur **toutes les partitions** (C:, D:, E:, etc.)   | ✅ **Amélioré**              |
| BCD Hardening       | Désactive recovery, auto-repair, timeout=0 + **DisableStartupRepair** | ✅ **Renforcé**              |
| ~~USB/CD Block~~    | ~~Désactive les services USBSTOR et cdrom~~                           | ❌ **SUPPRIMÉ**              |
| IFEO Blocks         | Bloque systemreset, rstrui, recoverydrive, dism, sfc, msconfig        | ✅ Inchangé                  |
| Safe Mode Block     | Supprime les options safeboot du BCD                                  | ✅ Inchangé                  |
| Advanced Startup    | Bloque le menu Shift+Restart                                          | ✅ Inchangé                  |
| System Restore      | Désactive VSS, shadow copies                                          | ✅ Inchangé                  |
| Sleep/Hibernation   | Complètement désactivé (PC toujours allumé)                           | ✅ Inchangé                  |
| Wake-on-LAN         | Activé pour gestion à distance (MeshCentral)                          | ✅ Inchangé                  |
| ~~WiFi Protection~~ | ~~L'utilisateur peut changer de réseau mais pas se déconnecter~~      | ❌ **SUPPRIMÉ** (→ UserLock) |

---

## 🔓 Unlock.bat (v3.0)

Restaure **exactement** tout ce que Lockdown v3.0 a bloqué (symétrie parfaite).

### Changements v3.0

- ✅ Plus de restauration USB/CD (jamais bloqués)
- ✅ Plus de restauration WiFi (géré par UserUnlock)
- ✅ Correction des asymétries BCD (advancedoptions)

---

## ✅ Verify.bat (v3.0)

Vérifie 14 sections de sécurité et affiche un rapport complet.

### Changements v3.0

- ℹ️ Affiche maintenant que USB/CD ne sont plus bloqués par Lockdown
- ℹ️ Indique que WiFi3.0t géré par UserLock

---

## 👤 UserLock.bat (v2.3)

### Fonctionnalités

| Feature        | Description                                                   |
| -------------- | ------------------------------------------------------------- |
| Demotion       | Retire l'utilisateur du groupe Administrators                 |
| Compte Admin   | Active "Administrator" avec mot de passe `uyy`                |
| Compte Support | (Optionnel) Crée un compte caché avec le mdp de l'utilisateur |
| Lanceur Admin  | Installe dans `C:\Program Files\NoWin\` + raccourci bureau    |
| Restrictions   | Control Panel, Task Manager, Registry, Run, etc.              |

### Option Installation

- **O (Bloquer)** : Pas de compte "Support" → seul l'admin avec "uyy" peut installer
- **N (Autoriser)** : Crée le compte "Support" avec le mdp de l'utilisateur → l'utilisateur peut installer avec son propre mot de passe

### Lanceur Admin

Créé automatiquement sur le bureau public. Permet de lancer :

- Panneau de configuration
- Gestionnaire des tâches
- Éditeur de registre
- Gestionnaire de périphériques
- Paramètres Windows
- Connexions réseau
- Gestion de l'ordinateur
- Services Windows
- CMD / PowerShell (Admin)
- Et plus...

---

## 👤 UserUnlock.bat (v3.0)

### Changements v3.0

- ✅ **Correction majeure** : Détection utilisateur améliorée (cherche maintenant les utilisateurs standard)
- ✅ Affiche le statut actuel (déjà admin ou non)
- ✅ Fonctionne même si aucun utilisateur n'est connecté

### Fonctionnalités

- Restaure l'utilisateur en Administrateur
- Supprime le compte "Support" si existant
- Supprime le Lanceur Admin
- Désactive le compte Administrator intégré

---

## 🛡️ Watchdog.bat (v4.1)

### Fonctionnalites

- Auto-remediation des verrous critiques (registre)
- Execution planifiee en compte SYSTEM (`NoWin_Watchdog`)
- Verification manuelle possible
- Journalisation locale dans `C:\ProgramData\NoWin\system.log`

### Mode d'utilisation

- **Menu** : Via `NoWin.bat` option `Watchdog`
- **Direct** : `Watchdog.bat --install`, `--uninstall`

---

## 🔄 AutoUpdate.bat (v4.2)

### Fonctionnalites

- Detection de mise a jour via l'etat du depot GitHub (`pushed_at`)
- Selection dynamique des fichiers presents sur le depot (pas d'echec si un fichier n'existe pas)
- Mise a jour atomique avec sauvegarde (`backup\YYYYMMDD_HHMMSS`)
- Rollback automatique si copie partielle
- Planification quotidienne en compte SYSTEM (`NoWin_AutoUpdate`)
- Journalisation dans `C:\ProgramData\NoWin\autoupdate.log`

### Commandes directes

- `AutoUpdate.bat --check` : verifie les mises a jour
- `AutoUpdate.bat --update` : applique la mise a jour si disponible
- `AutoUpdate.bat --install` : installe la tache quotidienne
- `AutoUpdate.bat --uninstall` : supprime la tache

---

## 🔑 Credentials

| Compte        | Mot de passe             | Visible           |
| ------------- | ------------------------ | ----------------- |
| Administrator | `uyy`                    | Non (écran login) |
| Support       | [même que l'utilisateur] | Non (caché)       |

---

## 📁 Structure des fichiers

```
NoWin/
├── NoWin.bat          # 🌟 Manager central (Menu Intelligent v4.2)
├── AutoUpdate.bat     # 🔄 Auto-update GitHub + rollback + scheduler
├── VERSION            # Version locale interne (optionnelle)
├── Lockdown.bat       # Verrouillage système (v3.0)
├── Unlock.bat         # Déverrouillage système (v3.0)
├── Verify.bat         # Vérification (v3.0)
├── UserLock.bat       # Restriction utilisateur (v3.0)
├── UserUnlock.bat     # Restauration utilisateur (v3.0)
├── Watchdog.bat       # 🛡️ Auto-remediation et logs
├── AdminLauncher.bat  # Lanceur apps bloquées (v3.0)
├── UninstallAdmin.bat # Désinstallation AdminLauncher (v3.0)
├── force-update-agent.bat  # MeshCentral
├── logo.ico           # Icône du Lanceur
├── README.md          # Documentation simple
└── DOCS.md            # Cette documentation
```

---

## 📝 Historique des versions

| Version | Changements                                                                                                                                     |
| ------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| 4.2     | AutoUpdate robuste: detection via GitHub API (`pushed_at`), selection dynamique des fichiers distants, fiabilite amelioree sur depot public.    |
| 4.1     | AutoUpdate GitHub (versioning + backup + rollback + tache SYSTEM), Watchdog durci, integration menu NoWin.                                      |
| 4.0     | Ajout du **Smart Menu Manager centralisé** (`NoWin.bat`) permettant de gérer tout l'écosystème d'un seul endroit avec téléchargement dynamique. |
| 3.0     | Refonte complète Lockdown / Séparation avec UserLock                                                                                            |
| 2.2     | WiFi protection, UTF-8 encoding fix                                                                                                             |
| 2.1     | Sleep/Hibernation disable, Wake-on-LAN                                                                                                          |
| 2.0     | Réécriture complète                                                                                                                             |
