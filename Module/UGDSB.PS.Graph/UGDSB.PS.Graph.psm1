#Region '.\Public\Get-GraphAccessToken.ps1' -1

<#
.SYNOPSIS
Initializes or retrieves a Microsoft Graph access token.

.DESCRIPTION
The Get-GraphAccessToken function initializes authentication to Microsoft Graph 
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
PS> Get-GraphAccessToken -clientId "12345678-1234-1234-1234-123456789012" -tenantId "abcdefgh-1234-1234-1234-123456789abc" -clientSecret $clientSecret
Initializes Microsoft Graph access using app registration credentials.

.EXAMPLE
PS> Get-GraphAccessToken -tenantId "abcdefgh-1234-1234-1234-123456789abc" -ManagedIdentity
Initializes Microsoft Graph access using a managed identity.

.NOTES
Once initialized, the authentication credentials are stored in script-scoped 
variables and reused by other Microsoft Graph functions. Use Get-GraphUser, 
Get-GraphApplications, or other Graph cmdlets after calling this function.
#>
function Get-GraphAccessToken {
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
  if (Test-AccessToken) {
    return
  }
  New-GraphAccessToken
}
#EndRegion '.\Public\Get-GraphAccessToken.ps1' 73
#Region '.\Public\Get-GraphAPI.ps1' -1

<#
.SYNOPSIS
Low-level function to make REST API calls to Microsoft Graph.

.DESCRIPTION
The Get-GraphAPI function provides the underlying REST API communication with 
Microsoft Graph. It constructs the Graph endpoint URI, handles authentication 
using the stored access token, manages request headers, and supports multiple 
HTTP methods for different operations. This is a private/internal function used 
by public Microsoft Graph cmdlets like Get-GraphUser, Get-GraphApplications, 
and others.

The function defaults to the production endpoint (v1.0) but can use the beta 
endpoint if the -beta switch is specified. It automatically includes the 
Authorization and Content-Type headers, and optionally includes ConsistencyLevel 
for advanced queries.

.PARAMETER endpoint
The Microsoft Graph API endpoint or resource path to call (without the domain prefix).
Example: "users", "applications", "users/{id}/messages"
This parameter is mandatory and cannot be empty.

.PARAMETER Method
The HTTP method to use for the API call.
Accepted values: Get, Post, Patch, Delete, Put
Defaults to "Get" if not specified.

.PARAMETER body
The request body as a PowerShell object. It will be automatically converted to JSON 
with a depth of 10 levels. This parameter is optional and only required for methods 
that send data (Post, Patch, Put).

.PARAMETER beta
Switch parameter to use the Microsoft Graph beta endpoint (beta/) instead of the 
production endpoint (v1.0/). Use for new or experimental features.

.PARAMETER ConsistencyLevel
Switch parameter to include the ConsistencyLevel header with value 'eventual'. 
Required when using advanced query operators like $search or orderBy on 
non-indexed properties.

.OUTPUTS
PSCustomObject
Returns an object with the following properties:
- StatusCode: The HTTP status code from the response
- Results: The response body from the Microsoft Graph API

.EXAMPLE
PS> Get-GraphAPI -endpoint "users"
Retrieves all users from Microsoft Graph using the default GET method.

.EXAMPLE
PS> Get-GraphAPI -endpoint "users?`$filter=displayName eq 'John Doe'"
Retrieves users filtered by display name.

.EXAMPLE
PS> $body = @{ displayName = "NewApp" }
PS> Get-GraphAPI -endpoint "applications" -Method Post -body $body
Creates a new application in Azure AD using POST method.

