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