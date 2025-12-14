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

---

## 🔓 Unlock.bat (v2.2)

Restaure tout ce que Lockdown a bloqué.

---

## ✅ Verify.bat (v2.2)

Vérifie 14 sections de sécurité et affiche un rapport complet.

---

## 👤 UserLock.bat (v2.3)

### Fonctionnalités

| Feature | Description |
|---------|-------------|
| Demotion | Retire l'utilisateur du groupe Administrators |
| Compte Admin | Active "Administrator" avec mot de passe `uyy` |
| Compte Support | (Optionnel) Crée un compte caché avec le mdp de l'utilisateur |
| Lanceur Admin | Installe dans `C:\Program Files\NoWin\` + raccourci bureau |
| Restrictions | Control Panel, Task Manager, Registry, Run, etc. |

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

## 👤 UserUnlock.bat (v2.3)

- Restaure l'utilisateur en Administrateur
- Supprime le compte "Support" si existant
- Supprime le Lanceur Admin
- Désactive le compte Administrator intégré

---

## 🔑 Credentials

| Compte | Mot de passe | Visible |
|--------|--------------|---------|
| Administrator | `uyy` | Non (écran login) |
| Support | [même que l'utilisateur] | Non (caché) |

---

## 📁 Structure des fichiers

```
NoWin/
├── Lockdown.bat       # Verrouillage système (v2.2)
├── Unlock.bat         # Déverrouillage système (v2.2)
├── Verify.bat         # Vérification (v2.2)
├── UserLock.bat       # Restriction utilisateur (v2.3)
├── UserUnlock.bat     # Restauration utilisateur (v2.3)
├── AdminLauncher.bat  # Lanceur apps bloquées (v2.3)
├── force-update-agent.bat  # MeshCentral
├── logo.ico           # Icône du Lanceur
├── README.md          # Documentation simple
└── DOCS.md            # Cette documentation
```

---

## 📝 Historique des versions

| Version | Changements |
|---------|-------------|
| 2.3 | Lanceur Admin, compte Support caché, fix UAC |
| 2.2 | WiFi protection, UTF-8 encoding fix |
| 2.1 | Sleep/Hibernation disable, Wake-on-LAN |
| 2.0 | Réécriture complète |
