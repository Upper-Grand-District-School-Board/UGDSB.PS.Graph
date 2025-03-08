<#
  .DESCRIPTION
  This cmdlet is designed to query the sign in logs for the users in the entra id tenant
  .PARAMETER userDisplayName
  The list of user display names that we should be looking for
  .PARAMETER userPrincipalName
  The list of user principal names that we should be looking for
  .PARAMETER userId
  The lsit of user ids that we should be looking for
  .PARAMETER appDisplayName
  The name of the application that we attempted to sign into
  .PARAMETER ipAddress
  The list of ipaddresses that we should be looking for
  .PARAMETER afterDateTime
  Sign ins after this date
#>
function Get-GraphSignInAuditLogs{
  [CmdletBinding()]
  param(
    [Parameter()][string[]]$userDisplayName,
    [Parameter()][string[]]$userPrincipalName,
    [Parameter()][string[]]$userId,
    [Parameter()][string[]]$appDisplayName,
    [Parameter()][string[]]$ipAddress,
    [Parameter()][datetime]$afterDateTime
  )
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # URI Endpoint
  $endpoint = "auditLogs/signIns"
  $uriparts = [System.Collections.Generic.List[PSCustomObject]]@()
  if ($PSBoundParameters.ContainsKey("userDisplayName")) {
    $list =  [System.Collections.Generic.List[String]]@()
    foreach($item in $userDisplayName){
      $list.Add("userDisplayName eq '$($item)'") | Out-Null
    }
    $uriparts.Add("($($list -join " or "))") | Out-Null    
  }
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) {
    $list =  [System.Collections.Generic.List[String]]@()
    foreach($item in $userPrincipalName){
      $list.Add("userPrincipalName eq '$($item)'") | Out-Null
    }
    $uriparts.Add("($($list -join " or "))") | Out-Null
  }  
  if ($PSBoundParameters.ContainsKey("userId")) {
    $list =  [System.Collections.Generic.List[String]]@()
    foreach($item in $userId){
      $list.Add("userId eq '$($item)'") | Out-Null
    }
    $uriparts.Add("($($list -join " or "))") | Out-Null
  }  
  if ($PSBoundParameters.ContainsKey("ipAddress")) {
    $list =  [System.Collections.Generic.List[String]]@()
    foreach($item in $ipAddress){
      $list.Add("ipAddress eq '$($item)'") | Out-Null
    }
    $uriparts.Add("($($list -join " or "))") | Out-Null
  }   
  if ($PSBoundParameters.ContainsKey("afterDateTime")) {
    $uriparts.Add("createdDateTime ge $($afterDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))") | Out-Null
  }  
  # Generate the final API endppoint URI
  $endpoint = "$($endpoint)?`$filter=$($uriparts -join " and ")"
  # Get Graph Headers for Call
  $headers = Get-GraphHeader 
  try {
    $signinList =  [System.Collections.Generic.List[PSCustomObject]]@()
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -headers $headers -beta -Verbose:$VerbosePreference
      # Add results to a list variable
      foreach ($item in $results.results.value) {
        $signinList.Add($item) | Out-Null
      }
      Write-Verbose "Returned $($results.results.value.Count) results. Current result set is $($signinList.Count) items." 
      if ($results.results."@odata.nextLink") {
        $uri = [REGEX]::Match($results.results."@odata.nextLink", "auditLogs/signIns.*").Value
      }
    }while ($null -ne $results.results."@odata.nextLink")     
  }
  catch {
    throw $_
  } 
  return $signinList
}