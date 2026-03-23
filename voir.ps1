# 1. Ta configuration (on la stocke dans une variable)
$configJson = @'
{
  "services": {
    "logs": {
      "endPoint": "https://facts.idf.hisqool.com/",
      "api_key": "U2FsdGVkX19hZDM4YWIwZolg60JX2lqIvQmpzEwl5LyFB8pzogLHmu7f0dkd5q5KTsmNLcdFzLHb9Frqb9Svcg/XDtEV0v/6AqxJy7OOewBjXoHegBhHNErHxO1HtKSh"
    },
    "api": {
      "endPoint": "https://idf.hisqool.com/graphql/v1/graphql"
    }
  }
}
'@ | ConvertFrom-Json

Write-Host "--- Diagnostic de la communication HiSqool ---" -ForegroundColor Cyan

# 2. Test du serveur de Logs (Télémétrie)
Write-Host "[*] Test du serveur de Logs..." -NoNewline
try {
    $logResponse = Invoke-WebRequest -Uri $configJson.services.logs.endPoint -Method Get -ErrorAction Stop
    Write-Host " OK (Code: $($logResponse.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host " ERREUR (Serveur injoignable ou accès refusé)" -ForegroundColor Red
}

# 3. Test de l'API GraphQL
Write-Host "[*] Test de l'API de configuration..." -NoNewline
$query = @{ query = "{ __typename }" } | ConvertTo-Json # Une requête simple pour dire "Bonjour"

try {
    $apiResponse = Invoke-RestMethod -Uri $configJson.services.api.endPoint -Method Post -Body $query -ContentType "application/json"
    Write-Host " CONNECTÉ" -ForegroundColor Green
    Write-Host "[!] Le serveur a répondu : $($apiResponse.data.__typename)" -ForegroundColor Yellow
} catch {
    Write-Host " ÉCHEC (L'API demande probablement un jeton de session)" -ForegroundColor Red
}

Write-Host "----------------------------------------------"
Write-Host "Analyse terminée. Appuie sur une touche pour quitter..."
$null = [System.Console]::ReadKey()