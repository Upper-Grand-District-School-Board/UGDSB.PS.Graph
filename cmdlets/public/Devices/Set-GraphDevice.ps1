function Set-GraphDevice {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $True, ParameterSetName = "id")][ValidateNotNullOrEmpty()][string[]]$id,
    [Parameter(Mandatory = $True, ParameterSetName = "deviceid")][ValidateNotNullOrEmpty()][string[]]$deviceId,
    [Parameter()][hashtable]$Properties,
    [Parameter()][hashtable]$extensionAttributes
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  if($id -match ","){
    $id = ($id -split ",").Trim()
  }
  if($deviceId -match ","){
    $deviceId = ($deviceId -split ",").Trim()
  }    
  # Should this be a batch job
  $batch = $false
  # Default endpoint
  $endpoint = "devices"
  # If only a single Object ID is passed
  if ($PSBoundParameters.ContainsKey("id") -and $id.count -eq 1) {
    $endpoint = "$($endpoint)/$($id)"
  }
  # If only a single device ID is passed
  elseif ($PSBoundParameters.ContainsKey("deviceId") -and $deviceId.count -eq 1) {
    $endpoint = "$($endpoint)(deviceId='{$($deviceId)}')"
  }
  # Otherwise it is going to be a batch job
  else {
    $batch = $true
  }
  # Get Graph Headers for Call
  $headers = Get-GraphHeader  
  # Create base body object
  $body = @{}
  # If properties are passed, add them to the request body
  if ($PSBoundParameters.ContainsKey("Properties")) {
    foreach ($item in $Properties.GetEnumerator()) {
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
    if ($id.count -gt 1) {
      $list = $id
    }
    else {
      $list = $deviceId
    }
    foreach ($device in $list) {
      if ($objid -lt 21) {
        if ($id) {
          $uri = "$($endpoint)/$($device)"
        }
        else {
          $uri = "$($endpoint)(deviceId='{$($device)}')"
        }
        $obj = [PSCustomObject]@{
          "id"      = $objid
          "method"  = "PATCH"
          "url"     = $uri
          "body"    = $body
          "headers" = @{"Content-Type" = "application/json" }
        }
        $batchObj.Add($obj) | Out-Null
        $objid++ 
      }
      if ($objId -eq 21) {
        $batches.Add($batchObj) | Out-Null
        $batchObj = $null
        $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
        $objid = 1 
      }        
    }
    $batches.Add($batchObj) | Out-Null
  }
  for ($x = 0; $x -lt $batches.count; $x++) {
    if ($batches[$x].count -gt 0) {
      $json = [PSCustomObject]@{
        "requests" = $batches[$x] 
      } | ConvertTo-JSON -Depth 10
      $results = Invoke-RestMethod -Method "POST" -Uri "https://graph.microsoft.com/beta/`$batch" -Headers $headers -Body $json
    }    
  }   
}