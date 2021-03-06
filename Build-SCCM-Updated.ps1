﻿$MyData =
@{
    AllNodes = @(

    @{
            NodeName="SCCM2017"
			RetryCount = 20
            RetryIntervalSec = 30
            PSDscAllowPlainTextPassword=$true
			PSDscAllowDomainUser = $true
         }

    )
 }


Configuration Configuration_CM
{

    Param
	(
		[string]$NodeName = 'localhost',
		#[PSCredential]$DriveCredentials,
        #[PSCredential]$DomainCredentials,
		[string]$DataDriveLetter = "F"
       # [string]$SQLSourceFolder  = "C:\SQLCD"

	)
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DsCresource -ModuleName xStorage
    Import-DsCresource -ModuleName SQLServerDSC
    Import-DsCresource -ModuleName StorageDSC
    Import-DsCresource -ModuleName XtimeZone -ModuleVersion 1.7.0.0
    #Import-DscResource -Module PSDscResources -ModuleVersion 2.8.0.0
    Import-DsCresource -ModuleName xWebAdministration
    Import-DsCresource -ModuleName xWindowsUpdate
    Node $nodename {
        LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyAndAutoCorrect'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
        }

        WindowsFeatureSet AddAllFeatures
        {
            Name                    = @("AS-NET-Framework", "NET-Framework-Features","net-framework-45-ASPNET","BITS","RDC","Web-WMI","web-asp-net","web-asp-net45","web-net-ext45","web-Windows-Auth","Web-Dyn-compression","web-Mgmt-console","net-http-activation","net-wcf-http-activation45","UpdateServices-RSAT", "RSAT-Bits-Server")
            Ensure                  = 'Present'
            IncludeAllSubFeature    = $true
        }


        WaitForDisk Wait_Data_Disk
		{
			DiskId = "2"
			RetryCount = 3
			RetryIntervalSec = 30

		}

		Disk Data_Disk
		{
			DiskId = "2"
			DriveLetter = $DataDriveLetter
			AllocationUnitSize = 4096
			DependsOn = '[WaitforDisk]Wait_Data_Disk'
        }

        Package Windows10_ADK
        {
            Ensure = "Present"
            Path = "http://packagesource.contosoad.com/downloads/adk10.exe"
            Name = "Windows Assessment and Deployment Kit - Windows 10"
            Arguments = "/quiet /promptrestart /features optionid.deploymenttools optionid.windowspreinstallationenvironment optionid.userstatemigrationtool"
            ProductId = "39ebb79f-797c-418f-b329-97cfdf92b7ab"
        }
       <# WindowsFeatureSet WSUS_InternalDB
        {
            Name = "UpdateServices-Services,UpdateServices-WidDB,UpdateServices-Services,Windows-Internal-Database,UpdateServices-UI"
            IncludeAllSubFeature = $true
            Ensure = "Present"
        }#>
    }
}



Configuration_CM -Nodename sccm2017.eastus2.cloudapp.azure.com -ConfigurationData $MyData -Outputpath c:\os\temp\testdsc