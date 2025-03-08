function Test-GraphIntuneLicense{
  [CmdletBinding()]
  param(
    [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$userId
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }   
  $endpoint = "deviceAppManagement/managedAppStatuses('userstatus')?userId=$($userId)"
  $headers = Get-GraphHeader
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  $result = Invoke-RestMethod -Method "GET" -URI $uri -Headers $headers -StatusCodeVariable "statusCode"
  $license = $result.content.validationStatuses | Where-Object { $_.validationName -eq 'Intune License' }
  if($license.State -eq 'Pass'){
    return $true
  }
  else{
    return $false
  }
}