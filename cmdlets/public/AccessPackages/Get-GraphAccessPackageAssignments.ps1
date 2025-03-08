function Get-GraphAccessPackageAssignments{
  [cmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$accessPackageId,
    [Parameter()][ValidateNotNullOrEmpty()][string]$groupid,
    [Parameter()][ValidateNotNullOrEmpty()][string]$groupname
  )  
  $endpoint = "identityGovernance/entitlementManagement/accessPackageAssignmentPolicies"
  if($id){
    $endpoint = "$($endpoint)?`$filter=id eq '$id'"
  }
  elseif($displayName){
    $endpoint = "$($endpoint)?`$filter=displayName eq '$displayName'"
  }
  elseif($accessPackageId){
    $endpoint = "$($endpoint)?`$filter=accessPackageId eq '$accessPackageId'"
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
          if($groupid -or $groupName){
            $skipItem = $true
            if($item.requestorSettings.allowedRequestors.id -contains $groupID){
              $skipItem = $false
            }
            if($item.requestorSettings.allowedRequestors.description -contains $groupname){
              $skipItem = $false
            }
            if($item.requestApprovalSettings.approvalStages.primaryApprovers.id -contains $groupID){
              $skipItem = $false
            }
            if($item.requestApprovalSettings.approvalStages.primaryApprovers.description -contains $groupname){
              $skipItem = $false
            }                        
          }
          if($skipItem){continue}
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