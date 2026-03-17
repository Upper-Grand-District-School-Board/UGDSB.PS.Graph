<#
.SYNOPSIS
Tests the validity of the current Microsoft Graph access token.

.DESCRIPTION
The Test-AccessToken function checks whether a valid Microsoft Graph access token 
exists and is not about to expire. If a token exists but is expiring within 5 minutes, 
the function automatically refreshes it by calling New-GraphAccessToken. This is 
a private/internal function used by other Microsoft Graph cmdlets to ensure valid 
authentication.

.OUTPUTS
System.Boolean
Returns $true if a valid Microsoft Graph access token exists and is not expiring soon.
Returns $false if no access token has been obtained yet.

.EXAMPLE
PS> if (Test-AccessToken) { 
    Write-Host "Token is valid"
} else {
    Write-Host "Token is invalid or not initialized"
}
Tests the current Microsoft Graph access token status.

.NOTES
This is an internal/private function used by other Microsoft Graph cmdlets. It checks 
the script-scoped variable $script:graphAccessToken. If the token is expired or 
expiring within 5 minutes, it automatically requests a new one. This function is 
called automatically by public Graph cmdlets before making API calls, so manual 
calls are typically not necessary.

The 5-minute refresh threshold ensures that token expiration does not occur during 
an API request.
#>
function Test-AccessToken {
  [CmdletBinding()]
  param()
  if(-not $script:graphAccessToken){
    return $false
  }
  if($script:graphAccessToken.ExpiresOn -lt (Get-Date).AddMinutes(5)) {
    New-GraphAccessToken
  }
  return $true
}