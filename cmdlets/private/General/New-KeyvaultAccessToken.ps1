<#
.SYNOPSIS
Obtains a new Microsoft Entra access token for Azure Key Vault.

.DESCRIPTION
The New-KeyvaultAccessToken function obtains a new access token from Microsoft Entra 
for use with Azure Key Vault. It supports two authentication methods:

1. App Registration (Client Credentials): Uses the client ID, tenant ID, and client 
secret that were previously stored by Get-KeyVaultAccessToken. Utilizes the MSAL 
(Microsoft Authentication Library) to acquire the token.

2. Managed Identity: Uses an Azure Arc managed identity endpoint to acquire a token. 
This method is used in Azure Arc-enabled environments. The function extracts the 
authentication challenge from the endpoint and retrieves the token using Arc-specific 
endpoints.

The acquired token is stored in the script-scoped variable $script:keyVaultAccessToken 
with AccessToken and ExpiresOn properties. This is a private/internal function that 
is called automatically by Test-KeyVaultAccessToken when token refresh is needed.

.OUTPUTS
None. The function stores the token in script-scoped variables.

.NOTES
This is an internal/private function that should not be called directly by users. 
It is called automatically by Test-KeyVaultAccessToken when the current token is 
expiring. 

Prerequisites:
- The authentication method variables must have been set by Get-KeyVaultAccessToken
  - For app registration: $script:client_id, $script:tenant_id, $script:client_secret
  - For managed identity: $script:ManagedIdentity = $true
- For managed identity, the IDENTITY_ENDPOINT environment variable must be set 
  (automatically set in Azure Arc environments)

The function requires either the MSAL PowerShell module or access to the Arc managed 
identity endpoint depending on the authentication method.
#>

function New-KeyvaultAccessToken{
  [cmdletbinding()]
  param()
  if ($script:client_secret) {
    $msalToken = Get-MsalToken -ClientId $script:client_id -TenantId $Script:tenant_id -ClientSecret $script:client_secret -Scopes "https://vault.azure.net/.default"
    $script:keyVaultAccessToken = @{
      AccessToken = $msalToken.AccessToken
      ExpiresOn = $msalToken.ExpiresOn
    }  
  }
  elseif ($script:ManagedIdentity) {
    $apiVersion = "2020-06-01"
    $resource = "https://vault.azure.net"
    $endpoint = "$($env:IDENTITY_ENDPOINT)?resource=$([uri]::EscapeDataString($resource))&api-version=$apiVersion"

    try {
      $challengeResponse = Invoke-WebRequest -Method GET -Uri $endpoint -Headers @{ Metadata = 'True' } -SkipHttpErrorCheck
    }
    catch {
      throw "Failed to call Arc managed identity endpoint: $($_.Exception.Message)"
    }

    $wwwAuthHeader = $challengeResponse.Headers['WWW-Authenticate']

    if (-not $wwwAuthHeader) {
      throw "WWW-Authenticate header was not returned. Raw status: $($challengeResponse.StatusCode)"
    }

    # Extract path after Basic realm=
    $secretFile = $wwwAuthHeader -replace '^Basic realm=', ''
    $secretFile = $secretFile.Trim('"')

    if (-not (Test-Path $secretFile)) {
      throw "Challenge token file path was extracted but does not exist: $secretFile"
    }

    $secret = Get-Content -Raw -Path $secretFile
    $headers = @{
      Metadata      = 'True'
      Authorization = "Basic $secret"
    }

    $tokenResponse = Invoke-RestMethod -Method GET -Uri $endpoint -Headers $headers
    $script:keyVaultAccessToken = @{
      AccessToken = $tokenResponse.access_token
      ExpiresOn   = $tokenResponse.expires_on
    }
  }  
}