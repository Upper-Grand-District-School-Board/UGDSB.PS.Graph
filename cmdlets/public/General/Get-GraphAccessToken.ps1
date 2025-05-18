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
  # If Microsoft.Identity.Client.dll is not loaded, load it
  try{
    Add-Type -Path "$($PSScriptRoot)\Microsoft.Identity.Client.dll" -ErrorAction SilentlyContinue | Out-Null
  }
  catch{}
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