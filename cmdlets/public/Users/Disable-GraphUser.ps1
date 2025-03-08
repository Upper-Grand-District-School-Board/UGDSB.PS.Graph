function Disable-GraphUser{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'userPrincipalName')][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Alias("id")][Parameter(Mandatory = $true, ParameterSetName = 'userid')][ValidateNotNullOrEmpty()][string]$userid
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) { 
    $endpoint = "https://graph.microsoft.com/beta/users/$($userPrincipalName)"
  }
  if ($PSBoundParameters.ContainsKey("userid")) { 
    $endpoint = "https://graph.microsoft.com/beta/users/$($userid)"
  }
  $body = @{
    accountEnabled = $false
  }
  $headers = Get-GraphHeader
  Invoke-RestMethod -Method PATCH -Uri $endpoint -Headers $headers -body ($body | ConvertTo-Json) -StatusCodeVariable statusCode
}