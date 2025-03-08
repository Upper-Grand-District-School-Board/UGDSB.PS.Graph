#Region '.\Public\Add-GraphGroupMember.ps1' 0
function Add-GraphGroupMember{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$groupId,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$ids
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # Get Graph Headers for Call
  $headers = Get-GraphHeader  
  try{
    $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
    $batches = [System.Collections.Generic.List[PSCustomObject]]@()
    for($i = 1; $i -le $ids.Count; ++$i){
      $obj = [PSCustomObject]@{
        "id" = $i
        "headers" = @{
          "Content-type" = "application/json"
        }
        "method" = "POST"
        "url" = "/groups/$($groupId)/members/`$ref"
        "body" = @{
          "@odata.id" = "https://graph.microsoft.com/beta/directoryObjects/$($ids[$i-1])"
        }
      }
      $batchObj.Add($obj) | Out-Null        
      if($($i % 20) -eq 0){
        $batches.Add($batchObj) | Out-Null
        $batchObj = $null
        $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
      }
    }
    $batches.Add($batchObj) | Out-Null
    foreach($batch in $batches){
      $json = [PSCustomObject]@{
        "requests" = $batch
      } | ConvertTo-JSON -Depth 5
      $results = Invoke-RestMethod -Method "POST" -Uri "https://graph.microsoft.com/beta/`$batch" -Headers $headers -Body $json
    }
    
  } 
  catch{
    throw "Unable to add members. $($_.Exception.Message)"
  }  
}
#EndRegion '.\Public\Add-GraphGroupMember.ps1' 48
#Region '.\Public\Add-GraphIntuneAppAddToESP.ps1' 0
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
#EndRegion '.\Public\Add-GraphIntuneAppAddToESP.ps1' 47
#Region '.\Public\Add-GraphIntuneAppAssignment.ps1' 0
function Add-GraphIntuneAppAssignment{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$applicationid,
    [Parameter(Mandatory = $true)][ValidateSet("available","required","uninstall")][string]$intent,
    [Parameter(Mandatory = $false)][string[]]$groups,
    [Parameter(Mandatory = $false)][Object[]]$filters = $null,
    [Parameter(Mandatory = $false)][switch]$exclude,
    [Parameter(Mandatory = $false)][bool]$foreground = $false,
    [Parameter(Mandatory = $false)][ValidateSet("Output","Verbose")][string]$LogLevel = "Verbose"
  )
  # Default format for assignment body
  $assignment = [PSCustomObject]@{
    "@odata.type" = "#microsoft.graph.mobileAppAssignment"
    "intent" = $intent
    "target" = $null
    "settings" = $null
  }
  foreach($group in $groups){
    # Set Filter details
    $filterId = $null
    $filterType = "none"
    if($null -ne $filters.$group){
      $assignmentFilters = Get-GraphIntuneFilters
      $filterId = ($assignmentFilters | Where-Object {$_.DisplayName -eq $filters.$group.filterName}).id
      $filterType = $filters.$group.filterType
    }
    $target = [PSCustomObject]@{
      "deviceAndAppManagementAssignmentFilterId" = $filterId
      "deviceAndAppManagementAssignmentFilterType" = $filterType
    }
    # Targeting Values
    switch($group.ToLower()){
      "all users" {
        $target | Add-Member -MemberType "NoteProperty" -Name "@odata.type" -Value "#microsoft.graph.allLicensedUsersAssignmentTarget"
      }
      "all devices" {
        $target | Add-Member -MemberType "NoteProperty" -Name "@odata.type" -Value "#microsoft.graph.allDevicesAssignmentTarget"
      }
      default {
        if($exclude){
          $target | Add-Member -MemberType "NoteProperty" -Name "@odata.type" -Value "#microsoft.graph.exclusionGroupAssignmentTarget"
        }
        else{
          $target | Add-Member -MemberType "NoteProperty" -Name "@odata.type" -Value "#microsoft.graph.groupAssignmentTarget"
        }
        try{
          $groupdetails = Get-GraphGroup -groupName $group
          $target | Add-Member -MemberType "NoteProperty" -Name "groupId" -Value $groupdetails.id
        }
        catch{
          throw "Unable to get ID of the group selected. $($_.Exception.Message)"
        }
      }
    }
    $assignment.target = $target
    # Settings Values
    if(!$exclude){
      $settings = [PSCustomObject]@{
        "@odata.type" = "#microsoft.graph.win32LobAppAssignmentSettings"
      }
      if($foreground){
        $settings | Add-Member -MemberType "NoteProperty" -Name "deliveryOptimizationPriority" -Value "foreground"
      }
      $assignment.settings = $settings
    }
    try{
      $endpoint = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($applicationid)/assignments"
      $headers = Get-GraphHeader
      Invoke-RestMethod -Method post -Uri $endpoint -Headers $headers -Body $($assignment | ConvertTo-Json -Depth 10) -StatusCodeVariable statusCode | Out-Null
    }
    catch{
      if(([REGEX]::Match($((($_ | ConvertFrom-Json).error.message | ConvertFrom-JSON).Message),"The MobileApp Assignment already exists")).Success){
        continue
      }
      else{
        throw $($_.Exception.Message)
      }
    }
  }
}
#EndRegion '.\Public\Add-GraphIntuneAppAssignment.ps1' 82
#Region '.\Public\Copy-GraphIntuneAppAssignments.ps1' 0
function Copy-GraphIntuneAppAssignments{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$applicationid,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$copyapplicationid
  )
  # Get the Assignments that we will be copying
  $assignments = Get-GraphIntuneAppAssignment -applicationid $copyapplicationid
  # Loop through the assignments
  foreach($assignment in $assignments){
    $assignment = [PSCustomObject]@{
      "@odata.type" = "#microsoft.graph.mobileAppAssignment"
      "intent" = $assignment.intent
      "target" = $assignment.target
      "settings" = $assignment.settings
    }
    try{
      $endpoint = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($applicationid)/assignments"
      $headers = Get-GraphHeader
      Invoke-RestMethod -Method post -Uri $endpoint -Headers $headers -Body $($assignment | ConvertTo-Json -Depth 10) -StatusCodeVariable statusCode | Out-Null
    }
    catch{
      if(([REGEX]::Match($((($_ | ConvertFrom-Json).error.message | ConvertFrom-JSON).Message),"The MobileApp Assignment already exists")).Success){
        continue
      }
      else{
        throw $($_.Exception.Message)
      }
    }
  }
}
#EndRegion '.\Public\Copy-GraphIntuneAppAssignments.ps1' 32
#Region '.\Public\Disable-GraphUser.ps1' 0
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
#EndRegion '.\Public\Disable-GraphUser.ps1' 23
#Region '.\Public\Get-GraphAccessPackageAssignments.ps1' 0
function Get-GraphAccessPackageAssignments{
  [cmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$accessPackageId,
    [Parameter()][ValidateNotNullOrEmpty()][string]$groupid,
    [Parameter()][ValidateNotNullOrEmpty()][string]$groupname
  )  
  $endpoint = "identityGovernance/entitlementManagement/accessPackageAssignmentPolicies"
  if($id){
    $endpoint = "$($endpoint)?`$filter=id eq '$id'"
  }
  elseif($displayName){
    $endpoint = "$($endpoint)?`$filter=displayName eq '$displayName'"
  }
  elseif($accessPackageId){
    $endpoint = "$($endpoint)?`$filter=accessPackageId eq '$accessPackageId'"
  }
  # Create empty list
  $List = [System.Collections.Generic.List[PSCustomObject]]@()
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  try {
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    do {
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      if ($results.value) {
        foreach ($item in $results.value) {
          if($groupid -or $groupName){
            $skipItem = $true
            if($item.requestorSettings.allowedRequestors.id -contains $groupID){
              $skipItem = $false
            }
            if($item.requestorSettings.allowedRequestors.description -contains $groupname){
              $skipItem = $false
            }
            if($item.requestApprovalSettings.approvalStages.primaryApprovers.id -contains $groupID){
              $skipItem = $false
            }
            if($item.requestApprovalSettings.approvalStages.primaryApprovers.description -contains $groupname){
              $skipItem = $false
            }                        
          }
          if($skipItem){continue}
          $List.add($item)
        }
      }
      $uri = $results."@odata.nextLink"
    }while ($null -ne $results."@odata.nextLink")
  }
  catch {
    throw "Unable to get Access Packages. $($_.Exception.Message)"
  }  
  return $List    
}
#EndRegion '.\Public\Get-GraphAccessPackageAssignments.ps1' 57
#Region '.\Public\Get-GraphAccessPackageCatalog.ps1' 0
function Get-GraphAccessPackageCatalog{
  [cmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName
  )
  $endpoint = "identityGovernance/entitlementManagement/accessPackageCatalogs"
  if($id){
    $endpoint = "$($endpoint)?`$filter=id eq '$id'"
  }
  elseif($displayName){
    $endpoint = "$($endpoint)?`$filter=displayName eq '$displayName'"
  }
  # Create empty list
  $List = [System.Collections.Generic.List[PSCustomObject]]@()
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  try {
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    do {
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      if ($results.value) {
        foreach ($item in $results.value) {
          $List.add($item)
        }
      }
      $uri = $results."@odata.nextLink"
    }while ($null -ne $results."@odata.nextLink")
  }
  catch {
    throw "Unable to get Access Packages. $($_.Exception.Message)"
  }  
  return $List
}
#EndRegion '.\Public\Get-GraphAccessPackageCatalog.ps1' 35
#Region '.\Public\Get-GraphAccessPackages.ps1' 0
function Get-GraphAccessPackages {
  [cmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$id
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # URI Endpoint
  $endpoint = "identityGovernance/entitlementManagement/accessPackages"
  if ($id) {
    $endpoint = "$($endpoint)?`$filter=id eq '$($id)'"
  }
  elseif ($displayName) {
    $endpoint = "$($endpoint)?`$filter=displayName eq '$($displayName)'"
  }
  # Create empty list
  $List = [System.Collections.Generic.List[PSCustomObject]]@()
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  try {
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    do {
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      if ($results.value) {
        foreach ($item in $results.value) {
          $List.add($item)
        }
      }
      $uri = $results."@odata.nextLink"
    }while ($null -ne $results."@odata.nextLink")
  }
  catch {
    throw "Unable to get Access Packages. $($_.Exception.Message)"
  }  
  return $List    
}
#EndRegion '.\Public\Get-GraphAccessPackages.ps1' 39
#Region '.\Public\Get-GraphAccessToken.ps1' 0
<#
  .DESCRIPTION
  This cmdlet is designed to use MSAL.PS to get an access token through an app registration, and then store in a global access token variable
  .PARAMETER clientID
  The client ID for the app registration used
  .PARAMETER clientSecret
  The secret used for the app registration
  .PARAMETER tenantID
  The tenant id for the app registration
#>
function Get-GraphAccessToken{
  [CmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$clientID,
    [Parameter()][ValidateNotNullOrEmpty()][string]$tenantID,
    [Parameter()][ValidateNotNullOrEmpty()][string]$clientSecret,
    [Parameter()][switch]$interactive,
    [Parameter()][ValidateNotNullOrEmpty()][PSCustomObject]$azToken
  )
  if($(Test-GraphAcessToken $script:graphAccessToken)){
    return $script:graphAccessToken
  }  
  Add-Type -Path "$($PSScriptRoot)\Microsoft.Identity.Client.dll" -ErrorAction SilentlyContinue | Out-Null
  [string[]]$scopes = @("https://graph.microsoft.com/.default")

  try{
    if($interactive.IsPresent){
      $clientApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($clientId).WithAuthority("https://login.microsoftonline.com/$tenantId").WithDefaultRedirectUri().Build()
      $authenticationResult = $clientApp.AcquireTokenInteractive($scopes).ExecuteAsync().GetAwaiter().GetResult()
    }
    elseif($clientSecret){
      $clientApp = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($clientId).WithClientSecret($clientSecret).WithAuthority("https://login.microsoftonline.com/$tenantId").Build()
      $authenticationResult = $clientApp.AcquireTokenForClient($scopes).ExecuteAsync().GetAwaiter().GetResult()
    }
    elseif($azToken){
      $authenticationResult = $azToken.PSObject.Copy()
      $authenticationResult | Add-Member -MemberType AliasProperty -Name "AccessToken" -Value "Token" -Force

    }
    $script:graphAccessToken = $authenticationResult
    return $script:graphAccessToken
  }
  catch{
    throw "Unable to generate access token. Error message: $($_)"
  }
}
#EndRegion '.\Public\Get-GraphAccessToken.ps1' 47
#Region '.\Public\Get-GraphAPI.ps1' 0
function Get-GraphAPI {
  [CmdletBinding()]
  [OutputType([System.Collections.Generic.List[PSCustomObject]])]
  param(
    [Parameter(Mandatory = $true)][string]$endpoint,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$headers,
    [Parameter()][ValidateSet("Get", "Post", "Patch", "Delete", "Put")][string]$Method = "Get",
    [Parameter()][ValidateNotNullOrEmpty()]$body,
    [Parameter()][switch]$beta
  )
  $uri = "https://graph.microsoft.com/v1.0/"
  if ($PSBoundParameters.ContainsKey("beta")) { 
    $uri = $uri -replace "v1.0", "beta"
  }
  $uri = "$($uri)$($endpoint)"
  try {
    $Vars = @{
      Method             = $Method
      Uri                = $uri
      StatusCodeVariable = 'statusCode'
      headers            = $headers
    }
    if ($PSBoundParameters.ContainsKey("body")) { 
      $vars.add("body", ($body | ConvertTo-JSON))
    }
    Write-Verbose "Calling API endpoint: $($uri)" 
    $results = Invoke-RestMethod @Vars
  }
  catch {
    $ErrorMsg = $script:Error[0]
    return $ErrorMsg
  }
  return [PSCustomObject]@{
    StatusCode = $statusCode
    Results    = $results
  } 
}
#EndRegion '.\Public\Get-GraphAPI.ps1' 38
#Region '.\Public\Get-GraphAutopilotInformation.ps1' 0
function Get-GraphAutopilotInformation {
  [CmdletBinding()]
  param(
    [parameter()][ValidateNotNullOrEmpty()][string]$SerialNumber,
    [parameter()][ValidateNotNullOrEmpty()][string]$groupTag,
    [parameter()][ValidateNotNullOrEmpty()][string]$manufacturer,
    [parameter()][ValidateNotNullOrEmpty()][string]$model,
    [parameter()][ValidateNotNullOrEmpty()][string]$azureAdDeviceId
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  $endpoint = "deviceManagement/windowsAutopilotDeviceIdentities"
  # Create empty list
  $filters = [System.Collections.Generic.List[PSCustomObject]]@()
  if($groupTag){
    $filters.Add("contains(groupTag,'$($groupTag)')") | Out-Null
  }
  if($SerialNumber){
    $filters.Add("contains(SerialNumber,'$($SerialNumber)')") | Out-Null
  }  
  if($manufacturer){
    $filters.Add("contains(manufacturer,'$($manufacturer)')") | Out-Null
  }   
  if($model){
    $filters.Add("contains(model,'$($model)')") | Out-Null
  }   
  if($userPrincipalName){
    $filters.Add("contains(userPrincipalName,'$($userPrincipalName)')") | Out-Null
  }  
  if($azureAdDeviceId){
    $filters.Add("contains(azureAdDeviceId,'$($azureAdDeviceId)')") | Out-Null
  }  
  # Create query string for the filter
  $filterList = $filters -join " and "  
  if($filterList){
    $endpoint = "$($endpoint)?`$filter=$($filterList)"
  }  
  # Create empty list
  $deviceList = [System.Collections.Generic.List[PSCustomObject]]@() 
  # Get Graph Headers for Call
  $headers = Get-GraphHeader 
  # Get Autopilot Devices
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  do {
    # Execute call against graph
    $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode 
    foreach($item in $results.value){
      $deviceList.Add($item) | Out-Null
    }
    # Set the URI to the nextlink if it exists
    $uri = $results."@odata.nextLink"     
  }while ($null -ne $results."@odata.nextLink")
  return $deviceList
}
#EndRegion '.\Public\Get-GraphAutopilotInformation.ps1' 56
#Region '.\Public\Get-GraphDevice.ps1' 0
<#
  .DESCRIPTION
  This cmdlet is designed to get devices from Azure ID
#>
function Get-GraphDevice{
  [CmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$deviceId,
    [Parameter()][ValidateNotNullOrEmpty()][bool]$accountEnabled,
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$fields
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # Create empty list
  $filters =  [System.Collections.Generic.List[PSCustomObject]]@()  
  if($displayName){
    $filters.Add("displayName eq '$($displayName)'") | Out-Null
  }
  if($accountEnabled){
    $filters.Add("accountEnabled eq '$($accountEnabled)'") | Out-Null
  }
  if($deviceId.count -eq 1){  
    $filters.Add("deviceId eq '$($deviceId)'") | Out-Null
  }
  $batch = $false
  # General endpoint
  $endpoint = "devices"
  if($id.count -eq 1){
    $endpoint = "$($endpoint)/$($id)"
  }
  elseif($id.count -gt 1 -or $deviceId.count -gt 1){
    $batch = $true
  }
  # Create query string for the filter
  $filterList = $filters -join " and "
  # Create empty list
  $deviceList =  [System.Collections.Generic.List[PSCustomObject]]@() 
  # Get Graph Headers for Call
  $headers = Get-GraphHeader       
  # If ID and deviceID are not an array
  if(-not $batch){
    # Setup endpoint based on if filter or fields are passed
    if($filterList){
      $endpoint = "$($endpoint)?`$filter=$($filterList)"
    }
    if($filterList -and $fields){
      $endpoint = "$($endpoint)&`$select=$($fields)"
    }
    elseif($fields){
      $endpoint = "$($endpoint)?`$select=$($fields)"
    }    
    # Try to call graph API and get results back
    try{
      $uri = "https://graph.microsoft.com/beta/$($endpoint)"
      do{
        $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
        if($results.value){
          foreach($item in $results.value){
            $deviceList.Add($item) | Out-Null
          }
        }
        else{
          $deviceList.Add($results) | Out-Null
        }
        $uri = $results."@odata.nextLink"
      }while($null -ne $results."@odata.nextLink")      
    }
    catch{
      throw "Unable to get devices. $($_.Exception.Message)"
    } 
    return $deviceList   
  }
  # If a batch job because id or device id is an array
  else{
    $objid = 1
    $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
    $batches = [System.Collections.Generic.List[PSCustomObject]]@()
    # if trying to return multiple ids
    if($id.count -gt 1){
      foreach($device in $id){
        if($objid -lt 21){
          if($fields){
            $uri = "$($endpoint)/$($device)?`$select=$($fields)"
          }
          else{
            $uri = "$($endpoint)/$($device)"
          }
          $obj = [PSCustomObject]@{
            "id" = $objid
            "method" = "GET"
            "url" = $uri
          }
          $batchObj.Add($obj) | Out-Null
          $objid++          
        }
        if($objId -eq 21){
          $batches.Add($batchObj) | Out-Null
          $batchObj = $null
          $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
          $objid = 1 
        }        
      }
      $batches.Add($batchObj) | Out-Null
    }
    # if trying to return multiple deviceids
    elseif($deviceId.Count -gt 1){
      foreach($device in $deviceId){
        if($objid -lt 21){
          if($fields){
            $uri = "$($endpoint)?`$filter=deviceId eq '$($device)'&`$select=$($fields)"
          }
          else{
            $uri = "$($endpoint)?`$filter=deviceId eq '$($device)'"
          }
          $obj = [PSCustomObject]@{
            "id" = $objid
            "method" = "GET"
            "url" = $uri
          }
          $batchObj.Add($obj) | Out-Null
          $objid++          
        }
        if($objId -eq 21){
          $batches.Add($batchObj) | Out-Null
          $batchObj = $null
          $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
          $objid = 1 
        }        
      }
      $batches.Add($batchObj) | Out-Null
    }
    for($x = 0; $x -lt $batches.count; $x++){
      if($batches[$x].count -gt 0){
        $json = [PSCustomObject]@{
          "requests" = $batches[$x] 
        } | ConvertTo-JSON    
        $results = Invoke-RestMethod -Method "POST" -Uri "https://graph.microsoft.com/beta/`$batch" -Headers $headers -Body $json
        foreach($item in $results.responses.body){
          if($item.value){
            $deviceList.Add($item.value) | Out-Null
          }
          else{
            $deviceList.Add($item) | Out-Null
          }

        }
      }    
    }
    return $deviceList
  }
}
#EndRegion '.\Public\Get-GraphDevice.ps1' 155
#Region '.\Public\Get-GraphGroup.ps1' 0
<#
  .DESCRIPTION
  This cmdlet is designed to query graph for Entra ID groups
  .PARAMETER groupName
  If want to find based on group name
  .PARAMETER groupId
  If want to lookup by group id
  .PARAMETER All
  If want to return all groups
#>
function Get-GraphGroup{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'groupName')][ValidateNotNullOrEmpty()][string]$groupName,
    [Parameter(Mandatory = $true, ParameterSetName = 'groupId')][ValidateNotNullOrEmpty()][string]$groupId,
    [Parameter(Mandatory = $true, ParameterSetName = 'All')][switch]$All
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Create empty list
  $groupList =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Build the headers we will use to get groups
  $headers = Get-GraphHeader
  # Base URI for resource call
  $uri = "https://graph.microsoft.com/beta/groups"
  if($groupName){
    # Filter based on group name is required
    $uri = "$($uri)?`$filter=displayName eq '$($groupName)'"
  }
  elseif($groupId){
    # Filter based on group ID
    $uri = "$($uri)/$($groupId)"
  }
  try{
    # Loop until nextlink is null
    do{
      # Execute call against graph
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      # Add results to a list variable
      foreach($item in $results.value){
        $groupList.Add($item) | Out-Null
      }
      # Set the URI to the nextlink if it exists
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
    # If there is only one result, return that
    if($groupList.count -eq 0){
      return $results
    }
    else{
      # Return the group list if it exists
      return $groupList
    }
  }
  catch{
    throw "Unable to get groups. $($_.Exception.Message)"
  }
}
#EndRegion '.\Public\Get-GraphGroup.ps1' 61
#Region '.\Public\Get-GraphGroupMembers.ps1' 0
#https://learn.microsoft.com/en-us/graph/api/group-list-members?view=graph-rest-beta&tabs=http
function Get-GraphGroupMembers{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'groupName')][ValidateNotNullOrEmpty()][string]$groupName,
    [Parameter(Mandatory = $true, ParameterSetName = 'groupId')][ValidateNotNullOrEmpty()][string]$groupId,
    [Parameter()][switch]$Recurse
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get the Group ID if Group Name was Sent
  if($groupName){
    $group = Get-GraphGroup -groupName $groupName
    $groupId = $group.id
  }
  # Create empty list
  $groupMemberList =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Create List for recurse if needed
  $groupList =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Build the headers we will use to get groups
  $headers = Get-GraphHeader
  # Deterime if we just want members of transitive members
  if($Recurse){
    $uri = "https://graph.microsoft.com/beta/groups/$($groupId)/transitiveMembers"
  }
  else{
    $uri = "https://graph.microsoft.com/beta/groups/$($groupId)/members"
  }
  try{
    # Loop until nextlink is null
    do{
      # Execute call against graph
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      # Add results to a list variable
      foreach($item in $results.value){
        $groupMemberList.Add($item)
      }
      # Set the URI to the nextlink if it exists
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
    return $groupMemberList
  }
  catch{
    throw "Unable to get group members. $($_.Exception.Message)"
  }
}
#EndRegion '.\Public\Get-GraphGroupMembers.ps1' 49
#Region '.\Public\Get-GraphHeader.ps1' 0
<#
  .DESCRIPTION
  This cmdlet is designed to format the graph header for the REST api calls
  .PARAMETER ConsistencyLevel
  This field will add the ConsistencyLevel variable to eventual
#>
function Get-GraphHeader{
  [CmdletBinding()]
  param(
    [Parameter()][switch]$ConsistencyLevel
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Base header variables
  $headerVars = @{
    Authorization = "Bearer $($script:graphAccessToken.AccessToken)"
    "Content-Type" = "application/json"
  }
  # If flagged to include the Consitency Level header
  if($ConsistencyLevel.IsPresent){
    $headerVars.Add("ConsistencyLevel","eventual")
  }
  return $headerVars
}
#EndRegion '.\Public\Get-GraphHeader.ps1' 26
#Region '.\Public\Get-GraphIntuneAPNCertificate.ps1' 0
function Get-GraphIntuneAPNCertificate{
  [CmdletBinding()]
  param()
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # URI Endpoint
  $endpoint = "deviceManagement/applePushNotificationCertificate"
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  # Invoke Rest API
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
  # return results
  return $results
}
#EndRegion '.\Public\Get-GraphIntuneAPNCertificate.ps1' 17
#Region '.\Public\Get-GraphIntuneApp.ps1' 0
function Get-GraphIntuneApp{
  [CmdletBinding(DefaultParameterSetName = 'All')]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'id')][ValidateNotNullOrEmpty()][string]$id,
    [Parameter(Mandatory = $true, ParameterSetName = 'displayName')][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter()][ValidateNotNullOrEmpty()][ValidateSet("microsoft.graph.androidManagedStoreApp","microsoft.graph.iosStoreApp","microsoft.graph.iosVppApp","microsoft.graph.macOSLobApp","microsoft.graph.macOSMicrosoftEdgeApp","microsoft.graph.macOSOfficeSuiteApp","microsoft.graph.macOSPkgApp","microsoft.graph.macOsVppApp","microsoft.graph.managedAndroidStoreApp","microsoft.graph.managedIOSStoreApp","microsoft.graph.officeSuiteApp","microsoft.graph.webApp","microsoft.graph.win32LobApp","microsoft.graph.winGetApp")]
      [string]$type,
    [Parameter()][ValidateNotNullOrEmpty()][string]$fields
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  
  
  # URI Endpoint
  $endpoint = "deviceAppManagement/mobileApps"
  # Build filters for URI
  $filters =  [System.Collections.Generic.List[PSCustomObject]]@()
  if($id){
    $filters.Add("id eq '$($id)'") | Out-Null
  }
  if($displayName){
    $filters.Add("displayName eq '$($displayName)'") | Out-Null
  }  
  if($type){
    $filters.Add("(isof('$($type)'))") | Out-Null
  }   
  # Create query string for the filter
  $filterList = $filters -join " and "
  if($filterList){
    $endpoint = "$($endpoint)?`$filter=$($filterList)"
  }
  if($filterList -and $fields){
    $endpoint = "$($endpoint)&`$select=$($fields)"
  }
  elseif($fields){
    $endpoint = "$($endpoint)?`$select=$($fields)"
  }
  # Create empty list
  $applicationList =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  try{
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    do{
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      if($results.value){
        foreach($item in $results.value){
          $applicationList.add($item)
        }
      }
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
  }
  catch{
    throw "Unable to get devices. $($_.Exception.Message)"
  }  
  return $applicationList
}
#EndRegion '.\Public\Get-GraphIntuneApp.ps1' 60
#Region '.\Public\Get-GraphIntuneAppAssignment.ps1' 0
function Get-GraphIntuneAppAssignment{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$applicationid
  )
  $endpoint = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($applicationid)/assignments"
  $headers = Get-GraphHeader
  $results = Invoke-RestMethod -Method "GET" -Uri $endpoint -Headers $headers
  return $results.value
}
#EndRegion '.\Public\Get-GraphIntuneAppAssignment.ps1' 11
#Region '.\Public\Get-GraphIntuneDEPCertificate.ps1' 0
function Get-GraphIntuneDEPCertificate{
  [CmdletBinding()]
  param()
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # URI Endpoint
  $endpoint = "deviceManagement/depOnboardingSettings"
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  # Invoke Rest API
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
  # return results
  return $results.Value  
}
#EndRegion '.\Public\Get-GraphIntuneDEPCertificate.ps1' 17
#Region '.\Public\Get-GraphIntuneEnrollmentStatusPage.ps1' 0
function Get-GraphIntuneEnrollmentStatusPage{
  [CmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # URI Endpoint
  $endpoint = "deviceManagement/deviceEnrollmentConfigurations"
  if($id){
    $endpoint = "$($endpoint)/$($id)"
  }
  if($displayName){
    $endpoint = "$($endpoint)?`$filter=displayName eq '$($displayName)'"
  }
  # Create empty list
  $esplist =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  try{
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    do{
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      if($results.value){
        foreach($item in $results.value){
          $esplist.add($item)
        }
      }
      else{
        $esplist.add($results)
      }
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
  }
  catch{
    throw "Unable to get devices. $($_.Exception.Message)"
  }
  return $esplist  
}
#EndRegion '.\Public\Get-GraphIntuneEnrollmentStatusPage.ps1' 42
#Region '.\Public\Get-GraphIntuneFilters.ps1' 0
function Get-GraphIntuneFilters{
  [CmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$platform
  )
  # Construct array list to build the dynamic filter list
  $FilterList = [System.Collections.Generic.List[PSCustomObject]]@()
  if($id){
    $FilterList.Add("`$PSItem.id -eq '$($id)'") | Out-Null
  }
  if($displayName){
    $FilterList.Add("`$PSItem.displayName -eq '$($displayName)'") | Out-Null
  }
  if($platform){
    $FilterList.Add("`$PSItem.platform -eq '$($platform)'") | Out-Null
  }
  # Construct script block from filter list array
  $FilterExpression = [scriptblock]::Create(($FilterList -join " -and ")) 
  # Create empty list
  $filters =  [System.Collections.Generic.List[PSCustomObject]]@()
  # Build the headers we will use to get groups
  $headers = Get-GraphHeader  
  # Endpoint for the API
  $uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters"
  try{
    # Loop until nextlink is null
    do{
      # Execute call against graph
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      # Add results to a list variable
      foreach($item in $results.value){
        $filters.Add($item)
      }
      # Set the URI to the nextlink if it exists
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
    if($FilterList.Count -gt 0){
      return $filters | Where-Object -FilterScript $FilterExpression
    }
    return $filters
  }
  catch{
    throw "Unable to get group members. $($_.Exception.Message)"
  }  
}
#EndRegion '.\Public\Get-GraphIntuneFilters.ps1' 48
#Region '.\Public\Get-GraphIntuneVPPCertificate.ps1' 0
function Get-GraphIntuneVPPCertificate{
  [CmdletBinding()]
  param()
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # URI Endpoint
  $endpoint = "deviceAppManagement/vppTokens"
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  # Invoke Rest API
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
  # return results
  return $results.Value
}
#EndRegion '.\Public\Get-GraphIntuneVPPCertificate.ps1' 17
#Region '.\Public\Get-GraphMail.ps1' 0
<#
  .DESCRIPTION
  This cmdlet is designed to read email from a specific mailbox
  .PARAMETER mailbox
  The email address of the account that we are reading from
  .PARAMETER folder
  The ID of the folder that we want to read from, if it is not the whole mailbox
  .PARAMETER unread
  If we want to return only unread email
#>
function Get-GraphMail{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$mailbox,
    [Parameter()][ValidateNotNullOrEmpty()][string]$folderid,
    [Parameter(ParameterSetName = "unread")][switch]$unread,
    [Parameter(ParameterSetName = "filter")][string]$filter,
    [Parameter()][switch]$all
  )
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Get Graph Header
  $headers = Get-GraphHeader   
  $endpoint = "users/$($mailbox)"
  if ($PSBoundParameters.ContainsKey("folderid")) {
    $endpoint = "$($endpoint)/mailFolders/$($folderid)"
  }
  $endpoint = "$($endpoint)/messages"
  $uriparts = [System.Collections.Generic.List[PSCustomObject]]@()
  if ($PSBoundParameters.ContainsKey("unread")) {$uriparts.add("`$filter=isRead eq false")}
  if ($PSBoundParameters.ContainsKey("filter")) {$uriparts.add("`$filter=$($filter)")}
  # Generate the final API endppoint URI
  $endpoint = "$($endpoint)?$($uriparts -join "&")"    
  try {
    # Create empty list
    $maillist = [System.Collections.Generic.List[PSCustomObject]]@()    
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -headers $headers -beta -Verbose:$VerbosePreference
      # Add results to a list variable
      foreach ($item in $results.results.value) {
        $maillist.Add($item) | Out-Null
      }
      Write-Verbose "Returned $($results.results.value.Count) results. Current result set is $($maillist.Count) items." 
      if ($results.results."@odata.nextLink") {
        $uri = [REGEX]::Match($results.results."@odata.nextLink", "users.*").Value
      }
    }while ($null -ne $results.results."@odata.nextLink" -and $all.IsPresent)
  }
  catch {
    throw "Unable to get users. $($_.Exception.Message)"
  } 
  if($maillist.count -eq 0){
    return $results
  }
  else{
    # Return the group list if it exists
    return $maillist
  }
}
#EndRegion '.\Public\Get-GraphMail.ps1' 64
#Region '.\Public\Get-GraphMailAttachment.ps1' 0
function Get-GraphMailAttachment{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$mailbox,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$messageid
  )
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get Graph Header
  $headers = Get-GraphHeader 
  $endpoint = "users/$($mailbox)/messages/$($messageid)/attachments"
  $results = Get-GraphAPI -endpoint $endpoint -headers $headers -beta -Verbose:$VerbosePreference
  return $results.results.value
}
#EndRegion '.\Public\Get-GraphMailAttachment.ps1' 17
#Region '.\Public\Get-GraphMailAttachmentContent.ps1' 0
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
#EndRegion '.\Public\Get-GraphMailAttachmentContent.ps1' 15
#Region '.\Public\Get-GraphMailFolder.ps1' 0
function Get-GraphMailFolder {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$mailbox,
    [Parameter()][ValidateNotNullOrEmpty()][string]$foldername,
    [Parameter()][switch]$includeHiddenFolders,
    [Parameter()][switch]$all
  )
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "users/$($mailbox)/mailFolders"
  $uriparts = [System.Collections.Generic.List[PSCustomObject]]@()
  if ($PSBoundParameters.ContainsKey("foldername")) { $uriparts.add("`$filter=displayName eq '$($foldername)'") }
  if ($PSBoundParameters.ContainsKey("includeHiddenFolders")) { $uriparts.add("includeHiddenFolders=true") }
  # Generate the final API endppoint URI
  $endpoint = "$($endpoint)?$($uriparts -join "&")"  
  try {
    # Create empty list
    $mailfolders = [System.Collections.Generic.List[PSCustomObject]]@()    
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -headers $headers -beta -Verbose:$VerbosePreference
      # Add results to a list variable
      foreach ($item in $results.results.value) {
        $mailfolders.Add($item) | Out-Null
      }
      Write-Verbose "Returned $($results.results.value.Count) results. Current result set is $($mailfolders.Count) items." 
      if ($results.results."@odata.nextLink") {
        $uri = [REGEX]::Match($results.results."@odata.nextLink", "users.*").Value
      }
    }while ($null -ne $results.results."@odata.nextLink" -and $all.IsPresent)
  }
  catch {
    throw "Unable to get users. $($_.Exception.Message)"
  } 
  return $mailfolders
}
#EndRegion '.\Public\Get-GraphMailFolder.ps1' 43
#Region '.\Public\Get-GraphMailRules.ps1' 0
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
#EndRegion '.\Public\Get-GraphMailRules.ps1' 22
#Region '.\Public\Get-GraphManagedDevice.ps1' 0
<#
  .DESCRIPTION
  This cmdlet is designed to get managed devices (intune) from the graph endpoints
