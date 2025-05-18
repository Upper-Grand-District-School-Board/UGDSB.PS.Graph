# https://learn.microsoft.com/en-us/graph/api/application-update?view=graph-rest-beta&tabs=http
function Set-GraphApplications{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$objectId,
    [Parameter()][validatenotnullorempty()][string]$applicationName,
    [Parameter()][validatenotnullorempty()][Object[]]$appRoles
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "applications/$($objectId)"
  # Create body for request
  $body = @{}
  if($PSBoundParameters.ContainsKey("applicationName")) {$body.Add("displayName", $applicationName)}
  if($PSBoundParameters.ContainsKey("appRoles")) {$body.Add("appRoles", $appRoles)}
  # Call API Endpoint to create application
  try {
    $results = Get-GraphAPI -endpoint $endpoint -Method Patch -headers $headers -body $body -beta -Verbose:$VerbosePreference
    if($results.StatusCode -ne 204 ){
      throw "Unable to update application. $($results)"
    }
  }
  catch {
    throw $_
  }
}