.EXAMPLE
PS> Get-GraphAPI -endpoint "users?`$search=`"displayName:john`"" -ConsistencyLevel
Searches for users by display name using the ConsistencyLevel header for eventual consistency.

.EXAMPLE
PS> Get-GraphAPI -endpoint "users" -beta
Retrieves users from the Microsoft Graph beta endpoint.

.NOTES
This is an internal/private function used by other Microsoft Graph cmdlets. 
Direct calls to this function are typically not necessary as public cmdlets 
handle the appropriate endpoint construction and parameter selection.

Requires a valid Microsoft Graph access token stored in $script:graphAccessToken. 
The token is automatically obtained and refreshed by Get-GraphAccessToken and 
Test-AccessToken.

The function constructs URIs in the format:
- Production: https://graph.microsoft.com/v1.0/{endpoint}
- Beta: https://graph.microsoft.com/beta/{endpoint}
#>
function Get-GraphAPI {
  [CmdletBinding()]
  [OutputType([System.Collections.Generic.List[PSCustomObject]])]
  param(
    [Parameter(Mandatory = $true)][string]$endpoint,
    [Parameter()][ValidateSet("Get", "Post", "Patch", "Delete", "Put")][string]$Method = "Get",
    [Parameter()][ValidateNotNullOrEmpty()]$body,
    [Parameter()][switch]$beta,
    [Parameter()][switch]$ConsistencyLevel
  )
  # Build the headers we will use to get users
  $ConsistencyLevelHeader = @{}
  if ($PSBoundParameters.ContainsKey("ConsistencyLevel")) {
    $ConsistencyLevelHeader.Add("ConsistencyLevel", $true) | Out-Null
  }  
  $headers = Get-GraphHeader @ConsistencyLevelHeader

  $uri = "https://graph.microsoft.com/v1.0/"
  if ($PSBoundParameters.ContainsKey("beta") -and $beta) { 
    $uri = $uri -replace "v1.0", "beta"
  }
  $uri = "$($uri)$($endpoint)"
  try {
    $Vars = @{
      Method             = $Method
      Uri                = $uri
      StatusCodeVariable = 'statusCode'
      headers            = $headers
    }
    if ($PSBoundParameters.ContainsKey("body")) { 
      $vars.add("body", ($body | ConvertTo-JSON -Depth 10))
    }
    Write-Verbose "Calling API endpoint: $($uri)" 
    $results = Invoke-RestMethod @Vars
    
  }
  catch {
    throw $_
  }
  return [PSCustomObject]@{
    StatusCode = $statusCode
    Results    = $results
  } 
}
#EndRegion '.\Public\Get-GraphAPI.ps1' 126
#Region '.\Public\Get-GraphApplications.ps1' -1

<#
.SYNOPSIS
Retrieves Azure AD applications from Microsoft Graph.

.DESCRIPTION
The Get-GraphApplications function retrieves application registrations from Microsoft Graph. 
It supports multiple query options including filtering by application ID, app ID, display name, 
or custom OData filters. Results can be paginated to retrieve all applications. By default, 
only the first page of results is returned unless the -all switch is specified.

.PARAMETER id
The object ID of a specific application to retrieve. This parameter is part of the 'id' 
parameter set and is mutually exclusive with other filter parameters.

.PARAMETER appId
The application (client) ID to search for. This parameter is part of the 'appid' 
parameter set and is mutually exclusive with other filter parameters.

.PARAMETER displayName
The display name or beginning of the display name to search for. Uses a 'startsWith' 
filter. This parameter is part of the 'displayName' parameter set and is mutually 
exclusive with other filter parameters.

.PARAMETER filter
A custom OData filter query parameter for advanced filtering. This parameter is part 
of the 'filter' parameter set and is mutually exclusive with other filter parameters.
Example: "createdDateTime gt 2023-01-01T00:00:00Z"

.PARAMETER all
Switch parameter to retrieve all applications. When specified, paginates through 
all results. By default, only the first page is returned.

.PARAMETER fields
Comma-separated list of application properties to return. Corresponds to the OData 
$select parameter. If not specified, all default properties are returned.

.PARAMETER beta
Switch parameter to use the Microsoft Graph beta endpoint instead of the 
production endpoint.

.OUTPUTS
System.Collections.Generic.List[PSCustomObject]
Returns a list of application objects from Microsoft Graph. Each object contains 
properties such as id, appId, displayName, createdDateTime, etc.

.EXAMPLE
PS> Get-GraphAccessToken -clientId "12345678-1234-1234-1234-123456789012" -tenantId "abcdefgh-1234-1234-1234-123456789abc" -clientSecret $clientSecret
PS> Get-GraphApplications -all
Retrieves all applications in the tenant.

.EXAMPLE
PS> Get-GraphApplications -displayName "MyApp"
Retrieves applications with display names starting with 'MyApp'.

.EXAMPLE
PS> Get-GraphApplications -appId "12345678-1234-1234-1234-123456789012"
Retrieves the specific application with the given app ID.

.EXAMPLE
PS> Get-GraphApplications -displayName "MyApp" -fields "id,appId,displayName,createdDateTime"
Retrieves applications starting with 'MyApp' and returns only the specified properties.

.EXAMPLE
PS> Get-GraphApplications -filter "createdDateTime gt 2023-01-01T00:00:00Z" -all
Retrieves all applications created after January 1, 2023.

.NOTES
Requires a valid Microsoft Graph access token. Call Get-GraphAccessToken before 
using this cmdlet. When pagination is enabled with the -all switch, the function 
makes multiple API calls to retrieve all results.
#>

function Get-GraphApplications{
  [CmdletBinding(DefaultParameterSetName = "All")]
  param(
    [Parameter(ParameterSetName = 'id')][validatenotnullorempty()][string]$id,
    [Parameter(ParameterSetName = 'appid')][validatenotnullorempty()][string]$appId,
    [Parameter(ParameterSetName = 'displayName')][validatenotnullorempty()][string]$displayName,
    [Parameter(ParameterSetName = 'filter')][ValidateNotNullOrEmpty()][string]$filter,
    [Parameter()][switch]$all,
    [Parameter()][ValidateNotNullOrEmpty()][string]$fields,
    [Parameter()][switch]$beta
  )
  if(!$(Test-AccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  $endpoint = "applications"
  $uriparts = [System.Collections.Generic.List[PSCustomObject]]@()  
  if($PSBoundParameters.ContainsKey("id")) {$uriparts.add("`$filter=id -eq '$($id)'")}
  if($PSBoundParameters.ContainsKey("appId")){$uriparts.add("`$filter=appId -eq '$($appId)'")}
  if ($PSBoundParameters.ContainsKey("displayName")) {$uriparts.add("`$filter=startsWith(displayName,'$($displayName)')")}
  if ($PSBoundParameters.ContainsKey("filter")) {$uriparts.add("`$filter=$($filter)")}
  if ($PSBoundParameters.ContainsKey("fields")) {$uriparts.add("`$select=$($fields)")}
  # Generate the final API endppoint URI
  $endpoint = "$($endpoint)?$($uriparts -join "&")" 
  try {
    # Create empty list
    $applications = [System.Collections.Generic.List[PSCustomObject]]@()    
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -beta:$beta.IsPresent -Verbose:$VerbosePreference
      # Add results to a list variable
      foreach ($item in $results.results.value) {
        $applications.Add($item) | Out-Null
      }
      Write-Verbose "Returned $($results.results.value.Count) results. Current result set is $($applications.Count) items." 
      if ($results.results."@odata.nextLink") {
        $uri = [REGEX]::Match($results.results."@odata.nextLink", "applications.*").Value
      }
    }while ($null -ne $results.results."@odata.nextLink" -and $all.IsPresent)
  }
  catch {
    throw "Unable to get applications. $($_.Exception.Message)"
  } 
  if($applications.count -eq 0){
    return $results
  }
  else{
    # Return the group list if it exists
    return $applications
  }
}
#EndRegion '.\Public\Get-GraphApplications.ps1' 124
#Region '.\Public\Get-GraphHeader.ps1' -1