#>
function Get-GraphManagedDevice{
  [CmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][datetime]$lastSyncBefore,
    [Parameter()][ValidateNotNullOrEmpty()][datetime]$lastSyncAfter,
    [Parameter()][ValidateNotNullOrEmpty()][ValidateSet("Windows","Android","macOS","iOS")][string]$operatingSystem,
    [Parameter()][ValidateNotNullOrEmpty()][ValidateSet("compliant","noncompliant","unknown")][string]$complianceState,
    [Parameter()][ValidateNotNullOrEmpty()][string]$OSVersion,
    [Parameter()][ValidateNotNullOrEmpty()][string]$OSVersionStartsWith,
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string]$azureADDeviceId,
    [Parameter()][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$model,
    [Parameter()][ValidateNotNullOrEmpty()][string]$manufacturer,
    [Parameter()][ValidateNotNullOrEmpty()][string]$serialNumber,
    [Parameter()][ValidateNotNullOrEmpty()][ValidateSet("disabled","enabled")][string]$lostModeState,
    [Parameter()][ValidateNotNullOrEmpty()][string]$minimumOSVersion,
    [Parameter()][ValidateNotNullOrEmpty()][string]$maximumOSVersion,
    [Parameter()][ValidateNotNullOrEmpty()][bool]$isEncrypted,
    [Parameter()][ValidateNotNullOrEmpty()][string]$fields,
    [Parameter()][switch]$batch
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }   
  # Create Filters for the URI
  # Create empty list
  $filters =  [System.Collections.Generic.List[PSCustomObject]]@()  
  # Build Filters
  if($lastSyncBefore){
    $filters.Add("lastSyncDateTime le $($lastSyncBefore.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))") | Out-Null
  }
  if($lastSyncAfter){
    $filters.Add("lastSyncDateTime ge $($lastSyncAfter.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))") | Out-Null
  }  
  if($operatingSystem){
    $filters.Add("operatingSystem eq '$($operatingSystem)'") | Out-Null
  }   
  if($complianceState){
    $filters.Add("complianceState eq '$($complianceState)'") | Out-Null
  }     
  if($OSVersion){
    $filters.Add("OSVersion eq '$($OSVersion)'") | Out-Null
  }    
  if($OSVersionStartsWith){
    $filters.Add("startsWith(OSVersion,'$($OSVersionStartsWith)')") | Out-Null
  }  
  if($azureADDeviceId){
    $filters.Add("azureADDeviceId eq '$($azureADDeviceId)'") | Out-Null
  }   
  if($userPrincipalName){
    $filters.Add("userPrincipalName eq '$($userPrincipalName)'") | Out-Null
  } 
  if($model){
    $filters.Add("model eq '$($model)'") | Out-Null
  }          
  if($manufacturer){
    $filters.Add("manufacturer eq '$($manufacturer)'") | Out-Null
  }    
  if($serialNumber){
    $filters.Add("serialNumber eq '$($serialNumber)'") | Out-Null
  }   
  # Create query string for the filter
  $filterList = $filters -join " and "
  # URI Endpoint
  $endpoint = "deviceManagement/managedDevices"
  if($id){
    $uri = "$($endpoint)/$($id)"
  } 
  else{
    $uri = "$($endpoint)"    
  }  
  if($filterList){
    $uri = "$($uri)?`$filter=$($filterList)"
  }
  if(!$batch){
    if($fields -ne ""){
      if($filters.count -gt 0){
        $uri = "$($uri)&`$select=$($fields)"
      }
      else{
        $uri = "$($uri)?`$select=$($fields)"
      }
    }
  }
  else{
    if($fields -ne ""){
      if($filters.count -gt 0){
        $uri = "$($uri)&`$select=id"
      }
      else{
        $uri = "$($uri)?`$select=id"
      }    
    }
  }
  # Create empty list
  $deviceList =  [System.Collections.Generic.List[PSCustomObject]]@()  
  # Create empty list
  $idlist =  [System.Collections.Generic.List[PSCustomObject]]@()    
  # Get Graph Headers for Call
  $headers = Get-GraphHeader  
  try{
    $uri = "https://graph.microsoft.com/beta/$($uri)"
    do{
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      if($results.value){
        foreach($item in $results.value){
          if(!$batch){$deviceList.Add($item) | Out-Null}
          else{$idlist.Add($item) | Out-Null}
        }
      }
      else{
        if(!$batch){$deviceList.Add($item) | Out-Null}
        else{$idlist.Add($item) | Out-Nul}
      }
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
  }
  catch{
    throw "Unable to get devices. $($_.Exception.Message)"
  }
  if(!$batch)
  {
    return $deviceList
  }
  $objid = 1
  $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
  $batches = [System.Collections.Generic.List[PSCustomObject]]@()
  foreach($device in $idlist){
    if($objid -lt 21){
      $url = "deviceManagement/managedDevices/$($device.id)"
      if($fields -ne ""){
        $url = "$($url)?`$select=$($fields)"
      }
      $obj = [PSCustomObject]@{
        "id" = $objid
        "method" = "GET"
        "url" = $url
      }
      $batchObj.Add($obj) | Out-Null
      $objid++
    }
    if($objId -eq 21){
      $batches.Add($batchObj) | Out-Null
      $batchObj = $null
      $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
      $objid = 1 
    }
  }  
  $batches.Add($batchObj) | Out-Null
  for($x = 0; $x -lt $batches.count; $x++){
    if($batches[$x].count -gt 0){
      $json = [PSCustomObject]@{
        "requests" = $batches[$x] 
      } | ConvertTo-JSON    
      $results = Invoke-RestMethod -Method "POST" -Uri "https://graph.microsoft.com/beta/`$batch" -Headers $headers -Body $json
      foreach($item in $results.responses.body){
        $deviceList.Add($item) | Out-Null
      }   
    } 
  }
  return $deviceList
}
#EndRegion '.\Public\Get-GraphManagedDevice.ps1' 168
#Region '.\Public\Get-GraphSignInAuditLogs.ps1' 0
<#
  .DESCRIPTION
  This cmdlet is designed to query the sign in logs for the users in the entra id tenant
  .PARAMETER userDisplayName
  The list of user display names that we should be looking for
  .PARAMETER userPrincipalName
  The list of user principal names that we should be looking for
  .PARAMETER userId
  The lsit of user ids that we should be looking for
  .PARAMETER appDisplayName
  The name of the application that we attempted to sign into
  .PARAMETER ipAddress
  The list of ipaddresses that we should be looking for
  .PARAMETER afterDateTime
  Sign ins after this date
