function Set-GraphDevice {
  [CmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$deviceId,
    [Parameter()][hashtable]$extensionProperties,
    [Parameter()][hashtable]$extensionAttributes
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # General endpoint
  $endpoint = "devices"  
  $batch = $false
  if ($id.count -eq 1) {
    $endpoint = "$($endpoint)/$($id)"
  }
  elseif ($id.count -gt 1 -or $deviceId.count -gt 1) {
    $batch = $true
  }
  # Get Graph Headers for Call
  $headers = Get-GraphHeader  
  # Create base body object
  $body = @{}
  # If extension properties are passed, add them to the request body
  if ($PSBoundParameters.ContainsKey("extensionProperties")) {
    foreach ($item in $extensionProperties.GetEnumerator()) {
      $body.Add($item.Key, $item.Value) | Out-Null
    }
  }
  # If extension extensionAttributes are passed, add them to the request body
  if ($PSBoundParameters.ContainsKey("extensionAttributes")) {
    $attributes = @{}
    foreach ($item in $extensionAttributes.GetEnumerator()) {
      $attributes.Add($item.Key, $item.Value) | Out-Null
    }
    $body.Add("extensionAttributes", $attributes) | Out-Null
  }
  # If ID and deviceID are not an array
  if (-not $batch) {
    try {
      $results = Get-GraphAPI -endpoint $endpoint -Method Patch -headers $headers -body $body -beta -Verbose:$VerbosePreference
      if ($results.StatusCode -ne 204) {
        throw "Unable to update device. $($results)"
      }    
    }
    catch {
      throw $_
    }
  }
  else {

    $objid = 1
    $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
    $batches = [System.Collections.Generic.List[PSCustomObject]]@()
    # if trying to return multiple ids
    if($id.count -gt 1){
      foreach($device in $id){
        if($objid -lt 21){
          $uri = "$($endpoint)/$($device)"
          $obj = [PSCustomObject]@{
            "id" = $objid
            "method" = "PATCH"
            "url" = $uri
            "body" = $body
            "headers" = @{"Content-Type" = "application/json"}
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
          $uri = "$($endpoint)/$($device)"
          $obj = [PSCustomObject]@{
            "id" = $objid
            "method" = "PATCH"
            "url" = $uri
            "body" = $body
            "headers" = @{"Content-Type" = "application/json"}
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
        } | ConvertTo-JSON -Depth 10
        $results = Invoke-RestMethod -Method "POST" -Uri "https://graph.microsoft.com/beta/`$batch" -Headers $headers -Body $json
      }    
    }
  }
}