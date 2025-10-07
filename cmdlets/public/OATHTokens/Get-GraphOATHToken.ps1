function Get-GraphOATHToken {
  [CmdletBinding(DefaultParameterSetName = "all")]
  param(
    [Parameter()][string]$id,
    [Parameter(ParameterSetName = "userid")][string]$userid,
    [Parameter(ParameterSetName = "upn")][string]$userPrincipalName,
    [Parameter()][string]$serialNumber,
    [Parameter()][string]$manufacturer,
    [Parameter()][string]$model,
    [Parameter()][ValidateSet("available", "assigned", "activated", "failedactivation")][string]$status
  )
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Get Graph Header
  $headers = Get-GraphHeader   
  $endpoint = "directory/authenticationMethodDevices/hardwareOathDevices"
  if ($PSBoundParameters.ContainsKey("userid")) {
    $endpoint = "users/$($userid)/authentication/hardwareOathMethods"
  }
  elseif ($PSBoundParameters.ContainsKey("userPrincipalName")) {
    $endpoint = "users/$($userPrincipalName)/authentication/hardwareOathMethods"
  }
  $filters = [System.Collections.Generic.List[PSCustomObject]]@()  
  if ($PSBoundParameters.ContainsKey("id")) { $filters.Add("id eq '$($id)'") | Out-Null }
  if ($PSBoundParameters.ContainsKey("serialNumber")) { $filters.Add("serialNumber eq '$($serialNumber)'") | Out-Null }
  if ($PSBoundParameters.ContainsKey("manufacturer")) { $filters.Add("manufacturer eq '$($manufacturer)'") | Out-Null }
  if ($PSBoundParameters.ContainsKey("model")) { $filters.Add("model eq '$($model)'") | Out-Null }
  if ($PSBoundParameters.ContainsKey("status")) { $filters.Add("status eq '$($status)'") | Out-Null }
  # Create query string for the filter
  $filterList = $filters -join " and "
  # Get Graph Headers for Call
  $headers = Get-GraphHeader       
  # Setup endpoint based on if filter or fields are passed
  if ($filterList) {
    $endpoint = "$($endpoint)?`$filter=$($filterList)"
  }  
  # Try to call graph API and get results back
  try {
    # Create empty list
    $devices =  [System.Collections.Generic.List[PSCustomObject]]@()  
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -headers $headers -beta -Verbose:$VerbosePreference
      # Add results to a list variable
      foreach ($item in $results.results.value) {
        $devices.Add($item) | Out-Null
      }
      Write-Verbose "Returned $($results.results.value.Count) results. Current result set is $($devices.Count) items." 
      if ($results.results."@odata.nextLink") {
        if ($PSBoundParameters.ContainsKey("userid") -or $PSBoundParameters.ContainsKey("userPrincipalName")){
          $uri = [REGEX]::Match($results.results."@odata.nextLink", "users.*").Value
        } 
        else{
          $uri = [REGEX]::Match($results.results."@odata.nextLink", "directory.*").Value
        }
      }
    }while ($null -ne $results.results."@odata.nextLink" -and $all.IsPresent)
  }
  catch {
    throw "Unable to get autopilot devices. $($_.Exception.Message)"
  } 
  if($devices.count -eq 0){
    return $results.Results
  }
  else{
    # Return the group list if it exists
    return $devices
  }    
}
