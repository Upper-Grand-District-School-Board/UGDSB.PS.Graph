function Send-GraphMailMessage{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$from,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$subject,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$message,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$to,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$cc,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$bcc,
    [Parameter()][ValidateSet("html","text")][string]$contenttype = "html",
    [Parameter(Mandatory = $false)][switch]$savetosentitems
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  $mailbody = @{
    "message" = @{
      "subject" = $subject
      "body" = @{
        "contentType" = $contenttype
        "content" = $message
      }
    }
    "saveToSentItems" = $savetosentitems.IsPresent
  }
  # Loop through recipients and add them as appropriate
  $mailto = [System.Collections.Generic.List[Hashtable]]@()
  $mailcc = [System.Collections.Generic.List[Hashtable]]@()
  $mailbcc = [System.Collections.Generic.List[Hashtable]]@()
  foreach($item in $to){
    $obj = @{
      "emailAddress" = @{
        "address" = $item
      }
    }
    $mailto.add($obj) | Out-Null
  }
  foreach($item in $cc){
    $obj = @{
      "emailAddress" = @{
        "address" = $item
      }
    }
    $mailcc.add($obj) | Out-Null
  }
  foreach($item in $bcc){
    $obj = @{
      "emailAddress" = @{
        "address" = $item
      }
    }
    $mailbcc.add($obj) | Out-Null
  }    
  $mailbody.message.add("toRecipients",$mailto)
  if($mailcc){
    $mailbody.message.add("ccRecipients",$mailcc)
  }
  if($mailbcc){
    $mailbody.message.add("bccRecipients",$mailbcc)
  }
  # Mail endpoint
  $uri = "https://graph.microsoft.com/beta/users/$($from)/sendMail"
  # Get Graph Header
  $headers = Get-GraphHeader  
  # Send Email
  Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body ($mailbody | ConvertTo-Json -Depth 5) -StatusCodeVariable statuscode
  return $statuscode
}