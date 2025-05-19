function Get-GraphApplicationDirectoryExtension{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$objectId,
    [Parameter()][validatenotnullorempty()][string]$extensionPropertyId
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "applications/$($objectId)/extensionProperties"
  if($PSBoundParameters.ContainsKey("extensionPropertyId")) {$endpoint = "$($endpoint)/$($extensionPropertyId)"} 
  try{
    $results = Get-GraphAPI -endpoint $endpoint -headers $headers -beta -Verbose:$VerbosePreference
  }
  catch {
    throw $_
  } 
  if($PSBoundParameters.ContainsKey("extensionPropertyId")){
    return $results.results
  }
  else{
    return $results.results.value
  }
  
}