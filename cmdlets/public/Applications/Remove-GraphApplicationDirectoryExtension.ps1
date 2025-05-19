function Remove-GraphApplicationDirectoryExtension{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$objectId,
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$extensionPropertyId
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "applications/$($objectId)/extensionProperties/$($extensionPropertyId)"
  try{
    $results = Get-GraphAPI -endpoint $endpoint -Method Delete -headers $headers -beta -Verbose:$VerbosePreference
    if($results.StatusCode -ne 204){
      throw "Unable to delete extension attribute for appplication. $($results)"
    }    
  }
  catch {
    throw $_
  }   
}