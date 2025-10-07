function Get-GraphSerivcePrincipalsSyncJobs{
  [CmdletBinding()]
  param(
    [Parameter(ParameterSetName = 'id')][validatenotnullorempty()][string]$id
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "servicePrincipals/$($id)/synchronization/jobs"  
  try {
    $results = Get-GraphAPI -endpoint $endpoint -headers $headers -beta -Verbose:$VerbosePreference
  }
  catch {
    throw "Unable to add token. $($_.Exception.Message)"
  }
  return $results.value
}