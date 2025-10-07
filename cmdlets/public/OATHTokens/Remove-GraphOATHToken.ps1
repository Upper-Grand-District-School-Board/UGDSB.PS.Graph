function Remove-GraphOATHToken{
  [CmdletBinding()]
  param(  
    [Parameter(Mandatory=$True)][string]$id,
    [Parameter()][switch]$force
  )  
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet "
  }
  $token = Get-GraphOATHToken -id $id
  if($token.assignedTo){
    if($force.IsPresent){
      foreach($user in $token.assignedTo){
        Remove-GraphOATHTokenAssignment -id $id -userid $user.id -Verbose:$VerbosePreference
      }
    }
    else{
      throw "Token is assigned to user. Please remove assignment before deleting token or use -force to have it be removed automatically."
    }
  }
  $headers = Get-GraphHeader   
  $endpoint = "directory/authenticationMethodDevices/hardwareOathDevices/$($id)"
  try {
    Get-GraphAPI -method delete -endpoint $endpoint -headers $headers -beta -Verbose:$VerbosePreference
  }
  catch {
    throw "Unable to remove token. $($_.Exception.Message)"
  }    
}