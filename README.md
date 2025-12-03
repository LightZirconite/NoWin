# NoWin

**Lockdown (Securisation du systeme)**
Bloque WinRE, la reinitialisation, la restauration et masque les options de recuperation.
```cmd
curl -L -o Lockdown.bat https://raw.githubusercontent.com/LightZirconite/NoWin/main/Lockdown.bat && Lockdown.bat
```

**Unlock (Deverrouillage)**
Retablit WinRE, la reinitialisation, la restauration et les menus.
```cmd
curl -L -o Unlock.bat https://raw.githubusercontent.com/LightZirconite/NoWin/main/Unlock.bat && Unlock.bat
```

**Verify (Verification)**
Affiche un rapport complet sur l'etat de securite (WinRE, BCD, Registre, Utilisateurs).
```cmd
curl -L -o Verify.bat https://raw.githubusercontent.com/LightZirconite/NoWin/main/Verify.bat && Verify.bat
```

**UserLock (Securisation Utilisateur)**
Active le compte "Administrator" (mdp: uyy) et retire les droits admin de l'utilisateur courant.
```cmd
curl -L -o UserLock.bat https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserLock.bat && UserLock.bat
```

**UserUnlock (Restauration Utilisateur)**
Redonne les droits admin a l'utilisateur courant et desactive le compte "Administrator".
```cmd
curl -L -o UserUnlock.bat https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat && UserUnlock.bat
```