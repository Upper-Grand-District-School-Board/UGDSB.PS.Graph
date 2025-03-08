function Get-GraphMailAttachmentContent{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$mailbox,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$messageid,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$attachmentid,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$filename
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  $headers = Get-GraphHeader  
  Invoke-RestMethod -method "GET" -uri "https://graph.microsoft.com/beta/users/$($mailbox)/messages/$($messageid)/attachments/$($attachmentid)/`$value" -Headers $headers -OutFile $filename
}