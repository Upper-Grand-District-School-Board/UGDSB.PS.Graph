function Set-GraphAutopilotInformation {
  param (
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$deviceId,
    [Parameter()][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$groupTag,
    [Parameter()][ValidateNotNullOrEmpty()][string]$deviceName
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }   
  $endpoint = "deviceManagement/windowsAutopilotDeviceIdentities/$($deviceId)/UpdateDeviceProperties"
  $headers = Get-GraphHeader
  # Create the body
  $body = @{}
  $clear = @{}
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) {
    $body.Add("userPrincipalName",$userPrincipalName) | Out-Null
  }
  if ($PSBoundParameters.ContainsKey("groupTag")) {
    $body.Add("groupTag",$groupTag) | Out-Null
    $clear.Add("groupTag","") | Out-Null
  }
  if ($PSBoundParameters.ContainsKey("displayName")) {
    $body.Add("displayName",$displayName) | Out-Null
  }
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  if($clear.count -gt 0){
    Invoke-RestMethod -Method "POST" -URI $uri -Headers $headers -Body ($clear | ConvertTo-Json) -StatusCodeVariable "statusCode"
    Start-Sleep -Seconds 5
    Invoke-RestMethod -Headers $headers -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotSettings/sync" -Method "POST"  
  }  
  if($body.count -gt 0){
    Invoke-RestMethod -Method "POST" -URI $uri -Headers $headers -Body ($body | ConvertTo-Json) -StatusCodeVariable "statusCode"
    Start-Sleep -Seconds 5
  }   
}