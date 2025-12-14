# NoWin - System Lockdown Suite v2.2

> **Ultimate Windows system restriction toolkit for managed environments (schools, kiosks, enterprise).**

---

## ⚠️ IMPORTANT: Windows Defender Alert

Windows Defender may detect these scripts as **"Ransomware"** - this is a **FALSE POSITIVE**.

The scripts use legitimate but aggressive techniques (IFEO redirects, BCD modification, file deletion) that trigger heuristic detection.

### Solution 1: Temporary Exclusion (Recommended)

Run this **in PowerShell as Administrator** BEFORE downloading the scripts:

```powershell
# Add exclusion for the download folder
Add-MpPreference -ExclusionPath "$env:USERPROFILE\Downloads\NoWin"
New-Item -ItemType Directory -Path "$env:USERPROFILE\Downloads\NoWin" -Force
```

### Solution 2: Disable Real-Time Protection Temporarily

```powershell
# Disable (requires admin)
Set-MpPreference -DisableRealtimeMonitoring $true

# Re-enable after running scripts
Set-MpPreference -DisableRealtimeMonitoring $false
```

---

## 📥 Installation (PowerShell)

**Open PowerShell as Administrator**, then run the desired command:

### Quick All-In-One Download
```powershell
$base = "https://raw.githubusercontent.com/LightZirconite/NoWin/main"
$dest = "$env:USERPROFILE\Downloads\NoWin"
New-Item -ItemType Directory -Path $dest -Force | Out-Null
@("Lockdown.bat","Unlock.bat","Verify.bat","UserLock.bat","UserUnlock.bat","force-update-agent.bat") | ForEach-Object {
    Invoke-WebRequest -Uri "$base/$_" -OutFile "$dest\$_"
    Write-Host "Downloaded: $_" -ForegroundColor Green
}
Write-Host "`nAll scripts downloaded to: $dest" -ForegroundColor Cyan
```

### Individual Scripts

**Lockdown (System Protection)**
```powershell
$dest = "$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $dest -Force | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Lockdown.bat" -OutFile "$dest\Lockdown.bat"
Start-Process -FilePath "$dest\Lockdown.bat" -Verb RunAs -Wait
```

**Unlock (System Restore)**
```powershell
$dest = "$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $dest -Force | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Unlock.bat" -OutFile "$dest\Unlock.bat"
Start-Process -FilePath "$dest\Unlock.bat" -Verb RunAs -Wait
```

**Verify (Status Check)**
```powershell
$dest = "$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $dest -Force | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/Verify.bat" -OutFile "$dest\Verify.bat"
Start-Process -FilePath "$dest\Verify.bat" -Verb RunAs -Wait
```

**UserLock (User Restriction)**
```powershell
$dest = "$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $dest -Force | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserLock.bat" -OutFile "$dest\UserLock.bat"
Start-Process -FilePath "$dest\UserLock.bat" -Verb RunAs -Wait
```

**UserUnlock (User Restore)**
```powershell
$dest = "$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $dest -Force | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/UserUnlock.bat" -OutFile "$dest\UserUnlock.bat"
Start-Process -FilePath "$dest\UserUnlock.bat" -Verb RunAs -Wait
```

**Force Update Agent (MeshCentral)**
```powershell
$dest = "$env:USERPROFILE\Downloads\NoWin"; New-Item -ItemType Directory -Path $dest -Force | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LightZirconite/NoWin/main/force-update-agent.bat" -OutFile "$dest\force-update-agent.bat"
Start-Process -FilePath "$dest\force-update-agent.bat" -Verb RunAs -Wait
```

---

## 📋 Script Details

### 🔒 Lockdown.bat (v2.2)
**Purpose:** Maximum system protection - blocks all recovery methods.

| Feature | Description |
|---------|-------------|
| WinRE Destruction | Deletes winre.wim, ReAgent.xml, corrupts recovery partition |
| BCD Hardening | Disables recovery, auto-repair, boot timeout=0 |
| USB/CD Block | Disables USBSTOR and cdrom services |
| IFEO Blocks | Blocks systemreset, rstrui, recoverydrive, dism, sfc, msconfig |
| Safe Mode Block | Removes safeboot options from BCD |
| Advanced Startup | Blocks Shift+Restart menu |
| System Restore | Disables VSS, shadow copies |
| Sleep/Hibernation | Completely disabled (PC always on) |
| Wake-on-LAN | Enabled for remote management (MeshCentral) |
| **WiFi Protection** | User can change networks but cannot disconnect completely |

### 🔓 Unlock.bat (v2.2)
**Purpose:** Completely reverses all Lockdown protections.

- Restores WinRE (if winre.wim provided next to script)
- Restores BCD to defaults
- Re-enables USB/CD
- Removes all IFEO blocks
- Restores System Restore, Safe Mode, etc.
- Restores Sleep/Hibernation (30min AC, 15min DC)
- Restores full WiFi control

### ✅ Verify.bat (v2.2)
**Purpose:** Complete security audit report (14 sections).

### 👤 UserLock.bat (v2.2)
**Purpose:** Demote user to standard with restrictions.

- Activates built-in Administrator (password: `uyy`)
- Removes current user from Administrators group
- Option to allow app installation with admin password
- Blocks: Control Panel, Task Manager, Registry, Run, Date/Time, AutoPlay

### 👤 UserUnlock.bat (v2.2)
**Purpose:** Restore full user privileges.

---

## 🔑 Default Credentials

| Account | Password |
|---------|----------|
| Built-in Administrator | `uyy` |

---

## 🛡️ Security Notes

### BIOS/UEFI Password
**Cannot be set via script.** You must manually:
1. Enter BIOS/UEFI setup (F2, F12, DEL at boot)
2. Set Supervisor/Admin password
3. Disable USB boot in boot order

### Remote Management
Designed for **MeshCentral**:
- Wake-on-LAN enabled
- Sleep/Hibernation disabled
- WiFi disconnect blocked

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Ransomware found" | Add Defender exclusion (see top) |
| "Cannot open file" | Use PowerShell, not CMD |
| Script won't elevate | Run PowerShell as Admin first |
| WinRE won't restore | Place valid `winre.wim` next to Unlock.bat |

---

## 📝 Version History

| Version | Changes |
|---------|---------|
| 2.2 | WiFi protection, UTF-8 encoding fix, PowerShell support |
| 2.1 | Sleep/Hibernation disable, Wake-on-LAN enable |
| 2.0 | Complete rewrite, enhanced WinRE destruction |
