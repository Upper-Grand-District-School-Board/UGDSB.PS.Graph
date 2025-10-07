function Add-GraphOATHToken {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$serialNumber,
    [Parameter(Mandatory = $true)][string]$manufacturer,
    [Parameter(Mandatory = $true)][string]$model,
    [Parameter(Mandatory = $true)][string]$secretKey,
    [Parameter(Mandatory = $true)][int]$timeIntervalInSeconds,
    [Parameter()][string]$assignTo
  )
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Get Graph Header
  $headers = Get-GraphHeader   
  $endpoint = "directory/authenticationMethodDevices/hardwareOathDevices"
  $body = @{
    "serialNumber"          = $serialNumber
    "manufacturer"          = $manufacturer
    "model"                 = $model
    "secretKey"             = $secretKey
    "timeIntervalInSeconds" = $timeIntervalInSeconds
  }
  if ($PSBoundParameters.ContainsKey("assignTo")) {
    $body["assignTo"] = @{id = $assignTo }
  }
  try {
    $results = Get-GraphAPI -method post -endpoint $endpoint -headers $headers -body $body -beta -Verbose:$VerbosePreference
    $results = ($results | ConvertFrom-Json)
    if($results.error){
      throw "Unable to add token. Code: $($results.error.code). Message: $($results.error.message)"
    }
  }
  catch {
    throw "Unable to add token. $($_.Exception.Message)"
  }
}

<#
  # Get Graph Header
  $headers = Get-GraphHeader   
  $endpoint = "directory/authenticationMethodDevices/hardwareOathDevices"
  $body = @{
    "serialNumber"          = $serialNumber
    "manufacturer"          = $manufacturer
    "model"                 = $model
    "secretKey"             = $secretKey
    "timeIntervalInSeconds" = $timeIntervalInSeconds
  }
  if ($PSBoundParameters.ContainsKey("assignTo")) {
    $body["assignTo"] = @{id = $assignTo }
  }
  try {
    $results = Get-GraphAPI -method post -endpoint $endpoint -headers $headers -body $body -beta -Verbose:$VerbosePreference
    $results = ($results | ConvertFrom-Json)
    if($results.error){
      throw "Unable to add token. Code: $($results.error.code). Message: $($results.error.message)"
    }
  }
  catch {
    throw "Unable to add token. $($_.Exception.Message)"
  }
#>