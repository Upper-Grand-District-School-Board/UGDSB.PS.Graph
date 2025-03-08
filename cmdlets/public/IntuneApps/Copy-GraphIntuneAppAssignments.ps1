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