function New-GraphApplicationDirectoryExtension{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$objectId,
    [Parameter(Mandatory = $true)][validateSet("Binary","Boolean","DateTime","Integer","LargeInteger","String")][string]$dataType,
    [Parameter(Mandatory = $true)][validatenotnullorempty()][string]$name,
    [Parameter()][switch]$isMultiValued,
    [Parameter(Mandatory = $true)][validateSet("User","Group","AdministrativeUnit","Application","Device","Organization")][string[]]$targetObjects
  )   
  if(!$(Test-GraphAcessToken $script:graphAccessToken)){
    throw "Please Call Get-GraphAccessToken before calling this cmdlet"
  }  
  # Get Graph Header
  $headers = Get-GraphHeader  
  $endpoint = "applications/$($objectId)/extensionProperties"
  # Set body for request
  $body = [PSCustomObject]@{
    name = $name
    dataType = $dataType
    isMultiValued = $isMultiValued.IsPresent
    targetObjects = $targetObjects
  }
  # Call API Endpoint to create application
  try {
    $results = Get-GraphAPI -endpoint $endpoint -Method Post -headers $headers -body $body -beta -Verbose:$VerbosePreference
    if($results.StatusCode -ne 201){
      throw "Unable to create extension attribute for appplication. $($results)"
    }
  }
  catch {
    throw $_
  }
  return $results.Results   
}