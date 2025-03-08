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