#>
function Get-GraphSignInAuditLogs{
  [CmdletBinding()]
  param(
    [Parameter()][string[]]$userDisplayName,
    [Parameter()][string[]]$userPrincipalName,
    [Parameter()][string[]]$userId,
    [Parameter()][string[]]$appDisplayName,
    [Parameter()][string[]]$ipAddress,
    [Parameter()][datetime]$afterDateTime
  )
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # URI Endpoint
  $endpoint = "auditLogs/signIns"
  $uriparts = [System.Collections.Generic.List[PSCustomObject]]@()
  if ($PSBoundParameters.ContainsKey("userDisplayName")) {
    $list =  [System.Collections.Generic.List[String]]@()
    foreach($item in $userDisplayName){
      $list.Add("userDisplayName eq '$($item)'") | Out-Null
    }
    $uriparts.Add("($($list -join " or "))") | Out-Null    
  }
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) {
    $list =  [System.Collections.Generic.List[String]]@()
    foreach($item in $userPrincipalName){
      $list.Add("userPrincipalName eq '$($item)'") | Out-Null
    }
    $uriparts.Add("($($list -join " or "))") | Out-Null
  }  
  if ($PSBoundParameters.ContainsKey("userId")) {
    $list =  [System.Collections.Generic.List[String]]@()
    foreach($item in $userId){
      $list.Add("userId eq '$($item)'") | Out-Null
    }
    $uriparts.Add("($($list -join " or "))") | Out-Null
  }  
  if ($PSBoundParameters.ContainsKey("ipAddress")) {
    $list =  [System.Collections.Generic.List[String]]@()
    foreach($item in $ipAddress){
      $list.Add("ipAddress eq '$($item)'") | Out-Null
    }
    $uriparts.Add("($($list -join " or "))") | Out-Null
  }   
  if ($PSBoundParameters.ContainsKey("afterDateTime")) {
    $uriparts.Add("createdDateTime ge $($afterDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))") | Out-Null
  }  
  # Generate the final API endppoint URI
  $endpoint = "$($endpoint)?`$filter=$($uriparts -join " and ")"
  # Get Graph Headers for Call
  $headers = Get-GraphHeader 
  try {
    $signinList =  [System.Collections.Generic.List[PSCustomObject]]@()
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -headers $headers -beta -Verbose:$VerbosePreference
      # Add results to a list variable
      foreach ($item in $results.results.value) {
        $signinList.Add($item) | Out-Null
      }
      Write-Verbose "Returned $($results.results.value.Count) results. Current result set is $($signinList.Count) items." 
      if ($results.results."@odata.nextLink") {
        $uri = [REGEX]::Match($results.results."@odata.nextLink", "auditLogs/signIns.*").Value
      }
    }while ($null -ne $results.results."@odata.nextLink")     
  }
  catch {
    throw $_
  } 
  return $signinList
}
#EndRegion '.\Public\Get-GraphSignInAuditLogs.ps1' 90
#Region '.\Public\Get-GraphUser.ps1' 0
function Get-GraphUser {
  [CmdletBinding(DefaultParameterSetName = "All")]
  [OutputType([System.Collections.Generic.List[PSCustomObject]])]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = 'userPrincipalName')][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Parameter(Mandatory = $true, ParameterSetName = 'userid')][ValidateNotNullOrEmpty()][string]$userid,
    [Parameter()][switch]$All,
    [Parameter()][switch]$ConsistencyLevel,
    [Parameter()][switch]$Count,
    [Parameter()][ValidateNotNullOrEmpty()][string]$filter,
    [Parameter()][ValidateNotNullOrEmpty()][string]$select
  )  
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }
  # Build the headers we will use to get groups
  $ConsistencyLevelHeader = @{}
  if ($PSBoundParameters.ContainsKey("ConsistencyLevel")) {
    $ConsistencyLevelHeader.Add("ConsistencyLevel", $true) | Out-Null
  }
  $headers = Get-GraphHeader @ConsistencyLevelHeader
  # Create empty list
  $userList = [System.Collections.Generic.List[PSCustomObject]]@()
  # Base URI for resource call
  $endpoint = "users"
  $uriparts = [System.Collections.Generic.List[PSCustomObject]]@()
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) {
    # Filter based on group name is required
    $endpoint = "$($endpoint)/$($userPrincipalName)"    
  }
  elseif ($PSBoundParameters.ContainsKey("userid")) {
    $endpoint = "$($endpoint)/$($userid)"
  }
  if ($PSBoundParameters.ContainsKey("filter")) { $uriparts.add("`$filter=$($filter)") }
  if ($PSBoundParameters.ContainsKey("select")) { $uriparts.add("`$select=$($select)") }
  if ($PSBoundParameters.ContainsKey("count")) { $uriparts.add("`$count=true") }
  # Generate the final API endppoint URI
  $endpoint = "$($endpoint)?$($uriparts -join "&")"
  try {
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -headers $headers -beta -Verbose:$VerbosePreference
      # Add results to a list variable
      foreach ($item in $results.results.value) {
        $userList.Add($item) | Out-Null
      }
      Write-Verbose "Returned $($results.results.value.Count) results. Current result set is $($userList.Count) items." 
      if ($results.results."@odata.nextLink") {
        $uri = [REGEX]::Match($results.results."@odata.nextLink", "users.*").Value
      }
    }while ($null -ne $results.results."@odata.nextLink" -and $all.IsPresent)
  }
  catch {
    throw "Unable to get users. $($_.Exception.Message)"
  } 
  # If there is only one result, return that
  if ($userList.count -eq 0) {
    return $results.Results
  }
  else {
    # Return the group list if it exists
    return $userList
  }
}
#EndRegion '.\Public\Get-GraphUser.ps1' 67
#Region '.\Public\Get-GraphUserGroups.ps1' 0

