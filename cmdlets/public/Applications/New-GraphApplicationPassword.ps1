function New-GraphApplicationPassword{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$objectId,
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$secretName,
    [Parameter()][datetime]$secretExpiry = (Get-Date).AddYears(1)
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "applications/$($objectId)/addPassword"
  # Create body for request
  $body = @{
    passwordCredential = @{
      displayName = $secretName
      endDateTime = $secretExpiry.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
  }
  # Call API Endpoint to create application
  try {
    $results = Get-GraphAPI -endpoint $endpoint -Method Post -headers $headers -body $body -beta -Verbose:$VerbosePreference
    if($results.StatusCode -ne 200){
      throw "Unable to create password for appplication. $($results)"
    }
  }
  catch {
    throw $_
  }
  return $results.Results   
}