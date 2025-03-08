
function Get-GraphUserGroups {
  [CmdletBinding()]
  [OutputType([System.Collections.Generic.List[PSObject]])]
  param(
    [Alias("userPrincipalName")][Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$userid,
    [Parameter(Mandatory = $true, ParameterSetName = 'directMembership')][switch]$directMembership,
    [Parameter(Mandatory = $true, ParameterSetName = 'transitiveMemberOf')][switch]$transitiveMemberOf
  )
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Build the endpoint
  $endpoint = "users/$($userid)"
  if ($PSBoundParameters.ContainsKey("directMembership")) {
    $endpoint = "$($endpoint)/memberOf"
  } 
  elseif ($PSBoundParameters.ContainsKey("transitiveMemberOf")) {  
    $endpoint = "$($endpoint)/transitiveMemberOf"
  }
  # Build the headers we will use to get groups
  $headers = Get-GraphHeader  
  # Create empty list
  $groupList = [System.Collections.Generic.List[PSCustomObject]]@()
  try {
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -headers $headers -beta -Verbose:$VerbosePreference
      # Add results to a list variable
      foreach ($item in $results.results.value) {
        $groupList.Add($item) | Out-Null
      }
      Write-Verbose "Returned $($results.results.value.Count) results. Current result set is $($groupList.Count) items." 
      if ($results.results."@odata.nextLink") {
        $uri = [REGEX]::Match($results.results."@odata.nextLink", "users.*").Value
      }
    }while ($null -ne $results.results."@odata.nextLink")     
  }
  catch {
    throw $_
  }    
  return $groupList
}