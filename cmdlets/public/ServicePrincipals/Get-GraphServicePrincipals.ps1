function Get-GraphServicePrincipals{
  [CmdletBinding(DefaultParameterSetName = "All")]
  param(
    [Parameter(ParameterSetName = 'id')][validatenotnullorempty()][string]$id,
    [Parameter(ParameterSetName = 'appid')][validatenotnullorempty()][string]$appId,
    [Parameter(ParameterSetName = 'displayName')][validatenotnullorempty()][string]$displayName,
    [Parameter(ParameterSetName = 'filter')][ValidateNotNullOrEmpty()][string]$filter,
    [Parameter()][string[]]$servicePrincipalType,
    [Parameter()][switch]$all,
    [Parameter()][ValidateNotNullOrEmpty()][string]$fields
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "servicePrincipals"
  if($PSBoundParameters.ContainsKey("id")){
    $endpoint = "$($endpoint)/$($id)"
  }
  if($PSBoundParameters.ContainsKey("appId")){
    $endpoint = "$($endpoint)(appid=$($id))"
  }
  $uriparts = [System.Collections.Generic.List[PSCustomObject]]@()
  if ($PSBoundParameters.ContainsKey("displayName")) {$uriparts.add("`$filter=displayName -eq '$($displayName)'")}
  if ($PSBoundParameters.ContainsKey("filter")) {$uriparts.add("`$filter=$($filter)")}
  if ($PSBoundParameters.ContainsKey("fields")) {$uriparts.add("`$select=$($fields)")}
  # Generate the final API endppoint URI
  $endpoint = "$($endpoint)?$($uriparts -join "&")" 
  try {
    # Create empty list
    $servicePrincipals = [System.Collections.Generic.List[PSCustomObject]]@()    
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -headers $headers -beta -Verbose:$VerbosePreference
      # Add results to a list variable
      foreach ($item in $results.results.value) {
        if($PSBoundParameters.ContainsKey("servicePrincipalType") -and $item.servicePrincipalType -notin $servicePrincipalType){continue}
        $servicePrincipals.Add($item) | Out-Null
      }
      Write-Verbose "Returned $($results.results.value.Count) results. Current result set is $($servicePrincipals.Count) items." 
      if ($results.results."@odata.nextLink") {
        $uri = [REGEX]::Match($results.results."@odata.nextLink", "servicePrincipals.*").Value
      }
    }while ($null -ne $results.results."@odata.nextLink" -and $all.IsPresent)
  }
  catch {
    throw "Unable to get users. $($_.Exception.Message)"
  } 
  if($servicePrincipals.count -eq 0){
    return $results.Results
  }
  else{
    # Return the group list if it exists
    return $servicePrincipals
  }
}