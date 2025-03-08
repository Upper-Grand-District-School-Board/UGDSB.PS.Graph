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