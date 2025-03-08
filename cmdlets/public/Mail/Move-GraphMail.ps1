<#
  .DESCRIPTION
  This cmdlet is designed to move emails between folders in a mailbox
  .PARAMETER id
  The id of the mail message we are acting on
  .PARAMETER emailAddress
  The email address of the account that we are reading from
  .PARAMETER folder
  The id of the folder that we are moving the message to
#>
function Move-GraphMail{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$id,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$emailAddress,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$folder
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  $headers = Get-GraphHeader
  # Body Content
  $body = @{
    "destinationId" = $folder
  } | ConvertTo-Json 
  $uri = "https://graph.microsoft.com/beta/users/$($emailAddress)/messages/$($id)/move"
  $results = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -StatusCodeVariable statusCode
  # Return Results
  if($statusCode -in (200,201)){
    return $results
  }
  else{
    throw "Unable to move email."
  }      
}