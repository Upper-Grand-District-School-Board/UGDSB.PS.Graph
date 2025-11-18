<#
  .DESCRIPTION
  This cmdlet is designed to get devices from Azure ID
#>
function Get-GraphDevice{
  [CmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$deviceId,
    [Parameter()][ValidateNotNullOrEmpty()][bool]$accountEnabled,
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$filter,
    [Parameter()][ValidateNotNullOrEmpty()][string]$fields
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  if($id -match ","){
    $id = ($id -split ",").Trim()
  }
  if($deviceId -match ","){
    $deviceId = ($deviceId -split ",").Trim()
  }  
  # Create empty list
  $filters =  [System.Collections.Generic.List[PSCustomObject]]@()  
  if($displayName){
    $filters.Add("displayName eq '$($displayName)'") | Out-Null
  }
  if($accountEnabled){
    $filters.Add("accountEnabled eq '$($accountEnabled)'") | Out-Null
  }
  if($deviceId.count -eq 1){  
    $filters.Add("deviceId eq '$($deviceId)'") | Out-Null
  }
  if ($PSBoundParameters.ContainsKey("filter")){
    $filters.Add($filter) | Out-Null
  }
  $batch = $false
  # General endpoint
  $endpoint = "devices"
  if($id.count -eq 1){
    $endpoint = "$($endpoint)/$($id)"
  }
  elseif($id.count -gt 1 -or $deviceId.count -gt 1){
    $batch = $true
  }
  # Create query string for the filter
  $filterList = $filters -join " and "
  # Create empty list
  $deviceList =  [System.Collections.Generic.List[PSCustomObject]]@() 
  # Get Graph Headers for Call
  $headers = Get-GraphHeader       
  # If ID and deviceID are not an array
  if(-not $batch){
    # Setup endpoint based on if filter or fields are passed
    if($filterList){
      $endpoint = "$($endpoint)?`$filter=$($filterList)"
    }
    if($filterList -and $fields){
      $endpoint = "$($endpoint)&`$select=$($fields)"
    }
    elseif($fields){
      $endpoint = "$($endpoint)?`$select=$($fields)"
    }    
    # Try to call graph API and get results back
    try{
      $uri = "https://graph.microsoft.com/beta/$($endpoint)"
      do{
        $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
        if($results.value){
          foreach($item in $results.value){
            $deviceList.Add($item) | Out-Null
          }
        }
        else{
          $deviceList.Add($results) | Out-Null
        }
        $uri = $results."@odata.nextLink"
      }while($null -ne $results."@odata.nextLink")      
    }
    catch{
      throw "Unable to get devices. $($_.Exception.Message)"
    } 
    return $deviceList   
  }
  # If a batch job because id or device id is an array
  else{
    $objid = 1
    $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
    $batches = [System.Collections.Generic.List[PSCustomObject]]@()
    # if trying to return multiple ids
    if($id.count -gt 1){
      foreach($device in $id){
        if($objid -lt 21){
          if($fields){
            $uri = "$($endpoint)/$($device)?`$select=$($fields)"
          }
          else{
            $uri = "$($endpoint)/$($device)"
          }
          $obj = [PSCustomObject]@{
            "id" = $objid
            "method" = "GET"
            "url" = $uri
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
    }
    # if trying to return multiple deviceids
    elseif($deviceId.Count -gt 1){
      foreach($device in $deviceId){
        if($objid -lt 21){
          if($fields){
            $uri = "$($endpoint)?`$filter=deviceId eq '$($device)'&`$select=$($fields)"
          }
          else{
            $uri = "$($endpoint)?`$filter=deviceId eq '$($device)'"
          }
          $obj = [PSCustomObject]@{
            "id" = $objid
            "method" = "GET"
            "url" = $uri
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
    }
    for($x = 0; $x -lt $batches.count; $x++){
      if($batches[$x].count -gt 0){
        $json = [PSCustomObject]@{
          "requests" = $batches[$x] 
        } | ConvertTo-JSON    
        $results = Invoke-RestMethod -Method "POST" -Uri "https://graph.microsoft.com/beta/`$batch" -Headers $headers -Body $json
        foreach($item in $results.responses.body){
          if($item.value){
            $deviceList.Add($item.value) | Out-Null
          }
          else{
            $deviceList.Add($item) | Out-Null
          }

        }
      }    
    }
    return $deviceList
  }
}
