function Get-GraphIntuneEnrollmentStatusPage{
  [CmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # URI Endpoint
  $endpoint = "deviceManagement/deviceEnrollmentConfigurations"
  if($id){
    $endpoint = "$($endpoint)/$($id)"
  }
  if($displayName){
    $endpoint = "$($endpoint)?`$filter=displayName eq '$($displayName)'"
  }
  # Create empty list
  $esplist =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  try{
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    do{
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      if($results.value){
        foreach($item in $results.value){
          $esplist.add($item)
        }
      }
      else{
        $esplist.add($results)
      }
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
  }
  catch{
    throw "Unable to get devices. $($_.Exception.Message)"
  }
  return $esplist  
}