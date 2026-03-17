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