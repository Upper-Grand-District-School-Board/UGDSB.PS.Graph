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