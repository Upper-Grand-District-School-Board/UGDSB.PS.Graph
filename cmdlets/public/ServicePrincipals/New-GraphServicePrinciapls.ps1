function New-GraphServicePrinciapls{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$applicationId
  )  
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "servicePrincipals"
  # Create body for request
  $body = @{
    appId = $applicationId
  }
  # Call API Endpoint to create application
  try {
    $results = Get-GraphAPI -endpoint $endpoint -Method Post -headers $headers -body $body -beta -Verbose:$VerbosePreference
    if($results.StatusCode -ne 201){
      throw "Unable to create application. $($results)"
    }
  }
  catch {
    throw $_
  }
  return $results.Results  
}