function Get-GraphUserGroups {
  [CmdletBinding()]
  [OutputType([System.Collections.Generic.List[PSObject]])]
  param(
    [Alias("userPrincipalName")][Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$userid,
    [Parameter(Mandatory = $true, ParameterSetName = 'directMembership')][switch]$directMembership,
    [Parameter(Mandatory = $true, ParameterSetName = 'transitiveMemberOf')][switch]$transitiveMemberOf
  )
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Build the endpoint
  $endpoint = "users/$($userid)"
  if ($PSBoundParameters.ContainsKey("directMembership")) {
    $endpoint = "$($endpoint)/memberOf"
  } 
  elseif ($PSBoundParameters.ContainsKey("transitiveMemberOf")) {  
    $endpoint = "$($endpoint)/transitiveMemberOf"
  }
  # Build the headers we will use to get groups
  $headers = Get-GraphHeader  
  # Create empty list
  $groupList = [System.Collections.Generic.List[PSCustomObject]]@()
  try {
    $uri = $endpoint
    do {
      # Execute call against graph
      $results = Get-GraphAPI -endpoint $uri -headers $headers -beta -Verbose:$VerbosePreference
      # Add results to a list variable
      foreach ($item in $results.results.value) {
        $groupList.Add($item) | Out-Null
      }
      Write-Verbose "Returned $($results.results.value.Count) results. Current result set is $($groupList.Count) items." 
      if ($results.results."@odata.nextLink") {
        $uri = [REGEX]::Match($results.results."@odata.nextLink", "users.*").Value
      }
    }while ($null -ne $results.results."@odata.nextLink")     
  }
  catch {
    throw $_
  }    
  return $groupList
}
#EndRegion '.\Public\Get-GraphUserGroups.ps1' 46
#Region '.\Public\Move-GraphMail.ps1' 0
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
#EndRegion '.\Public\Move-GraphMail.ps1' 36
#Region '.\Public\New-GraphGroup.ps1' 0
<#
  .DESCRIPTION
  This cmdlet is designed to create a new Entra ID group via graph
  .PARAMETER displayName
  The display name of the group
  .PARAMETER mailEnabled
  If the group should be mail enabled, default false
  .PARAMETER mailNickname
  What the mailnickname will be, required even if mailenabled is false
  .PARAMETER description
  The description for the group
  .PARAMETER securityEnabled
  If the group should be security enabled, default true   
#>
function New-GraphGroup{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$displayName,
    [Parameter()][bool]$mailEnabled = $false,
    [Parameter(Mandatory = $true)][string]$mailNickname,
    [Parameter()][string]$description,
    [Parameter()][bool]$securityEnabled = $true
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Build the headers we will use to get groups
  $headers = Get-GraphHeader  
  # Variables
  $body = $PsBoundParameters | ConvertTo-Json  
  # Base URI for resource call
  $uri = "https://graph.microsoft.com/beta/groups"
  try{
    # Execute call against graph
    $results = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -StatusCodeVariable statusCode    
    return $results
  }
  catch{
    throw "Unable to create group. $($_.Exception.Message)"
  }
  
}
#EndRegion '.\Public\New-GraphGroup.ps1' 44
#Region '.\Public\Remove-GraphDevice.ps1' 0
function Remove-GraphDevice{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$id
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get Graph Headers for Call
  $headers = Get-GraphHeader  
  # URI Endpoint
  $endpoint = "devices/$($id)"
  try{
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    Invoke-RestMethod -Method Delete $uri -Headers $headers -StatusCodeVariable statusCode  #| Out-Null
  }
  catch{
    throw "Unable to delete devices. $($_.Exception.Message)"
  }   
}
#EndRegion '.\Public\Remove-GraphDevice.ps1' 21
#Region '.\Public\Remove-GraphGroupMember.ps1' 0
function Remove-GraphGroupMember{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$groupId,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$ids
  )
  # Confirm we have a valid graph token
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # Get Graph Headers for Call
  $headers = Get-GraphHeader 
  try{
    $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
    $batches = [System.Collections.Generic.List[PSCustomObject]]@()
    for($i = 1; $i -le $ids.Count; ++$i){
      $obj = [PSCustomObject]@{
        "id" = $i
        "method" = "DELETE"
        "url" = "/groups/$($groupId)/members/$($ids[$i-1])/`$ref"
      }      
      $batchObj.Add($obj) | Out-Null        
      if($($i % 20) -eq 0){
        $batches.Add($batchObj) | Out-Null
        $batchObj = $null
        $batchObj = [System.Collections.Generic.List[PSCustomObject]]@()
      }      
    }
    $batches.Add($batchObj) | Out-Null
    foreach($batch in $batches){
      $json = [PSCustomObject]@{
        "requests" = $batch
      } | ConvertTo-JSON -Depth 5
      $results = Invoke-RestMethod -Method "POST" -Uri "https://graph.microsoft.com/beta/`$batch" -Headers $headers -Body $json
    }
  }
  catch{
    throw "Unable to remove members. $($_.Exception.Message)"
  }      
}
#EndRegion '.\Public\Remove-GraphGroupMember.ps1' 41
#Region '.\Public\Remove-GraphIntuneApp.ps1' 0
function Remove-GraphIntuneApp{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$applicationid
  )
  # Invoke graph API to remove the application
  $endpoint = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($applicationid)"
  $headers = Get-GraphHeader
  Invoke-RestMethod -Method Delete -Uri $endpoint -Headers $headers -StatusCodeVariable statusCode | Out-Null
}
#EndRegion '.\Public\Remove-GraphIntuneApp.ps1' 11
#Region '.\Public\Remove-GraphIntuneDevicePrimaryUser.ps1' 0
function Remove-GraphIntuneDevicePrimaryUser{
  [CmdletBinding()]
  param(
    [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$deviceId
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }   
  $endpoint = "deviceManagement/managedDevices/$($deviceId)/users/`$ref"
  $headers = Get-GraphHeader
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  Invoke-RestMethod -method "DELETE" -Uri $uri -Headers $headers -StatusCodeVariable "statusCode"  
}
#EndRegion '.\Public\Remove-GraphIntuneDevicePrimaryUser.ps1' 14
#Region '.\Public\Remove-GraphMailRule.ps1' 0
function Remove-GraphMailRule{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = 'userPrincipalName')][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Alias("id")][Parameter(Mandatory = $true, ParameterSetName = 'userid')][ValidateNotNullOrEmpty()][string]$userid,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ruleid
  )  
  # Confirm we have a valid graph token
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) { 
    $endpoint = "https://graph.microsoft.com/beta/users/$($userPrincipalName)/mailFolders/inbox/messageRules/$($ruleid)"
  }
  if ($PSBoundParameters.ContainsKey("userid")) { 
    $endpoint = "https://graph.microsoft.com/beta/users/$($userid)/mailFolders/inbox/messageRules/$($ruleid)"
  }
  $headers = Get-GraphHeader
  Invoke-RestMethod -Method Delete -Uri $endpoint -Headers $headers -StatusCodeVariable statusCode | Out-Null
}
#EndRegion '.\Public\Remove-GraphMailRule.ps1' 21
#Region '.\Public\Remove-GraphManagedDevice.ps1' 0
function Remove-GraphManagedDevice{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$id
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get Graph Headers for Call
  $headers = Get-GraphHeader  
  # URI Endpoint
  $endpoint = "deviceManagement/managedDevices/$($id)"
  try{
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers -StatusCodeVariable statusCode | Out-Null
  }
  catch{
    throw "Unable to delete devices. $($_.Exception.Message)"
  }   
}
#EndRegion '.\Public\Remove-GraphManagedDevice.ps1' 21
#Region '.\Public\Send-GraphMailMessage.ps1' 0
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
#EndRegion '.\Public\Send-GraphMailMessage.ps1' 70
#Region '.\Public\Set-GraphAutopilotInformation.ps1' 0
function Set-GraphAutopilotInformation {
  param (
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$deviceId,
    [Parameter()][ValidateNotNullOrEmpty()][string]$userPrincipalName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$groupTag,
    [Parameter()][ValidateNotNullOrEmpty()][string]$deviceName
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }   
  $endpoint = "deviceManagement/windowsAutopilotDeviceIdentities/$($deviceId)/UpdateDeviceProperties"
  $headers = Get-GraphHeader
  # Create the body
  $body = @{}
  $clear = @{}
  if ($PSBoundParameters.ContainsKey("userPrincipalName")) {
    $body.Add("userPrincipalName",$userPrincipalName) | Out-Null
  }
  if ($PSBoundParameters.ContainsKey("groupTag")) {
    $body.Add("groupTag",$groupTag) | Out-Null
    $clear.Add("groupTag","") | Out-Null
  }
  if ($PSBoundParameters.ContainsKey("displayName")) {
    $body.Add("displayName",$displayName) | Out-Null
  }
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  if($clear.count -gt 0){
    Invoke-RestMethod -Method "POST" -URI $uri -Headers $headers -Body ($clear | ConvertTo-Json) -StatusCodeVariable "statusCode"
    Start-Sleep -Seconds 5
    Invoke-RestMethod -Headers $headers -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotSettings/sync" -Method "POST"  
  }  
  if($body.count -gt 0){
    Invoke-RestMethod -Method "POST" -URI $uri -Headers $headers -Body ($body | ConvertTo-Json) -StatusCodeVariable "statusCode"
    Start-Sleep -Seconds 5
  }   
}
#EndRegion '.\Public\Set-GraphAutopilotInformation.ps1' 37
#Region '.\Public\Set-GraphIntuneDevicePrimaryUser.ps1' 0
function Set-GraphIntuneDevicePrimaryUser{
  param(
    [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$deviceId,
    [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$userId
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  $endpoint = "deviceManagement/managedDevices/$($deviceId)/users/`$ref"
  $headers = Get-GraphHeader
  $Body = @{
    "@odata.id" = "https://graph.microsoft.com/beta/users/$($userId)"
  }
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  Invoke-RestMethod -method "POST" -Uri $uri -Headers $headers -body ($body | ConvertTo-JSON) -StatusCodeVariable "statusCode"
}
#EndRegion '.\Public\Set-GraphIntuneDevicePrimaryUser.ps1' 17
#Region '.\Public\Set-GraphMailRead.ps1' 0
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
#EndRegion '.\Public\Set-GraphMailRead.ps1' 34
#Region '.\Public\Test-GraphAcessToken.ps1' 0
<#
  .DESCRIPTION
  This cmdlet is tests to see if the passed variable is not null, and expires in less than 10 minutes
  .PARAMETER token
  The current access tokenb variable
#>
function Test-GraphAcessToken{
  [CmdletBinding()]
  param(
    [Parameter()][System.Object]$token
  )
  if(!$token){
    return $false
  }
  $expiryTime = $token.ExpiresOn - (Get-Date)
  if($expiryTime.Minutes -lt 10){
    return $false
  }
  else{
    return $true
  }
}
#EndRegion '.\Public\Test-GraphAcessToken.ps1' 23
#Region '.\Public\Test-GraphIntuneAPNCertificate.ps1' 0
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
#EndRegion '.\Public\Test-GraphIntuneAPNCertificate.ps1' 65
#Region '.\Public\Test-GraphIntuneDEPCertificate.ps1' 0
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
#EndRegion '.\Public\Test-GraphIntuneDEPCertificate.ps1' 69
#Region '.\Public\Test-GraphIntuneLicense.ps1' 0
function Test-GraphIntuneLicense{
  [CmdletBinding()]
  param(
    [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$userId
  )
  if (!$(Test-GraphAcessToken $script:graphAccessToken)) {
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }   
  $endpoint = "deviceAppManagement/managedAppStatuses('userstatus')?userId=$($userId)"
  $headers = Get-GraphHeader
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  $result = Invoke-RestMethod -Method "GET" -URI $uri -Headers $headers -StatusCodeVariable "statusCode"
  $license = $result.content.validationStatuses | Where-Object { $_.validationName -eq 'Intune License' }
  if($license.State -eq 'Pass'){
    return $true
  }
  else{
    return $false
  }
}
#EndRegion '.\Public\Test-GraphIntuneLicense.ps1' 21
#Region '.\Public\Test-GraphIntuneVPPCertificate.ps1' 0
function Test-GraphIntuneVPPCertificate{
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
  # Get VPP Tokens
  $VPPTokens = Get-GraphIntuneVPPCertificate
  foreach($VPP in $VPPTokens){
    # Check if the token is current valid
    if ($VPP.state -ne 'valid') {
      $obj = [ordered]@{
        "Status" = "Apple VPP Token is not valid, new token required"
        "appleid" = $VPP.appleId
        "expiry" = $VPP.expirationDateTime.ToShortDateString()
        "displayname" = $VPP.displayName
      }
      $alerts.add($obj) | Out-Null
    }
    else{
      $VPPTokenDaysLeft = ($VPP.expirationDateTime - (Get-Date))
      if ($VPPTokenDaysLeft.Days -le $days) {
        $obj = [ordered]@{
          "Status" = "Apple VPP Token expires in $($VPPTokenDaysLeft.Days) days"
          "appleid" = $VPP.appleId
          "expiry" = $VPP.expirationDateTime.ToShortDateString()
          "displayname" = $VPP.displayName
        }
        $alerts.add($obj) | Out-Null        
      }
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
                            "Connector:"    = "Apple VPP Token"
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
        <strong>Connector:</strong> Apple VPP Token<br/>
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
#EndRegion '.\Public\Test-GraphIntuneVPPCertificate.ps1' 81
