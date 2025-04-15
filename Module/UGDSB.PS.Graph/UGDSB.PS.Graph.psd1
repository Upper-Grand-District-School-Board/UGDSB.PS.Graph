#
# Module manifest for module 'Topdesk'
#
# Generated by: Me
#
# Generated on: 7/21/2022
#
@{
  # Script module or binary module file associated with this manifest.
    RootModule = 'UGDSB.PS.Graph.psm1'
    
    # Version number of this module.
    ModuleVersion = '0.1.3'
    
    # Supported PSEditions
    # CompatiblePSEditions = @()
    
    # ID used to uniquely identify this module
    GUID = '77fbcf7c-95f6-4e2c-8cf0-05c4a211839e'
    
    # Author of this module
    Author = 'Jeremy Putman'
    
    # Company or vendor of this module
    CompanyName = 'Upper Grand District School Board'
    
    # Copyright statement for this module
    Copyright = '(c) 2022. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'This bundles together functions related to powershell functions use for UGDSB Graph Automations'
    
    # Minimum version of the Windows PowerShell engine required by this module
    # PowerShellVersion = ''
    
    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''
    
    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    #RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    #FunctionsToExport = @()
    FunctionsToExport = @('Add-GraphGroupMember','Add-GraphIntuneAppAddToESP','Add-GraphIntuneAppAssignment','Copy-GraphIntuneAppAssignments','Disable-GraphUser','Get-GraphAccessPackageAssignments','Get-GraphAccessPackageCatalog','Get-GraphAccessPackages','Get-GraphAccessToken','Get-GraphAPI','Get-GraphApplications','Get-GraphAutopilotInformation','Get-GraphDevice','Get-GraphGroup','Get-GraphGroupMembers','Get-GraphHeader','Get-GraphIntuneAPNCertificate','Get-GraphIntuneApp','Get-GraphIntuneAppAssignment','Get-GraphIntuneDEPCertificate','Get-GraphIntuneEnrollmentStatusPage','Get-GraphIntuneFilters','Get-GraphIntuneVPPCertificate','Get-GraphMail','Get-GraphMailAttachment','Get-GraphMailAttachmentContent','Get-GraphMailFolder','Get-GraphMailRules','Get-GraphManagedDevice','Get-GraphServicePrincipals','Get-GraphSignInAuditLogs','Get-GraphUser','Get-GraphUserGroups','Move-GraphMail','New-GraphGroup','Remove-GraphDevice','Remove-GraphGroupMember','Remove-GraphIntuneApp','Remove-GraphIntuneDevicePrimaryUser','Remove-GraphMailRule','Remove-GraphManagedDevice','Send-GraphMailMessage','Set-GraphAutopilotInformation','Set-GraphIntuneDevicePrimaryUser','Set-GraphMailRead','Test-GraphAcessToken','Test-GraphIntuneAPNCertificate','Test-GraphIntuneDEPCertificate','Test-GraphIntuneLicense','Test-GraphIntuneVPPCertificate')
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = '*'
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()
    
    # DSC resources to export from this module
    # DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # List of all files packaged with this module
    # FileList = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
    
    PSData = @{
    
    # Tags applied to this module. These help with module discovery in online galleries.
    # Tags = @()
    
    # A URL to the license for this module.
    # LicenseUri = ''
    
    # A URL to the main website for this project.
    # ProjectUri = ''
    
    # A URL to an icon representing this module.
    # IconUri = ''
    
    # ReleaseNotes of this module
    # ReleaseNotes = ''
    
    } # End of PSData hashtable
    
    } # End of PrivateData hashtable
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    DefaultCommandPrefix = ''
    
    }
