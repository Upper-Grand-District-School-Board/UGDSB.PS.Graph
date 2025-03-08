param(
  [version]$global:Version = "0.1.0"
)
#Requires -Module ModuleBuilder
$privateFolder = Join-Path -Path $PSScriptRoot -ChildPath Source  -AdditionalChildPath "Private"
$publicFolder = Join-Path -Path $PSScriptRoot -ChildPath Source -AdditionalChildPath "Public"
$dllFolder = Join-Path -Path $PSScriptRoot -ChildPath Source -AdditionalChildPath "Assemblies"
# Remove Folders if Exist
Remove-Item -Path $privateFolder -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $publicFolder -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
# Create Folders
New-Item -Path $privateFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
New-Item -Path $publicFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
# Parent Folder
$parentFolder = (get-item $PSScriptRoot).Parent
# Sub Folders without build and Module
$folders = Get-ChildItem -Path $parentFolder -Directory | Where-Object {$_.Name -in ('cmdlets')}
# Copy PS1 files
foreach($folder in $folders){
  $files = Get-ChildItem -Path $folder -Recurse -Filter "*.ps1"
  foreach($file in $files){
    Copy-Item -Path $file -Destination $publicFolder
  }
}
# Output Directory
$moduleDir = Join-Path -Path $parentFolder -ChildPath Module
$params = @{
  SourcePath = "$PSScriptRoot\Source\UGDSB.PS.Graph.psd1"
  Version = $global:Version
  CopyPaths = @("$PSScriptRoot\Source\UGDSB.PS.Graph.nuspec")
  OutputDirectory = $moduleDir 
  UnversionedOutputDirectory = $true
}
Build-Module @params
$dlls = Get-ChildItem -Path $dllFolder -Filter "*.dll"
$dlldir = Join-Path -Path $moduleDir -ChildPath "UGDSB.PS.Graph"
foreach($file in $dlls){
  Copy-Item -Path $file -Destination $dlldir -force
}  
#$path = (Get-Module -ListAvailable "UGDSB.PS.Graph" | Where-Object {$_.Path -like "*$($global:Version)*"}).path
#if($path){
#  $directory = (Get-Item $Path).DirectoryName
#  $copyFrom = $moduleDir
#  $filesToCopy = Get-ChildItem -Path $copyFrom -recurse -Filter "*PS.Graph.ps*"
#  $filesToCopy | Copy-Item -Destination $directory -Force
#}