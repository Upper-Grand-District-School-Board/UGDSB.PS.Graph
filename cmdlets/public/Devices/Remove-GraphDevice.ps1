function Remove-GraphDevice{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$id
  )
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get Graph Headers for Call
  $headers = Get-GraphHeader  
  # URI Endpoint
  $endpoint = "devices/$($id)"
  try{
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    Invoke-RestMethod -Method Delete $uri -Headers $headers -StatusCodeVariable statusCode  #| Out-Null
  }
  catch{
    throw "Unable to delete devices. $($_.Exception.Message)"
  }   
}