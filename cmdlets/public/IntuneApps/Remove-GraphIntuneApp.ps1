function Remove-GraphIntuneApp{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$applicationid
  )
  # Invoke graph API to remove the application
  $endpoint = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($applicationid)"
  $headers = Get-GraphHeader
  Invoke-RestMethod -Method Delete -Uri $endpoint -Headers $headers -StatusCodeVariable statusCode | Out-Null
}