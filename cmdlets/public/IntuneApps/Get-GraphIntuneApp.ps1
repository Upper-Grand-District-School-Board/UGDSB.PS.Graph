function Get-GraphIntuneApp{
  [CmdletBinding(DefaultParameterSetName = 'All')]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'id')][ValidateNotNullOrEmpty()][string]$id,
    [Parameter(Mandatory = $true, ParameterSetName = 'displayName')][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter()][ValidateNotNullOrEmpty()][ValidateSet("microsoft.graph.androidManagedStoreApp","microsoft.graph.iosStoreApp","microsoft.graph.iosVppApp","microsoft.graph.macOSLobApp","microsoft.graph.macOSMicrosoftEdgeApp","microsoft.graph.macOSOfficeSuiteApp","microsoft.graph.macOSPkgApp","microsoft.graph.macOsVppApp","microsoft.graph.managedAndroidStoreApp","microsoft.graph.managedIOSStoreApp","microsoft.graph.officeSuiteApp","microsoft.graph.webApp","microsoft.graph.win32LobApp","microsoft.graph.winGetApp")]
      [string]$type,
    [Parameter()][ValidateNotNullOrEmpty()][string]$fields
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  
  
  # URI Endpoint
  $endpoint = "deviceAppManagement/mobileApps"
  # Build filters for URI
  $filters =  [System.Collections.Generic.List[PSCustomObject]]@()
  if($id){
    $filters.Add("id eq '$($id)'") | Out-Null
  }
  if($displayName){
    $filters.Add("displayName eq '$($displayName)'") | Out-Null
  }  
  if($type){
    $filters.Add("(isof('$($type)'))") | Out-Null
  }   
  # Create query string for the filter
  $filterList = $filters -join " and "
  if($filterList){
    $endpoint = "$($endpoint)?`$filter=$($filterList)"
  }
  if($filterList -and $fields){
    $endpoint = "$($endpoint)&`$select=$($fields)"
  }
  elseif($fields){
    $endpoint = "$($endpoint)?`$select=$($fields)"
  }
  # Create empty list
  $applicationList =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  try{
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    do{
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      if($results.value){
        foreach($item in $results.value){
          $applicationList.add($item)
        }
      }
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
  }
  catch{
    throw "Unable to get devices. $($_.Exception.Message)"
  }  
  return $applicationList
}