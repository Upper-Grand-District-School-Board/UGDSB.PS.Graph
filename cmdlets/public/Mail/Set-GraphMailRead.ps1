<#
  .DESCRIPTION
  This cmdlet is designed to mark a specific email as read
  .PARAMETER id
  The id of the mail message we are acting on
  .PARAMETER emailAddress
  The email address of the account that we are reading from
#>
function Set-GraphMailRead{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$id,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$emailAddress
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  $headers = Get-GraphHeader
  # Body Content
  $body = @{
    "isRead" = $true
  } | ConvertTo-Json
  # Execute Graph Call
  $uri = "https://graph.microsoft.com/beta/users/$($emailAddress)/messages/$($id)"
  $results = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body -StatusCodeVariable statusCode
  # Return Results
  if($statusCode -in (200,201)){
    return $results
  }
  else{
    throw "Unable to mark email as read."
  }  
}