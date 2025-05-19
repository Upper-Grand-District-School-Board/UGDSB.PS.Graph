function New-GraphApplications{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$applicationName,
    [Parameter()][validatenotnullorempty()][string]$secretName,
    [Parameter()][datetime]$secretExpiry = (Get-Date).AddYears(1),
    [Parameter()][validatenotnullorempty()][Object[]]$appRoles
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "applications"
  # Create body for request
  $body = @{
    displayName = $applicationName
  }
  # If roles are in the request add them to the body
  if($PSBoundParameters.ContainsKey("appRoles")) {$body.Add("appRoles", $appRoles)}
  # If set to create a secret
  if($PSBoundParameters.ContainsKey("secretName")) {
    $body.Add("passwordCredentials", @(
      @{
        displayName = $secretName
        endDateTime = $secretExpiry.ToString("yyyy-MM-ddTHH:mm:ssZ")
      }
    ))
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