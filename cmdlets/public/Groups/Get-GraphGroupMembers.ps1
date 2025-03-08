#https://learn.microsoft.com/en-us/graph/api/group-list-members?view=graph-rest-beta&tabs=http
function Get-GraphGroupMembers{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'groupName')][ValidateNotNullOrEmpty()][string]$groupName,
    [Parameter(Mandatory = $true, ParameterSetName = 'groupId')][ValidateNotNullOrEmpty()][string]$groupId,
    [Parameter()][switch]$Recurse
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get the Group ID if Group Name was Sent
  if($groupName){
    $group = Get-GraphGroup -groupName $groupName
    $groupId = $group.id
  }
  # Create empty list
  $groupMemberList =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Create List for recurse if needed
  $groupList =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Build the headers we will use to get groups
  $headers = Get-GraphHeader
  # Deterime if we just want members of transitive members
  if($Recurse){
    $uri = "https://graph.microsoft.com/beta/groups/$($groupId)/transitiveMembers"
  }
  else{
    $uri = "https://graph.microsoft.com/beta/groups/$($groupId)/members"
  }
  try{
    # Loop until nextlink is null
    do{
      # Execute call against graph
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      # Add results to a list variable
      foreach($item in $results.value){
        $groupMemberList.Add($item)
      }
      # Set the URI to the nextlink if it exists
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
    return $groupMemberList
  }
  catch{
    throw "Unable to get group members. $($_.Exception.Message)"
  }
}