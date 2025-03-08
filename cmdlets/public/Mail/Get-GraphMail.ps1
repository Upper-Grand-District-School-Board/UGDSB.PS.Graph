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