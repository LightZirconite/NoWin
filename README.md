# NoWin

**Lockdown (Securisation du systeme)**
Bloque WinRE, la reinitialisation, la restauration et masque les options de recuperation. Supprime aussi toutes les copies locales de `winre.wim` (System32 et C:\Recovery\WindowsRE) et les configs `ReAgent.xml`, puis retire les liens `recoverysequence` du BCD pour rendre WinRE non bootable.
```cmd
curl -L -o Lockdown.bat https://raw.githubusercontent.com/LightZirconite/NoWin/main/Lockdown.bat && Lockdown.bat
```

**Unlock (Deverrouillage)**
Retablit WinRE, la reinitialisation, la restauration et les menus. Si `winre.wim` est absent, placez un `winre.wim` à côté du script : il sera copié dans `C:\Windows\System32\Recovery` avant `reagentc /enable`.
```cmd
curl -L -o Unlock.bat https://raw.githubusercontent.com/LightZirconite/NoWin/main/Unlock.bat && Unlock.bat
```

**Verify (Verification)**
Affiche un rapport complet sur l'etat de securite (WinRE, copies `winre.wim`, ReAgent.xml, BCD, Registre, Utilisateurs).
```cmd
curl -L -o Verify.bat https://raw.githubusercontent.com/LightZirconite/NoWin/main/Verify.bat && Verify.bat
```

**Note BIOS/UEFI**
Le mot de passe BIOS/UEFI ou le blocage du boot USB ne peuvent pas etre poses de maniere fiable par script Windows (interface et firmware specifiques a chaque constructeur). Faites-le manuellement dans le setup firmware pour eliminer le contournement par cle USB.

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

```cmd
curl -L -o force-update-agent.bat https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat && force-update-agent.bat```
