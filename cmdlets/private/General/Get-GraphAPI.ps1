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