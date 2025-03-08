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