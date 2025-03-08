function Get-GraphAccessPackageCatalog{
  [cmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName
  )
  $endpoint = "identityGovernance/entitlementManagement/accessPackageCatalogs"
  if($id){
    $endpoint = "$($endpoint)?`$filter=id eq '$id'"
  }
  elseif($displayName){
    $endpoint = "$($endpoint)?`$filter=displayName eq '$displayName'"
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