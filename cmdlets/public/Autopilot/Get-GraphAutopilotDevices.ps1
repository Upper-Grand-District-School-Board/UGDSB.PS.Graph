function Get-GraphAutopilotDevices{
  [CmdletBinding()]
  [OutputType([System.Collections.Generic.List[PSCustomObject]])]  
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$id,
    [Parameter()][switch]$all, 
    [Parameter(ParameterSetName = 'filter')][ValidateNotNullOrEmpty()][string]$filter,    
    [Parameter()][ValidateNotNullOrEmpty()][string]$fields
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Build the headers we will use to get groups
  $headers = Get-GraphHeader
  # Base URI for resource call
  $endpoint = "deviceManagement/windowsAutopilotDeviceIdentities"
  if($PSBoundParameters.ContainsKey("id")){
    $endpoint = "$($endpoint)/$($id)"
  }
  $uriparts = [System.Collections.Generic.List[PSCustomObject]]@()  
  if ($PSBoundParameters.ContainsKey("filter")) {$uriparts.add("`$filter=$($filter)")}  
  if ($PSBoundParameters.ContainsKey("fields")) {$uriparts.add("`$select=$($fields)")}
  # Generate the final API endppoint URI
  $endpoint = "$($endpoint)?$($uriparts -join "&")"  
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
        $uri = [REGEX]::Match($results.results."@odata.nextLink", "deviceManagement.*").Value
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