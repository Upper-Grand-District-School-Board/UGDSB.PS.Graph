function Remove-GraphMailRule{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = 'userPrincipalName')][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Alias("id")][Parameter(Mandatory = $true, ParameterSetName = 'userid')][ValidateNotNullOrEmpty()][string]$userid,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ruleid
  )  
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) { 
    $endpoint = "https://graph.microsoft.com/beta/users/$($userPrincipalName)/mailFolders/inbox/messageRules/$($ruleid)"
  }
  if ($PSBoundParameters.ContainsKey("userid")) { 
    $endpoint = "https://graph.microsoft.com/beta/users/$($userid)/mailFolders/inbox/messageRules/$($ruleid)"
  }
  $headers = Get-GraphHeader
  Invoke-RestMethod -Method Delete -Uri $endpoint -Headers $headers -StatusCodeVariable statusCode | Out-Null
}