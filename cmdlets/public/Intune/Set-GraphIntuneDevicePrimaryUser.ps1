function Set-GraphIntuneDevicePrimaryUser{
  param(
    [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$deviceId,
    [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$userId
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  $endpoint = "deviceManagement/managedDevices/$($deviceId)/users/`$ref"
  $headers = Get-GraphHeader
  $Body = @{
    "@odata.id" = "https://graph.microsoft.com/beta/users/$($userId)"
  }
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  Invoke-RestMethod -method "POST" -Uri $uri -Headers $headers -body ($body | ConvertTo-JSON) -StatusCodeVariable "statusCode"
}