function Remove-GraphOATHTokenAssignment{
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
    $endpoint = "users/$($userid)/authentication/hardwareOathMethods/$($id)"
  }
  elseif ($PSBoundParameters.ContainsKey("userPrincipalName")) {
    $endpoint = "users/$($userPrincipalName)/authentication/hardwareOathMethods/$($id)"
  }
  try {
    Get-GraphAPI -method delete -endpoint $endpoint -headers $headers -beta -Verbose:$VerbosePreference | Out-Null
  }
  catch {
    throw "Unable to delete token assignment. $($_.Exception.Message)"
  }  
}