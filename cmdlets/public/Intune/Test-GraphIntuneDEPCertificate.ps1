function Test-GraphIntuneDEPCertificate{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$days,
    [Parameter()][ValidateNotNullOrEmpty()][string]$emailfrom,
    [Parameter()][ValidateNotNullOrEmpty()][string]$emailto,
    [Parameter()][ValidateNotNullOrEmpty()][string]$teamswebhook
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }   
  # List of Alerts
  $alerts = [System.Collections.Generic.List[Hashtable]]@()
  # Get DEP Tokens
  $DEPTokens = Get-GraphIntuneDEPCertificate
  foreach($DEP in $DEPTokens){
    $DEPTokenDaysLeft = ($DEP.tokenExpirationDateTime - (Get-Date))
    if ($DEPTokenDaysLeft.Days -le $days) {
      $obj = [ordered]@{
        "Status" = "Apple DEP Token expires in $($DEPTokenDaysLeft.Days) days"
        "appleid" = $DEP.appleIdentifier
        "expiry" = $DEP.tokenExpirationDateTime.ToShortDateString()
        "displayname" = $DEP.tokenName
      }
      $alerts.add($obj) | Out-Null
    }
  }
  if($alerts -and $teamswebhook){
    foreach($item in $alerts){
      $message = @{
        "webhook"           = $teamswebhook
        "summary"           = "Intune Apple Notification"
        "activityimageuri"  = "https://dev.azure.com/jeremyputman/71648e28-a38f-4acc-bafa-aa569ba7b3f8/_apis/git/repositories/d80cf88f-316e-4d8d-b8f5-d40311acc791/items?path=/Resources/Images/warning.png&%24format=octetStream"
        "title"             = $item.Status
        "activitytitle"     = "Action Required!"
        "activitytext"      = "Must be renewed by IT Admin before the expiry date."
        "facts"             = [ordered]@{
                            "Connector:"    = "Apple DEP Token"
                            "Status:"       = $item.Status
                            "Display Name:" = $item.displayname
                            "AppleID:"      = $item.appleid
                            "Expiry Date:"  = $item.expiry      
        }
      }
      Send-TeamsMessage @message | Out-Null      
    }
  }
  if($alerts -and $emailfrom -and $emailto){
    foreach($item in $alerts){
      $message = @{
        "from" = $emailfrom
        "to" = $emailto
        "subject" = $item.Status
        "savetosentitems" = $true
        "message" = "
        <h2>Action Required!</h2>
        <strong>Connector:</strong> Apple DEP Token<br/>
        <strong>Status:</strong> $($item.Status)<br/>
        <strong>Display Name:</strong> $($item.displayname)<br/>
        <strong>AppleID:</strong> $($item.appleid)<br/>
        <strong>Expiry Date:</strong> $($item.expiry)<br/>
        "
      }
      Send-GraphMailMessage @message | Out-Null      
    }
  }
  return $alerts  
}