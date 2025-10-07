function Enter-GraphOATHTokenActivation{
  [CmdletBinding(DefaultParameterSetName = "all")]
  param(  
    [Parameter(Mandatory=$True)][string]$id,
    [Parameter(Mandatory=$True)][int]$code,
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
    $endpoint = "users/$($userid)/authentication/hardwareOathMethods/$($id)/activate"
  }
  elseif ($PSBoundParameters.ContainsKey("userPrincipalName")) {
    $endpoint = "users/$($userPrincipalName)/authentication/hardwareOathMethods/$($id)/activate"
  }
  $body = @{
    verificationCode = $code
  }
  try {
    Get-GraphAPI -method post -endpoint $endpoint -headers $headers -body $body -beta -Verbose:$VerbosePreference
  }
  catch {
    throw "Unable to add token. $($_.Exception.Message)"
  }  
}