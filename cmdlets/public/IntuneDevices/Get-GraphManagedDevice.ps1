<#
  .DESCRIPTION
  This cmdlet is designed to get managed devices (intune) from the graph endpoints
#>
function Get-GraphManagedDevice{
  [CmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][datetime]$lastSyncBefore,
    [Parameter()][ValidateNotNullOrEmpty()][datetime]$lastSyncAfter,
    [Parameter()][ValidateNotNullOrEmpty()][ValidateSet("Windows","Android","macOS","iOS")][string]$operatingSystem,
    [Parameter()][ValidateNotNullOrEmpty()][ValidateSet("compliant","noncompliant","unknown")][string]$complianceState,
    [Parameter()][ValidateNotNullOrEmpty()][string]$OSVersion,
    [Parameter()][ValidateNotNullOrEmpty()][string]$OSVersionStartsWith,
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string]$azureADDeviceId,
    [Parameter()][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$model,
    [Parameter()][ValidateNotNullOrEmpty()][string]$manufacturer,
    [Parameter()][ValidateNotNullOrEmpty()][string]$serialNumber,
    [Parameter()][ValidateNotNullOrEmpty()][ValidateSet("disabled","enabled")][string]$lostModeState,
    [Parameter()][ValidateNotNullOrEmpty()][string]$minimumOSVersion,
    [Parameter()][ValidateNotNullOrEmpty()][string]$maximumOSVersion,
    [Parameter()][ValidateNotNullOrEmpty()][bool]$isEncrypted,
    [Parameter()][ValidateNotNullOrEmpty()][string]$fields,
    [Parameter()][switch]$batch
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }   
  # Create Filters for the URI
  # Create empty list
  $filters =  [System.Collections.Generic.List[PSCustomObject]]@()  
  # Build Filters
  if($lastSyncBefore){
    $filters.Add("lastSyncDateTime le $($lastSyncBefore.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))") | Out-Null
  }
  if($lastSyncAfter){
    $filters.Add("lastSyncDateTime ge $($lastSyncAfter.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))") | Out-Null
  }  
  if($operatingSystem){
    $filters.Add("operatingSystem eq '$($operatingSystem)'") | Out-Null
  }   
  if($complianceState){
    $filters.Add("complianceState eq '$($complianceState)'") | Out-Null
  }     
  if($OSVersion){
    $filters.Add("OSVersion eq '$($OSVersion)'") | Out-Null
  }    
  if($OSVersionStartsWith){
    $filters.Add("startsWith(OSVersion,'$($OSVersionStartsWith)')") | Out-Null
  }  
  if($azureADDeviceId){
    $filters.Add("azureADDeviceId eq '$($azureADDeviceId)'") | Out-Null
  }   
  if($userPrincipalName){
    $filters.Add("userPrincipalName eq '$($userPrincipalName)'") | Out-Null
  } 
  if($model){
    $filters.Add("model eq '$($model)'") | Out-Null
  }          
  if($manufacturer){
    $filters.Add("manufacturer eq '$($manufacturer)'") | Out-Null
  }    
  if($serialNumber){
    $filters.Add("serialNumber eq '$($serialNumber)'") | Out-Null
  }   
  # Create query string for the filter
  $filterList = $filters -join " and "
  # URI Endpoint
  $endpoint = "deviceManagement/managedDevices"
  if($id){
    $uri = "$($endpoint)/$($id)"
  } 
  else{
    $uri = "$($endpoint)"    
  }  
  if($filterList){
    $uri = "$($uri)?`$filter=$($filterList)"
  }
  if(!$batch){
    if($fields -ne ""){
      if($filters.count -gt 0){
        $uri = "$($uri)&`$select=$($fields)"
      }
      else{
        $uri = "$($uri)?`$select=$($fields)"
      }
    }
  }
  else{
    if($fields -ne ""){
      if($filters.count -gt 0){
        $uri = "$($uri)&`$select=id"
      }
      else{
        $uri = "$($uri)?`$select=id"
      }    
    }
  }
  # Create empty list
  $deviceList =  [System.Collections.Generic.List[PSCustomObject]]@()  
  # Create empty list
  $idlist =  [System.Collections.Generic.List[PSCustomObject]]@()    
  # Get Graph Headers for Call
  $headers = Get-GraphHeader  
  try{
    $uri = "https://graph.microsoft.com/beta/$($uri)"
    do{
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      if($results.value){
        foreach($item in $results.value){
          if(!$batch){$deviceList.Add($item) | Out-Null}
          else{$idlist.Add($item) | Out-Null}
        }
      }
      else{
        if(!$batch){$deviceList.Add($item) | Out-Null}
        else{$idlist.Add($item) | Out-Nul}
      }
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
  }
  catch{
    throw "Unable to get devices. $($_.Exception.Message)"
  }
  if(!$batch)
  {
    return $deviceList
  }
  $objid = 1
  $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
  $batches = [System.Collections.Generic.List[PSCustomObject]]@()
  foreach($device in $idlist){
    if($objid -lt 21){
      $url = "deviceManagement/managedDevices/$($device.id)"
      if($fields -ne ""){
        $url = "$($url)?`$select=$($fields)"
      }
      $obj = [PSCustomObject]@{
        "id" = $objid
        "method" = "GET"
        "url" = $url
      }
      $batchObj.Add($obj) | Out-Null
      $objid++
    }
    if($objId -eq 21){
      $batches.Add($batchObj) | Out-Null
      $batchObj = $null
      $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
      $objid = 1 
    }
  }  
  $batches.Add($batchObj) | Out-Null
  for($x = 0; $x -lt $batches.count; $x++){
    if($batches[$x].count -gt 0){
      $json = [PSCustomObject]@{
        "requests" = $batches[$x] 
      } | ConvertTo-JSON    
      $results = Invoke-RestMethod -Method "POST" -Uri "https://graph.microsoft.com/beta/`$batch" -Headers $headers -Body $json
      foreach($item in $results.responses.body){
        $deviceList.Add($item) | Out-Null
      }   
    } 
  }
  return $deviceList
}