function Test-GraphIntuneAPNCertificate{
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
  # Get the APN Certificate
  $APNCertificate = Get-GraphIntuneAPNCertificate
  # Times for Certificate
  $APNExpDate = $APNCertificate.expirationDateTime
  $APNIdentifier = $APNCertificate.appleIdentifier
  $APNExpShortDate = $APNExpDate.ToShortDateString()  
  # Set Status as null
  $APNExpirationStatus = $null
  # If the certificate has already expired
  if ($APNExpDate -lt (Get-Date)) {
    $APNExpirationStatus = "Apple MDM Push certificate has already expired"
  }
  else{
    $APNDaysLeft = ($APNExpDate - (Get-Date))
    if ($APNDaysLeft.Days -le $APNCertificateDays) {
      $APNExpirationStatus = "Apple MDM Push certificate expires in $($APNDaysLeft.Days) days"
    }
  }
  if($APNExpirationStatus -and $teamswebhook){
    $message = @{
      "webhook"           = $teamswebhook
      "summary"           = "Intune Apple Notification"
      "activityimageuri"  = "https://dev.azure.com/jeremyputman/71648e28-a38f-4acc-bafa-aa569ba7b3f8/_apis/git/repositories/d80cf88f-316e-4d8d-b8f5-d40311acc791/items?path=/Resources/Images/warning.png&%24format=octetStream"
      "title"             = $APNExpirationStatus
      "activitytitle"     = "Action Required!"
      "activitytext"      = "Must be renewed by IT Admin before the expiry date."
      "facts"             = [ordered]@{
                          "Connector:"    = "Apple Push Notification Certificate"
                          "Status:"       = $APNExpirationStatus
                          "AppleID:"      = $APNIdentifier
                          "Expiry Date:"  = $APNExpShortDate        
      }
    }
    Send-TeamsMessage @message | Out-Null
  }
  if($APNExpirationStatus -and $emailfrom -and $emailto){
    $message = @{
      "from" = $emailfrom
      "to" = $emailto
      "subject" = $APNExpirationStatus
      "savetosentitems" = $true
      "message" = "
      <strong style='font-size:14px;'>Action Required!</strong><br/><br/>
      <strong>Connector:</strong> Apple Push Notification Certificate<br/>
      <strong>Status:</strong> $($APNExpirationStatus)<br/>
      <strong>AppleID:</strong> $($APNIdentifier)<br/>
      <strong>Expiry Date:</strong> $($APNExpShortDate)<br/>
      "
    }
    Send-GraphMailMessage @message | Out-Null
  }
  return $APNExpirationStatus
}