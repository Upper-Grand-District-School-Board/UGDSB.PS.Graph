function Get-GraphUserLicenseDetails{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'userPrincipalName')][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Alias("id")][Parameter(Mandatory = $true, ParameterSetName = 'userid')][ValidateNotNullOrEmpty()][string]$userid    
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  $headers = Get-GraphHeader  
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) { 
    $endpoint = "users/$($userPrincipalName)/licenseDetails"
  }
  elseif ($PSBoundParameters.ContainsKey("userid")) { 
    $endpoint = "users/$($userid)/licenseDetails"
  }
  try{
    $results = Get-GraphAPI -endpoint $endpoint -Method Get -headers $headers -beta -Verbose:$VerbosePreference
    if($results.StatusCode -ne 200){
      throw "Unable to retrieve user license details. $($results)"
    }    
  }
  catch {
    throw $_
  } 
  return $results.Results.value
}