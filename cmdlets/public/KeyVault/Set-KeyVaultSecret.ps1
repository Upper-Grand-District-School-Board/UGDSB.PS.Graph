<#
.SYNOPSIS
Sets or creates a secret in Azure Key Vault.

.DESCRIPTION
The Set-KeyVaultSecret function creates a new secret or updates an existing 
secret in the specified Azure Key Vault. The function requires a valid Key Vault 
access token to be obtained before calling this cmdlet.

.PARAMETER vaultName
The name of the Azure Key Vault where the secret will be stored.
This parameter is mandatory and cannot be empty.

.PARAMETER secretName
The name of the secret to create or update.
This parameter is mandatory and cannot be empty.

.PARAMETER secretValue
The value of the secret.
This parameter is mandatory and cannot be empty.

.OUTPUTS
PSCustomObject
Returns the result object from the Key Vault API call.

.EXAMPLE
PS> Get-KeyVaultAccessToken
PS> Set-KeyVaultSecret -vaultName "MyVault" -secretName "DBPassword" -secretValue "P@ssw0rd123"
Creates or updates a secret named 'DBPassword' in the vault 'MyVault'.

.NOTES
Requires a valid Key Vault access token. Call Get-KeyVaultAccessToken or 
Test-KeyVaultAccessToken before using this cmdlet. The access token must 
be valid for the specified vault.
#>
function Set-KeyVaultSecret{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$vaultName,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$secretName,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$secretValue
  )
  if(!$(Test-KeyVaultAccessToken)){
    throw "Please Call Test-KeyVaultAccessToken before calling this cmdlet"
  }
  # Set a new secret value in the vault
  $results = Get-KeyVaultAPI -Method Put @PSBoundParameters
  return $results.Results
}