<#
.SYNOPSIS
Constructs HTTP headers for Microsoft Graph API requests.

.DESCRIPTION
The Get-GraphHeader function creates a hashtable of HTTP headers required for 
making requests to Microsoft Graph. It automatically includes the Authorization 
header with the current access token and sets the Content-Type to application/json. 
Optionally, it can include the ConsistencyLevel header for advanced queries that 
require eventual consistency semantics. This is a private/internal function used 
by other Microsoft Graph cmdlets.

.PARAMETER ConsistencyLevel
Switch parameter to include the ConsistencyLevel header with value 'eventual'. 
This is required when using advanced query operators like $search, $orderby on 
non-indexed properties, or other queries that need eventual consistency semantics.

.OUTPUTS
System.Collections.Hashtable
Returns a hashtable containing the HTTP headers. By default includes:
- Authorization: Bearer token for authentication
- Content-Type: application/json

When ConsistencyLevel switch is used, also includes:
- ConsistencyLevel: eventual

.EXAMPLE
PS> $headers = Get-GraphHeader
PS> $headers
Name                           Value
----                           -----
Authorization                 Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type                   application/json

Retrieves standard Graph API headers.

.EXAMPLE
PS> $headers = Get-GraphHeader -ConsistencyLevel
PS> $headers
Name                           Value
----                           -----
Authorization                 Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type                   application/json
ConsistencyLevel               eventual

