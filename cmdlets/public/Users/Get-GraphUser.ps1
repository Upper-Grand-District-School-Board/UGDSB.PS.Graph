function Get-GraphUser {
  [CmdletBinding(DefaultParameterSetName = "All")]
  [OutputType([System.Collections.Generic.List[PSCustomObject]])]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = 'userPrincipalName')][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Parameter(Mandatory = $true, ParameterSetName = 'userid')][ValidateNotNullOrEmpty()][string]$userid,
    [Parameter()][switch]$All,
    [Parameter()][switch]$ConsistencyLevel,
    [Parameter()][switch]$Count,
    [Parameter()][ValidateNotNullOrEmpty()][string]$filter,
    [Parameter()][ValidateNotNullOrEmpty()][string]$select
  )  
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Build the headers we will use to get groups
  $ConsistencyLevelHeader = @{}
  if ($PSBoundParameters.ContainsKey("ConsistencyLevel")) {
    $ConsistencyLevelHeader.Add("ConsistencyLevel", $true) | Out-Null
  }
  $headers = Get-GraphHeader @ConsistencyLevelHeader
  # Create empty list
  $userList = [System.Collections.Generic.List[PSCustomObject]]@()
  # Base URI for resource call
  $endpoint = "users"
  $uriparts = [System.Collections.Generic.List[PSCustomObject]]@()
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) {
    # Filter based on group name is required
    $endpoint = "$($endpoint)/$($userPrincipalName)"    
  }
  elseif ($PSBoundParameters.ContainsKey("userid")) {
    $endpoint = "$($endpoint)/$($userid)"
  }
  if ($PSBoundParameters.ContainsKey("filter")) { $uriparts.add("`$filter=$($filter)") }
  if ($PSBoundParameters.ContainsKey("select")) { $uriparts.add("`$select=$($select)") }
  if ($PSBoundParameters.ContainsKey("count")) { $uriparts.add("`$count=true") }
  # Generate the final API endppoint URI
  $endpoint = "$($endpoint)?$($uriparts -join "&")"
  try {
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -headers $headers -beta -Verbose:$VerbosePreference
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