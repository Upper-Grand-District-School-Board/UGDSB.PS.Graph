function Get-GraphIntuneAppAssignment{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$applicationid
  )
  $endpoint = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($applicationid)/assignments"
  $headers = Get-GraphHeader
  $results = Invoke-RestMethod -Method "GET" -Uri $endpoint -Headers $headers
  return $results.value
}