function Get-GraphAutopilotInformation {
  [CmdletBinding()]
  param(
    [parameter()][ValidateNotNullOrEmpty()][string]$SerialNumber,
    [parameter()][ValidateNotNullOrEmpty()][string]$groupTag,
    [parameter()][ValidateNotNullOrEmpty()][string]$manufacturer,
    [parameter()][ValidateNotNullOrEmpty()][string]$model,
    [parameter()][ValidateNotNullOrEmpty()][string]$azureAdDeviceId
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  $endpoint = "deviceManagement/windowsAutopilotDeviceIdentities"
  # Create empty list
  $filters = [System.Collections.Generic.List[PSCustomObject]]@()
  if($groupTag){
    $filters.Add("contains(groupTag,'$($groupTag)')") | Out-Null
  }
  if($SerialNumber){
    $filters.Add("contains(SerialNumber,'$($SerialNumber)')") | Out-Null
  }  
  if($manufacturer){
    $filters.Add("contains(manufacturer,'$($manufacturer)')") | Out-Null
  }   
  if($model){
    $filters.Add("contains(model,'$($model)')") | Out-Null
  }   
  if($userPrincipalName){
    $filters.Add("contains(userPrincipalName,'$($userPrincipalName)')") | Out-Null
  }  
  if($azureAdDeviceId){
    $filters.Add("contains(azureAdDeviceId,'$($azureAdDeviceId)')") | Out-Null
  }  
  # Create query string for the filter
  $filterList = $filters -join " and "  
  if($filterList){
    $endpoint = "$($endpoint)?`$filter=$($filterList)"
  }  
  # Create empty list
  $deviceList = [System.Collections.Generic.List[PSCustomObject]]@() 
  # Get Graph Headers for Call
  $headers = Get-GraphHeader 
  # Get Autopilot Devices
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  do {
    # Execute call against graph
    $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode 
    foreach($item in $results.value){
      $deviceList.Add($item) | Out-Null
    }
    # Set the URI to the nextlink if it exists
    $uri = $results."@odata.nextLink"     
  }while ($null -ne $results."@odata.nextLink")
  return $deviceList
}