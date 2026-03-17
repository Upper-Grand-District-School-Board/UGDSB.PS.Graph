<#
.SYNOPSIS
Initializes or retrieves an Azure Key Vault access token.

.DESCRIPTION
The Get-KeyVaultAccessToken function initializes authentication to Azure Key Vault 
using either an app registration (service principal) or a managed identity. It stores 
the credentials in script-scoped variables and obtains a new access token if one is 
not already valid. If a valid token already exists, the function returns without 
requesting a new one.

.PARAMETER clientId
The client (application) ID of the Azure AD app registration.
Required when using the 'Appregistration' parameter set.
This parameter cannot be empty.

.PARAMETER tenantId
The Azure AD tenant ID.
Required for all parameter sets.
This parameter cannot be empty.

.PARAMETER clientSecret
The client secret of the Azure AD app registration.
Must be a SecureString object.
Required when using the 'Appregistration' parameter set.
This parameter cannot be empty.

.PARAMETER ManagedIdentity
Switch parameter to authenticate using a managed identity instead of 
app registration credentials. Used when running in Azure-hosted environments.
Required when using the 'ManagedIdentity' parameter set.

.OUTPUTS
None. The function initializes authentication and stores credentials in 
script-scoped variables.

.EXAMPLE
PS> $clientSecret = ConvertTo-SecureString -String "your-secret" -AsPlainText -Force
PS> Get-KeyVaultAccessToken -clientId "12345678-1234-1234-1234-123456789012" -tenantId "abcdefgh-1234-1234-1234-123456789abc" -clientSecret $clientSecret
Initializes Key Vault access using app registration credentials.

.EXAMPLE
PS> Get-KeyVaultAccessToken -tenantId "abcdefgh-1234-1234-1234-123456789abc" -ManagedIdentity
Initializes Key Vault access using a managed identity.

.NOTES
Once initialized, the authentication credentials are stored in script-scoped 
variables and reused by other Key Vault functions. Use Get-KeyVaultSecret 
or Set-KeyVaultSecret after calling this function.
#>
function Get-KeyVaultAccessToken {
  [cmdletbinding()]
  param(
    [parameter(Mandatory = $true, ParameterSetName="Appregistration")][ValidateNotNullOrEmpty()][string]$clientId,
    [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$tenantId,
    [parameter(Mandatory = $true, ParameterSetName="Appregistration")][ValidateNotNullOrEmpty()][secureString]$clientSecret,
    [Parameter(Mandatory = $true, ParameterSetName="ManagedIdentity")][switch]$ManagedIdentity
  )
  $script:client_id = $clientId
  $script:tenant_id = $tenantId
  if($PSBoundParameters.containsKey("clientSecret")){
    $script:client_secret = $clientSecret  
  }
  elseif($PSBoundParameters.containsKey("ManagedIdentity")){
    $script:ManagedIdentity = $true
  } 
  # Check to see if we have a valid session currently
  if (Test-KeyVaultAccessToken) {
    return
  }
  New-KeyVaultAccessToken
}