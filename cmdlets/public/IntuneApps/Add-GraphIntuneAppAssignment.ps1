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