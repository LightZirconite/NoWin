# NoWin

**Lockdown (Securisation du systeme)**
Bloque WinRE, la reinitialisation, la restauration et masque les options de recuperation.
```powershell
irm https://raw.githubusercontent.com/LightZirconite/NoWin/main/Lockdown.bat | iex
```

**Unlock (Deverrouillage)**
Retablit WinRE, la reinitialisation, la restauration et les menus.
```powershell
irm https://raw.githubusercontent.com/LightZirconite/NoWin/main/Unlock.bat | iex
```

**Verify (Verification)**
Affiche un rapport complet sur l'etat de securite (WinRE, BCD, Registre, Utilisateurs).
```powershell
irm https://raw.githubusercontent.com/LightZirconite/NoWin/main/Verify.bat | iex
```

**UserLock (Securisation Utilisateur)**
Active le compte "Administrator" (mdp: uyy) et retire les droits admin de l'utilisateur courant.
```powershell
irm https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserLock.bat | iex
```

**UserUnlock (Restauration Utilisateur)**
Redonne les droits admin a l'utilisateur courant et desactive le compte "Administrator".
```powershell
irm https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat | iex
```