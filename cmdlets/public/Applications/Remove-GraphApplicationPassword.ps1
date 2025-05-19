function Remove-GraphApplicationPassword{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$objectId,
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$secretKeyId
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "applications/$($objectId)/removePassword"
  # Create body for request
  $body = @{
    keyId = $secretKeyId
  }
  # Call API Endpoint to create application
  try {
    $results = Get-GraphAPI -endpoint $endpoint -Method Post -headers $headers -body $body -beta -Verbose:$VerbosePreference
    if($results.StatusCode -ne 204){
      throw "Unable to remove password for appplication. $($results)"
    }
  }
  catch {
    throw $_
  } 
}