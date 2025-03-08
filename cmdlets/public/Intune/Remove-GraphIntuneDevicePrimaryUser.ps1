function Remove-GraphIntuneDevicePrimaryUser{
  [CmdletBinding()]
  param(
    [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$deviceId
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }   
  $endpoint = "deviceManagement/managedDevices/$($deviceId)/users/`$ref"
  $headers = Get-GraphHeader
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  Invoke-RestMethod -method "DELETE" -Uri $uri -Headers $headers -StatusCodeVariable "statusCode"  
}