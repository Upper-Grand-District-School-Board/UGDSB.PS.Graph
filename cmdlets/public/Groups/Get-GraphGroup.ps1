<#
  .DESCRIPTION
  This cmdlet is designed to query graph for Entra ID groups
  .PARAMETER groupName
  If want to find based on group name
  .PARAMETER groupId
  If want to lookup by group id
  .PARAMETER All
  If want to return all groups
#>
function Get-GraphGroup{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'groupName')][ValidateNotNullOrEmpty()][string]$groupName,
    [Parameter(Mandatory = $true, ParameterSetName = 'groupId')][ValidateNotNullOrEmpty()][string]$groupId,
    [Parameter(Mandatory = $true, ParameterSetName = 'All')][switch]$All
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Create empty list
  $groupList =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Build the headers we will use to get groups
  $headers = Get-GraphHeader
  # Base URI for resource call
  $uri = "https://graph.microsoft.com/beta/groups"
  if($groupName){
    # Filter based on group name is required
    $uri = "$($uri)?`$filter=displayName eq '$($groupName)'"
  }
  elseif($groupId){
    # Filter based on group ID
    $uri = "$($uri)/$($groupId)"
  }
  try{
    # Loop until nextlink is null
    do{
      # Execute call against graph
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      # Add results to a list variable
      foreach($item in $results.value){
        $groupList.Add($item) | Out-Null
      }
      # Set the URI to the nextlink if it exists
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
    # If there is only one result, return that
    if($groupList.count -eq 0){
      return $results
    }
    else{
      # Return the group list if it exists
      return $groupList
    }
  }
  catch{
    throw "Unable to get groups. $($_.Exception.Message)"
  }
}