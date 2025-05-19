function Remove-GraphApplications{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$objectId
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "applications/$($objectId)"
  # Call API Endpoint to create application
  try {
    $results = Get-GraphAPI -endpoint $endpoint -Method Delete -headers $headers -beta -Verbose:$VerbosePreference
    if($results.StatusCode -ne 204){
      throw "Unable to remove appplication. $($results)"
    }
  }
  catch {
    throw $_
  }   
}