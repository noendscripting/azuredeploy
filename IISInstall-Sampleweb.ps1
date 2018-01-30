<#
 	.DISCLAIMER
    This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
    THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
    We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object
    code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software
    product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the
    Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims
    or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
    Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained
    within the Premier Customer Services Description.
#>

$MyData = 
@{
    AllNodes = @(
    
    @{
            NodeName= "localhost"
	        RetryCount = 20  
            RetryIntervalSec = 30  
            PSDscAllowPlainTextPassword=$true
			PSDscAllowDomainUser = $true
            DiskNumber = 2
            DriveLetter = "F"
         }
    
    )
 }


Configuration IISInstall 
{
    param (
         [PSCredential]$DriveCredentials,
         [string]$NodeName = 'localhost',
         [string]$SourcePath,
         [string]$DestinationPath

  
  )
$PlainPassword = "1hfxLwbLsT4PbE4JztmeLOm+4I6eEmPMUnlgB0x4tHTN6qMQ4Hdb56oNLZuKIhOnm+uf8lbDMBXl7QdxtSPj/Q=="
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force 
$UserName = "AZURE\101filepoc"
$DriveCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
Import-DscResource -ModuleName PSDesiredStateConfiguration,xWebAdministration,xStorage,xTimeZone
Node $NodeName
{  
    LocalConfigurationManager
	{
		ConfigurationMode = 'ApplyAndAutoCorrect'
		RebootNodeIfNeeded = $true
		ActionAfterReboot = 'ContinueConfiguration'
		AllowModuleOverwrite = $true
	}
    xTimeZone TimeZoneExample

    {
		isSingleInstance = 'Yes'
        TimeZone = 'Eastern Standard Time'
    }
   
    WindowsFeature WebWindowsAuth  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Windows-Auth'  
    }

    WindowsFeature IIS  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Server'  
    }  

    WindowsFeature WebWebServer  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-WebServer'  
    }  

	WindowsFeature WebAppDev  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-App-Dev'  
		
    } 	

	WindowsFeature WebNetExt  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Net-Ext'  
    } 

	WindowsFeature WebNetExt45  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Net-Ext45'  
    } 

    WindowsFeature AspNet45  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Asp-Net45'  
    } 

    WindowsFeature Net3.5  
    {  
        Ensure          = 'Present'  
        Name            = 'NET-Framework-Core'  
    }
	
	 
    WindowsFeature CustomLogging  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Custom-Logging'  
    }

    WindowsFeature WebDirBrowsing  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Dir-Browsing'  
    }


    WindowsFeature WebHttpErrors  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Http-Errors'  
    }

    WindowsFeature WebHttpLogging  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Http-Logging'  
    }

    WindowsFeature WebStaticContent  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Static-Content'  
    }

    WindowsFeature WebStatCompression  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Stat-Compression'  
    }

    WindowsFeature WebPerformance  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Performance'  
    }

    WindowsFeature WebISAPIExt  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-ISAPI-Ext'  
    }
    
	WindowsFeature WebISAPIFilter   
    {  
        Ensure          = 'Present'  
        Name            = 'Web-ISAPI-Filter'  
    }

    WindowsFeature ApplicationServer  
    {  
        Ensure          = 'Present'  
        Name            = 'Application-Server'  
    }

	WindowsFeature NETFramework45ASPNET  
    {  
        Ensure          = 'Present'  
        Name            = 'NET-Framework-45-ASPNET'  
    }

	WindowsFeature WindowsIdentityFoundation
    {  
        Ensure          = 'Present'  
        Name            = 'Windows-Identity-Foundation'  
    }
	
    WindowsFeature AspNet3.5  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Asp-Net'  
    }
	
	WindowsFeature WebMgmtConsole  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Mgmt-Console'  
    }
	
	WindowsFeature WebMgmtCompat  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Mgmt-Compat'  
    }
	
	WindowsFeature WebMetabase  
    {  
        Ensure          = 'Present'  
        Name            = 'Web-Metabase'  
    }
    xWaitForDisk Wait_Data_Disk
	{
		DiskNumber = 2
		RetryCount = 3
		RetryIntervalSec = 30
	}

		xDisk Data_Disk
	{
		DiskNumber = $allNodes.DiskNumber
		DriveLetter = $AllNodes.DriveLetter
		AllocationUnitSize = 4096
		DependsOn = '[xWaitforDisk]Wait_Data_Disk'
	}
    File WebContent
    {   #copy websource files
        DestinationPath = $DestinationPath  
        SourcePath = $SourcePath
        Type =  "Directory"
        Checksum =  "ModifiedDate"
        Credential = $DriveCredentials
        Ensure =  "Present"
        MatchSource = $true 
        Recurse = $true
        DependsOn = "[xWebsite]DefaultWebSite"
    }

    xWebsite SampleWeb
        {
            Ensure          = "Present"
            Name            = "SampleWeb"
            State           = "Started"
            PhysicalPath    = "F:\sampleweb"
            DependsOn       = '[File]WebContent','[xWebsite]DefaultWebSite'
        }
    xWebsite DefaultWebSite
        {
            Ensure          = "Absent"
            Name            = "Default Web Site"
            State           = "Stopped"
            DependsOn       = "[xDisk]Data_Disk" 
        }

  
  }





 }
    
  


IISInstall -Nodename "localhost" -ConfigurationData $MyData -SourcePath \\101filepoc.file.core.windows.net\source\sampleweb -DestinationPath F:\sampleweb