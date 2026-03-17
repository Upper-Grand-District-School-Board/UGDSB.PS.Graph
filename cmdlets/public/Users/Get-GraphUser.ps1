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