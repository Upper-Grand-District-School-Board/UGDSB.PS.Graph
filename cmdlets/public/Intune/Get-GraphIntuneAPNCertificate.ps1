function Get-GraphIntuneAPNCertificate{
  [CmdletBinding()]
  param()
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  } 
  # URI Endpoint
  $endpoint = "deviceManagement/applePushNotificationCertificate"
  # Get Graph Headers for Call
  $headers = Get-GraphHeader
  # Invoke Rest API
  $uri = "https://graph.microsoft.com/beta/$($endpoint)"
  $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
  # return results
  return $results
}