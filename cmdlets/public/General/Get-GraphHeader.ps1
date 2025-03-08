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