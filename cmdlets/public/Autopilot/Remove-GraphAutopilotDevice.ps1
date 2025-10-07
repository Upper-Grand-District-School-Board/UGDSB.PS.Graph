function Remove-GraphAutopilotDevice{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$id
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # Get Graph Headers for Call
  $headers = Get-GraphHeader  
  # URI Endpoint
  $endpoint = "deviceManagement/windowsAutopilotDeviceIdentities/$($id)"
  try{
    $uri = $endpoint
    Get-GraphAPI -endpoint $uri -Method Delete -headers $headers -beta -Verbose:$VerbosePreference | Out-Null
  }
  catch{
    throw "Unable to delete devices. $($_.Exception.Message)"
  } 
}
