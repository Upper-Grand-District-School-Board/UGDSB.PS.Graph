function Get-GraphAccessPackages {
  [cmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$id
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # URI Endpoint
  $endpoint = "identityGovernance/entitlementManagement/accessPackages"
  if ($id) {
    $endpoint = "$($endpoint)?`$filter=id eq '$($id)'"
  }
  elseif ($displayName) {
    $endpoint = "$($endpoint)?`$filter=displayName eq '$($displayName)'"
  }
  # Create empty list
  $List = [System.Collections.Generic.List[PSCustomObject]]@()
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  try {
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    do {
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      if ($results.value) {
        foreach ($item in $results.value) {
          $List.add($item)
        }
      }
      $uri = $results."@odata.nextLink"
    }while ($null -ne $results."@odata.nextLink")
  }
  catch {
    throw "Unable to get Access Packages. $($_.Exception.Message)"
  }  
  return $List    
}