Retrieves Graph API headers with ConsistencyLevel for advanced queries.

.NOTES
This is an internal/private function used by other Microsoft Graph cmdlets. 
It is called by functions like Get-GraphUser and Get-GraphApplications to 
construct the headers for API requests.

Requires a valid Microsoft Graph access token stored in $script:graphAccessToken. 
The ConsistencyLevel header should be used with advanced query operators that 
require eventual consistency, such as $search on resources that don't have 
indexed properties.
#>

function Get-GraphHeader{
  [CmdletBinding()]
  param(
    [Parameter()][switch]$ConsistencyLevel
  )  
  # Base header variables
  $headerVars = @{
    Authorization = "Bearer $($script:graphAccessToken.AccessToken)"
    "Content-Type" = "application/json"
  }
  # If flagged to include the Consitency Level header
  if($ConsistencyLevel.IsPresent){
    $headerVars.Add("ConsistencyLevel","eventual")
  }
  return $headerVars  
}
#EndRegion '.\Public\Get-GraphHeader.ps1' 75
#Region '.\Public\Get-GraphUser.ps1' -1

<#
.SYNOPSIS
Retrieves Microsoft Graph user information.

.DESCRIPTION
The Get-GraphUser function retrieves user information from Microsoft Graph. 
It supports multiple query options including filtering by user principal name, 
user ID, or using advanced query parameters.

.PARAMETER userPrincipalName
The user principal name (UPN) of the user to retrieve. This parameter is 
mutually exclusive with userid.

.PARAMETER userid
The unique identifier (ID) of the user to retrieve. This parameter is 
mutually exclusive with userPrincipalName.

.PARAMETER All
Switch parameter to retrieve all users. When specified, paginates through 
all results if available.

.PARAMETER ConsistencyLevel
Switch parameter to request consistent data reads. Used with advanced queries.

.PARAMETER Count
Switch parameter to include the count of matching results in the response.

.PARAMETER filter
OData filter query parameter to filter results. Example: "startsWith(displayName,'John')"

.PARAMETER select
OData select query parameter to specify which properties to return.

.PARAMETER beta
Switch parameter to use the Microsoft Graph beta endpoint instead of the 
production endpoint.

.OUTPUTS
System.Collections.Generic.List[PSCustomObject]
Returns a list of user objects from Microsoft Graph.

.EXAMPLE
PS> Get-GraphAccessToken
PS> Get-GraphUser -All
Retrieves all users from Microsoft Graph.

.EXAMPLE
PS> Get-GraphUser -userPrincipalName "john.doe@example.com"
Retrieves a specific user by user principal name.

.EXAMPLE
PS> Get-GraphUser -filter "startsWith(displayName,'John')" -select "displayName,mail"
Retrieves users whose display name starts with 'John', returning only 
displayName and mail properties.

.NOTES
Requires an active Microsoft Graph access token. Call Get-GraphAccessToken 
before using this cmdlet.
#>

