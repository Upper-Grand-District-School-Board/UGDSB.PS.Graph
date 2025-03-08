function Get-GraphMailRules {
  [CmdletBinding()]
  [OutputType([System.Collections.Generic.List[PSCustomObject]])]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = 'userPrincipalName')][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Alias("id")][Parameter(Mandatory = $true, ParameterSetName = 'userid')][ValidateNotNullOrEmpty()][string]$userid
  )
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) { 
    $endpoint = "https://graph.microsoft.com/beta/users/$($userPrincipalName)/mailFolders/inbox/messageRules"
  }
  if ($PSBoundParameters.ContainsKey("userid")) { 
    $endpoint = "https://graph.microsoft.com/beta/users/$($userid)/mailFolders/inbox/messageRules"
  }   
  $headers = Get-GraphHeader
  $results = Invoke-RestMethod -Method Get -Uri $endpoint -Headers $headers -StatusCodeVariable statusCode
  $results.value
}