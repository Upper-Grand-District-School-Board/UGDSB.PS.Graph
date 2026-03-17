<#
.SYNOPSIS
Low-level function to make REST API calls to Azure Key Vault.

.DESCRIPTION
The Get-KeyVaultAPI function provides the underlying REST API communication with 
Azure Key Vault. It constructs the Key Vault REST endpoint, handles authentication 
using the stored access token, and supports multiple HTTP methods for different 
operations. This is a private/internal function used by public Key Vault cmdlets 
like Get-KeyVaultSecret and Set-KeyVaultSecret.

The function uses Key Vault API version 7.4 and automatically includes the 
Authorization header with the current access token.

.PARAMETER vaultName
The name of the Azure Key Vault (without the .vault.azure.net domain).
This parameter is mandatory and cannot be empty.

.PARAMETER secretName
The name of the secret in the Key Vault.
This parameter is mandatory and cannot be empty.

.PARAMETER secretValue
The value to set for the secret. Required when using Put or Post methods 
to create or update a secret. This parameter is optional and only used when 
provided via -secretValue parameter.

.PARAMETER Method
The HTTP method to use for the API call.
Accepted values: Get, Post, Patch, Delete, Put
Defaults to "Get" if not specified.

.OUTPUTS
PSCustomObject
Returns an object with the following properties:
- StatusCode: The HTTP status code from the response
- Results: The response body from the Key Vault API

.EXAMPLE
PS> Get-KeyVaultAPI -vaultName "MyVault" -secretName "DBPassword"
Retrieves a secret from the vault using the default GET method.

.EXAMPLE
PS> Get-KeyVaultAPI -vaultName "MyVault" -secretName "DBPassword" -secretValue "NewPassword123" -Method Put
Creates or updates a secret in the vault using the PUT method.

.EXAMPLE
PS> Get-KeyVaultAPI -vaultName "MyVault" -secretName "OldSecret" -Method Delete
Deletes a secret from the vault using the DELETE method.

.NOTES
This is an internal/private function used by other Key Vault cmdlets. Direct 
calls to this function are typically not necessary as public cmdlets like 
Get-KeyVaultSecret and Set-KeyVaultSecret handle the appropriate method and 
parameter selection.

Requires a valid Key Vault access token stored in $script:keyVaultAccessToken. 
The token is automatically obtained and refreshed by Get-KeyVaultAccessToken 
and Test-KeyVaultAccessToken.
#>
function Get-KeyVaultAPI {
  [CmdletBinding()]
  [OutputType([System.Collections.Generic.List[PSCustomObject]])]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$vaultName,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$secretName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$secretValue,
    [Parameter()][ValidateSet("Get", "Post", "Patch", "Delete", "Put")][string]$Method = "Get"
  )
  $uri = "https://$($vaultName).vault.azure.net/secrets/$($secretName)?api-version=7.4"

  $params = @{
    Method = $Method
    uri = $uri
    headers = @{
      Authorization = "Bearer $($script:keyVaultAccessToken.AccessToken)"
      "Content-Type" = "application/json"
    }
  }

  if($PSBoundParameters.ContainsKey("secretValue")){
    $params.add("body", (@{value = $secretValue} | ConvertTo-JSON))
  }

  try {
    Write-Verbose "Calling API endpoint: $($uri)" 
    $results = Invoke-RestMethod @params
  }
  catch {
    throw $_
  }  
  return [PSCustomObject]@{
    StatusCode = $statusCode
    Results    = $results
  }
}