function Get-GraphUser{
  [CmdletBinding(DefaultParameterSetName = "All")]
  [OutputType([System.Collections.Generic.List[PSCustomObject]])]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = 'userPrincipalName')][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Parameter(Mandatory = $true, ParameterSetName = 'userid')][ValidateNotNullOrEmpty()][string]$userid,
    [Parameter()][switch]$All,
    [Parameter()][switch]$ConsistencyLevel,
    [Parameter()][switch]$Count,
    [Parameter()][ValidateNotNullOrEmpty()][string]$filter,
    [Parameter()][ValidateNotNullOrEmpty()][string]$select,
    [Parameter()][switch]$beta
  )
  if(!$(Test-AccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Base URI for resource call
  $endpoint = "users"
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) {
    # Filter based on group name is required
    $endpoint = "$($endpoint)/$($userPrincipalName)"    
  }
  elseif ($PSBoundParameters.ContainsKey("userid")) {
    $endpoint = "$($endpoint)/$($userid)"
  }
  # Get Query Parameters
  $uriparts = [System.Collections.Generic.List[PSCustomObject]]@()
  if ($PSBoundParameters.ContainsKey("filter")) { $uriparts.add("`$filter=$($filter)") }
  if ($PSBoundParameters.ContainsKey("select")) { $uriparts.add("`$select=$($select)") }
  if ($PSBoundParameters.ContainsKey("count")) { $uriparts.add("`$count=true") }
  # Generate the final API endppoint URI
  $endpoint = "$($endpoint)?$($uriparts -join "&")"   
  # Create empty list
  $userList = [System.Collections.Generic.List[PSCustomObject]]@()  
  try {
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -beta:$beta.IsPresent -ConsistencyLevel:$ConsistencyLevel.IsPresent -Verbose:$VerbosePreference
      # Add results to a list variable
      foreach ($item in $results.results.value) {
        $userList.Add($item) | Out-Null
      }
      Write-Verbose "Returned $($results.results.value.Count) results. Current result set is $($userList.Count) items." 
      if ($results.results."@odata.nextLink") {
        $uri = [REGEX]::Match($results.results."@odata.nextLink", "users.*").Value
      }
    }while ($null -ne $results.results."@odata.nextLink" -and $all.IsPresent)
  }
  catch {
    throw "Unable to get users. $($_.Exception.Message)"
  } 
  # If there is only one result, return that
  if ($userList.count -eq 0) {
    return $results.Results
  }
  else {
    # Return the group list if it exists
    return $userList
  }  
}
#EndRegion '.\Public\Get-GraphUser.ps1' 122
#Region '.\Public\Get-KeyVaultAccessToken.ps1' -1

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
#EndRegion '.\Public\Get-KeyVaultAccessToken.ps1' 73
#Region '.\Public\Get-KeyVaultAPI.ps1' -1

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
#EndRegion '.\Public\Get-KeyVaultAPI.ps1' 97
#Region '.\Public\Get-KeyVaultSecret.ps1' -1

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
#EndRegion '.\Public\Get-KeyVaultSecret.ps1' 44
#Region '.\Public\New-GraphAccessToken.ps1' -1

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
#EndRegion '.\Public\New-GraphAccessToken.ps1' 95
#Region '.\Public\New-GraphApplicationPassword.ps1' -1

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
function New-GraphApplicationPassword{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$objectId,
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$secretName,
    [Parameter()][datetime]$secretExpiry = (Get-Date).AddYears(1),
    [Parameter()][switch]$beta
  )
  if(!$(Test-AccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  $endpoint = "applications/$($objectId)/addPassword"
  # Create body for request
  $body = @{
    passwordCredential = @{
      displayName = $secretName
      endDateTime = $secretExpiry.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
  }
  # Call API Endpoint to create application
  try {
    $results = Get-GraphAPI -endpoint $endpoint -Method Post -body $body -beta:$beta.IsPresent -Verbose:$VerbosePreference
    if($results.StatusCode -ne 200){
      throw "Unable to create password for appplication. $($results)"
    }
  }
  catch {
    throw $_
  }
  return $results.Results   
}
#EndRegion '.\Public\New-GraphApplicationPassword.ps1' 70
#Region '.\Public\New-KeyvaultAccessToken.ps1' -1

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
#EndRegion '.\Public\New-KeyvaultAccessToken.ps1' 90
#Region '.\Public\Remove-GraphApplicationPassword.ps1' -1

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
#EndRegion '.\Public\Remove-GraphApplicationPassword.ps1' 66
#Region '.\Public\Set-KeyVaultSecret.ps1' -1

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
#EndRegion '.\Public\Set-KeyVaultSecret.ps1' 50
#Region '.\Public\Test-AccessToken.ps1' -1

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
#EndRegion '.\Public\Test-AccessToken.ps1' 46
#Region '.\Public\Test-KeyVaultAccessToken.ps1' -1

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
#EndRegion '.\Public\Test-KeyVaultAccessToken.ps1' 45
