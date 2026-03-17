<#
.SYNOPSIS
Obtains a new Microsoft Entra access token for Microsoft Graph.

.DESCRIPTION
The New-GraphAccessToken function obtains a new access token from Microsoft Entra 
for use with Microsoft Graph. It supports two authentication methods:

1. App Registration (Client Credentials): Uses the client ID, tenant ID, and client 
secret that were previously stored by Get-GraphAccessToken. Utilizes the MSAL 
(Microsoft Authentication Library) to acquire the token.

2. Managed Identity: Uses an Azure Arc managed identity endpoint to acquire a token. 
This method is used in Azure Arc-enabled environments. The function extracts the 
authentication challenge from the endpoint and retrieves the token using Arc-specific 
endpoints.

The acquired token is stored in the script-scoped variable $script:graphAccessToken 
with AccessToken and ExpiresOn properties. This is a private/internal function that 
is called automatically by Test-AccessToken when token refresh is needed.

.OUTPUTS
None. The function stores the token in script-scoped variables.

.NOTES
This is an internal/private function that should not be called directly by users. 
It is called automatically by Test-AccessToken when the current token is expiring.

Prerequisites:
- The authentication method variables must have been set by Get-GraphAccessToken
  - For app registration: $script:client_id, $script:tenant_id, $script:client_secret
  - For managed identity: $script:ManagedIdentity = $true
- For managed identity, the IDENTITY_ENDPOINT environment variable must be set 
  (automatically set in Azure Arc environments)

The function requests the "https://graph.microsoft.com/.default" scope for app 
registration authentication, providing full access to Microsoft Graph.

The function requires either the MSAL PowerShell module or access to the Arc managed 
identity endpoint depending on the authentication method.
#>
function New-GraphAccessToken {
  [cmdletbinding()]
  param()
  if ($script:client_secret) {
    $msalToken = Get-MsalToken -ClientId $script:client_id -TenantId $Script:tenant_id -ClientSecret $script:client_secret -Scopes "https://graph.microsoft.com/.default"
    $script:graphAccessToken = @{
      AccessToken = $msalToken.AccessToken
      ExpiresOn   = $msalToken.ExpiresOn
    }    
  }
  elseif ($script:ManagedIdentity) {
    $apiVersion = "2020-06-01"
    $resource = "https://graph.microsoft.com"
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

    Write-Host "WWW-Authenticate: $wwwAuthHeader"

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
    $script:graphAccessToken = @{
      AccessToken = $tokenResponse.access_token
      ExpiresOn   = $tokenResponse.expires_on
    }
  }
  

}