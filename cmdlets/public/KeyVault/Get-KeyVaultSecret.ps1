<#
.SYNOPSIS
Retrieves a secret from Azure Key Vault.

.DESCRIPTION
The Get-KeyVaultSecret function retrieves a secret value from a specified 
Azure Key Vault. The function requires a valid Key Vault access token to 
be obtained before calling this cmdlet.

.PARAMETER vaultName
The name of the Azure Key Vault from which to retrieve the secret.
This parameter is mandatory and cannot be empty.

.PARAMETER secretName
The name of the secret to retrieve.
This parameter is mandatory and cannot be empty.

.OUTPUTS
PSCustomObject
Returns the result object containing the secret value from the Key Vault API call.

.EXAMPLE
PS> Get-KeyVaultAccessToken
PS> Get-KeyVaultSecret -vaultName "MyVault" -secretName "DBPassword"
Retrieves the 'DBPassword' secret from the 'MyVault' Key Vault.

.NOTES
Requires a valid Key Vault access token. Call Get-KeyVaultAccessToken or 
Test-KeyVaultAccessToken before using this cmdlet. The access token must 
be valid for the specified vault.
#>
function Get-KeyVaultSecret{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$vaultName,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$secretName
  )
  if(!$(Test-KeyVaultAccessToken)){
    throw "Please Call Test-KeyVaultAccessToken before calling this cmdlet"
  }
  $results = Get-KeyVaultAPI @PSBoundParameters
  return $results.Results
}