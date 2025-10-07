function Set-GraphOATHTokenAssignment{
  [CmdletBinding(DefaultParameterSetName = "all")]
  param(  
    [Parameter(Mandatory=$True)][string]$id,
    [Parameter(Mandatory=$True, ParameterSetName = "userid")][string]$userid,
    [Parameter(Mandatory=$True, ParameterSetName = "upn")][string]$userPrincipalName
  )
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Get Graph Header
  $headers = Get-GraphHeader   
  if ($PSBoundParameters.ContainsKey("userid")) {
    $endpoint = "users/$($userid)/authentication/hardwareOathMethods"
  }
  elseif ($PSBoundParameters.ContainsKey("userPrincipalName")) {
    $endpoint = "users/$($userPrincipalName)/authentication/hardwareOathMethods"
  }
  $body = @{
    device = @{
      "id" = $id
    }
  }
  try {
    Get-GraphAPI -method post -endpoint $endpoint -headers $headers -body $body -beta -Verbose:$VerbosePreference | Out-Null
  }
  catch {
    throw "Unable to add token. $($_.Exception.Message)"
  }
}