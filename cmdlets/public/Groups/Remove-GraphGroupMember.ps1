function Remove-GraphGroupMember{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$groupId,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$ids
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # Get Graph Headers for Call
  $headers = Get-GraphHeader 
  try{
    $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
    $batches = [System.Collections.Generic.List[PSCustomObject]]@()
    for($i = 1; $i -le $ids.Count; ++$i){
      $obj = [PSCustomObject]@{
        "id" = $i
        "method" = "DELETE"
        "url" = "/groups/$($groupId)/members/$($ids[$i-1])/`$ref"
      }      
      $batchObj.Add($obj) | Out-Null        
      if($($i % 20) -eq 0){
        $batches.Add($batchObj) | Out-Null
        $batchObj = $null
        $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
      }      
    }
    $batches.Add($batchObj) | Out-Null
    foreach($batch in $batches){
      $json = [PSCustomObject]@{
        "requests" = $batch
      } | ConvertTo-JSON -Depth 5
      $results = Invoke-RestMethod -Method "POST" -Uri "https://graph.microsoft.com/beta/`$batch" -Headers $headers -Body $json
    }
  }
  catch{
    throw "Unable to remove members. $($_.Exception.Message)"
  }      
}