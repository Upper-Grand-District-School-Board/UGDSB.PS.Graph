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
      $vars.add("body", ($body | ConvertTo-JSON -Depth 10))
    }
    Write-Verbose "Calling API endpoint: $($uri)" 
    $results = Invoke-RestMethod @Vars
  }
  catch {
    $ErrorMsg = $global:Error[0]
    return $ErrorMsg
  }
  return [PSCustomObject]@{
    StatusCode = $statusCode
    Results    = $results
  } 
}