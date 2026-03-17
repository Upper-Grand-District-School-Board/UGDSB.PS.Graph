<#
.SYNOPSIS
Tests the validity of the current Key Vault access token.

.DESCRIPTION
The Test-KeyVaultAccessToken function checks whether a valid Key Vault access token 
exists and is not about to expire. If a token exists but is expiring within 5 minutes, 
the function automatically refreshes it by calling New-KeyVaultAccessToken. This is 
a private/internal function used by other Key Vault cmdlets to ensure valid authentication.

.OUTPUTS
System.Boolean
Returns $true if a valid Key Vault access token exists and is not expiring soon.
Returns $false if no access token has been obtained yet.

.EXAMPLE
PS> if (Test-KeyVaultAccessToken) { 
    Write-Host "Token is valid"
} else {
    Write-Host "Token is invalid or not initialized"
}
Tests the current Key Vault access token status.

.NOTES
This is an internal/private function used by other Key Vault cmdlets. It checks the 
script-scoped variable $script:keyVaultAccessToken. If the token is expired or expiring 
within 5 minutes, it automatically requests a new one. This function is called 
automatically by public Key Vault cmdlets before making API calls, so manual calls 
are typically not necessary.

The 5-minute refresh threshold ensures that token expiration does not occur during 
an API request.
#>
function Test-KeyVaultAccessToken {
  [CmdletBinding()]
  param()
  if(-not $script:keyVaultAccessToken){
    return $false
  }
  if($script:keyVaultAccessToken.ExpiresOn -lt (Get-Date).AddMinutes(5)) {
    New-KeyVaultAccessToken
  }
  return $true
}