function Add-GraphIntuneAppAddToESP{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'id')][ValidateNotNullOrEmpty()][string]$id,
    [Parameter(Mandatory = $true, ParameterSetName = 'displayName')][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$applicationid
  )
  # Body for JSON
  if($id){
    $currentData = Get-GraphIntuneEnrollmentStatusPage -id $id
  }
  elseif($displayName){
    $currentData = Get-GraphIntuneEnrollmentStatusPage -displayName $displayName
  }
  # Endpoint
  $endpoint = "deviceManagement/deviceEnrollmentConfigurations/$($currentData.id)"
  # Add Application to the ESP
  $currentData.selectedMobileAppIds = @("$($currentData.selectedMobileAppIds -join ','),$($applicationid)") -split ","
  $params = @{
    "@odata.type"                             = "#microsoft.graph.windows10EnrollmentCompletionPageConfiguration"
    id                                        = $currentData.id
    displayName                               = $currentData.displayName
    description                               = $currentData.description
    showInstallationProgress                  = $currentData.showInstallationProgress
    blockDeviceSetupRetryByUser               = $currentData.blockDeviceSetupRetryByUser
    allowDeviceResetOnInstallFailure          = $currentData.allowDeviceResetOnInstallFailure
    allowLogCollectionOnInstallFailure        = $currentData.allowLogCollectionOnInstallFailure
    customErrorMessage                        = $currentData.customErrorMessage
    installProgressTimeoutInMinutes           = $currentData.installProgressTimeoutInMinutes
    allowDeviceUseOnInstallFailure            = $currentData.allowDeviceUseOnInstallFailure
    selectedMobileAppIds                      = $currentData.selectedMobileAppIds
    trackInstallProgressForAutopilotOnly      = $currentData.trackInstallProgressForAutopilotOnly
    disableUserStatusTrackingAfterFirstUser   = $currentData.disableUserStatusTrackingAfterFirstUser
    roleScopeTagIds                           = $currentData.roleScopeTagIds
    allowNonBlockingAppInstallation           = $currentData.allowNonBlockingAppInstallation
    installQualityUpdates                     = $currentData.installQualityUpdates
  }
  try{
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    $headers = Get-GraphHeader
    Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $($params | ConvertTo-Json -Depth 10) -StatusCodeVariable statusCode
  }
  catch{
    $_
  }
}