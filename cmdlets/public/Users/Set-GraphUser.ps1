function Set-GraphUser{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'userPrincipalName')][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Alias("id")][Parameter(Mandatory = $true, ParameterSetName = 'userid')][ValidateNotNullOrEmpty()][string]$userid,
    [Parameter()][hashtable]$extensionProperties
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  $headers = Get-GraphHeader  
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) { 
    $endpoint = "users/$($userPrincipalName)"
  }
  elseif ($PSBoundParameters.ContainsKey("userid")) { 
    $endpoint = "users/$($userid)"
  }
  # Create base body object
  $body = @{}
  # If extension properties are passed, add them to the request body
  if ($PSBoundParameters.ContainsKey("extensionProperties")){
    foreach($item in $extensionProperties.GetEnumerator()){
      $body.Add($item.Key,$item.Value) | Out-Null
    }
  }
  try{
    $results = Get-GraphAPI -endpoint $endpoint -Method Patch -headers $headers -body $body -beta -Verbose:$VerbosePreference
    if($results.StatusCode -ne 204){
      throw "Unable to update user. $($results)"
    }    
  }
  catch {
    throw $_
  } 
}