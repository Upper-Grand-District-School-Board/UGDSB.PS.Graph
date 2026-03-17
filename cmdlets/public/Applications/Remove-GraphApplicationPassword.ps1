<#
.SYNOPSIS
Removes a password credential from an Azure AD application.

.DESCRIPTION
The Remove-GraphApplicationPassword function removes a password (client secret) 
from a specified Azure AD application registration. This function requires a valid 
Microsoft Graph access token to be obtained before calling this cmdlet.

.PARAMETER objectId
The object ID of the Azure AD application from which to remove the password.
This parameter is mandatory and cannot be empty.

.PARAMETER secretKeyId
The key ID of the specific password credential to remove.
This parameter is mandatory and cannot be empty.

.PARAMETER beta
Switch parameter to use the Microsoft Graph beta endpoint instead of the 
production endpoint.

.OUTPUTS
None. The function returns no output on success. On failure, it throws an error.

.EXAMPLE
PS> Get-GraphAccessToken -clientId "12345678-1234-1234-1234-123456789012" -tenantId "abcdefgh-1234-1234-1234-123456789abc" -clientSecret $clientSecret
PS> Remove-GraphApplicationPassword -objectId "87654321-4321-4321-4321-210987654321" -secretKeyId "abc12345-1234-1234-1234-abcdefg12345"
Removes the specified password credential from the application.

.EXAMPLE
PS> Remove-GraphApplicationPassword -objectId "87654321-4321-4321-4321-210987654321" -secretKeyId "abc12345-1234-1234-1234-abcdefg12345" -beta
Removes the specified password credential from the application using the beta endpoint.

.NOTES
Requires a valid Microsoft Graph access token. Call Get-GraphAccessToken before 
using this cmdlet. The function expects a 204 (No Content) response from the API 
on success, which indicates the password was successfully removed.
#>

function Remove-GraphApplicationPassword{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$objectId,
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$secretKeyId,
    [Parameter()][switch]$beta
  )
  if(!$(Test-AccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  $endpoint = "applications/$($objectId)/removePassword"
  # Create body for request
  $body = @{
    keyId = $secretKeyId
  }
  # Call API Endpoint to create application
  try {
    $results = Get-GraphAPI -endpoint $endpoint -Method Post -body $body -beta:$beta.IsPresent -Verbose:$VerbosePreference
    if($results.StatusCode -ne 204){
      throw "Unable to remove password for appplication. $($results)"
    }
  }
  catch {
    throw $_
  } 
}