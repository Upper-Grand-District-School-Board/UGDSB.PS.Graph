function Get-GraphIntuneFilters{
  [CmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$platform
  )
  # Construct array list to build the dynamic filter list
  $FilterList = [System.Collections.Generic.List[PSCustomObject]]@()
  if($id){
    $FilterList.Add("`$PSItem.id -eq '$($id)'") | Out-Null
  }
  if($displayName){
    $FilterList.Add("`$PSItem.displayName -eq '$($displayName)'") | Out-Null
  }
  if($platform){
    $FilterList.Add("`$PSItem.platform -eq '$($platform)'") | Out-Null
  }
  # Construct script block from filter list array
  $FilterExpression = [scriptblock]::Create(($FilterList -join " -and ")) 
  # Create empty list
  $filters =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Build the headers we will use to get groups
  $headers = Get-GraphHeader  
  # Endpoint for the API
  $uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters"
  try{
    # Loop until nextlink is null
    do{
      # Execute call against graph
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      # Add results to a list variable
      foreach($item in $results.value){
        $filters.Add($item)
      }
      # Set the URI to the nextlink if it exists
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
    if($FilterList.Count -gt 0){
      return $filters | Where-Object -FilterScript $FilterExpression
    }
    return $filters
  }
  catch{
    throw "Unable to get group members. $($_.Exception.Message)"
  }  
}