

$MyData = 
@{
    AllNodes = @(
    
    @{
            NodeName="sql2014sccm.eastus2.cloudapp.azure.com"
			RetryCount = 20  
            RetryIntervalSec = 30  
            PSDscAllowPlainTextPassword=$true
			PSDscAllowDomainUser = $true
         }
    
    )
 }



Configuration ConfigurationSQL
{
    [CmdletBinding()]

	Param
	(
		[string]$NodeName = 'localhost',
		[PSCredential]$DriveCredentials,
        [PSCredential]$DomainCredentials,        
		[string]$DataDriveLetter = "F",		
        [string]$SQLSourceFolder  = "C:\SQLCD"

	)


$PlainPassword = "1hfxLwbLsT4PbE4JztmeLOm+4I6eEmPMUnlgB0x4tHTN6qMQ4Hdb56oNLZuKIhOnm+uf8lbDMBXl7QdxtSPj/Q=="
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force 
$UserName = "101filepoc"
$DriveCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword  


$SQLServerDomainPassword = ConvertTo-SecureString -AsPlainText -Force "P2ssw0rd" 
$SQLServerAccountuser = "Contosoad\cmSQLsvc"
$SQLServerAccountCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SQLServerAccountuser , $SQLServerDomainPassword  

$SQLAgentAccountuser = "Contosoad\cmSQLAgent"
$SQLAgentAccountCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SQLAgentAccountuser , $SQLServerDomainPassword  

$SQLRSAccountuser = "Contosoad\cmRSPacct"
$SQLRSAccountCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SQLRSAccountuser , $SQLServerDomainPassword  



Import-DscResource -ModuleName SQLServerDSC
Import-DscResource -ModuleName StorageDSC
Import-DscResource -Module PSDscResources -ModuleVersion 2.8.0.0
Import-DscResource -ModuleName xTimeZone -ModuleVersion 1.7.0.0
Node $NodeName {
    LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyAndAutoCorrect'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
            AllowModuleOverwrite = $true
            DebugMode = "All"
        }
        
        xTimeZone TimeZoneEastern

        {
			isSingleInstance = 'Yes'
            TimeZone = 'Eastern Standard Time'

        }
        WindowsFeatureSet Framework
        {
            Name                    = @("AS-NET-Framework", "NET-Framework-Features")
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

        File SQL_CD
        {   #copy SQL Iso from Azure Files
            DestinationPath = "F:\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso"
            Checksum =  "ModifiedDate"
            Credential = $DriveCredentials
            Ensure =  "Present"
            DependsOn = "[Disk]Data_Disk"
            SourcePath = "\\101filepoc.file.core.windows.net\iso\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso"
            Type =  "File"
        }
        Script Mount_SQL_CD
        {
            GetScript = {
                $result = $null
                return @{
                    $result = Get-Volume |Where-Object {$_.FileSystemLabel -eq "SQL2014_x64_ENU"}
                }
            }
            SetScript =   {
                $setupDriveLetter = (Mount-DiskImage -ImagePath F:\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso -PassThru | Get-Volume).DriveLetter
                Write-Verbose "Mounted SQL CD with Letter $($setupdriveletter)"
                
            }
            TestScript = {
                $driveletter = $null
                $driveletter = Get-Volume -ErrorAction SilentlyContinue |Where-Object {$_.FileSystemLabel -eq "SQL2014_x64_ENU"}
                if ($driveletter -eq $null )
                {
                    return $false
                }
                else
                {
                    return $true
                }
            }
            DependsOn = '[File]SQL_CD'

        }

        Script Create_Folder_Link
        {
            GetScript = {return @{"result"="useless"}}
            SetScript = {

                $driveletter = (Get-Volume |Where-Object {$_.FileSystemLabel -eq "SQL2014_x64_ENU"}).DriveLetter
                New-Item -ItemType SymbolicLink -Path $using:SQLSourceFolder -Target "$($driveletter):\"
            }
            TestScript = {
                return (test-path $using:SQLSourceFolder)
                
            }
            DependsOn = '[Script]Mount_SQL_CD'
        }
       

        SqlSetup InstallNamedInstance_INST2014
        {

            Action                = 'Install'
            InstanceName          = 'MSSQLSERVER'
            Features              = 'SQLENGINE,FULLTEXT,RS,SSMS,ADV_SSMS'
            SQLCollation          = 'SQL_Latin1_General_CP1_CI_AS'
            SQLSvcAccount         = $SQLServerAccountCredentials
            AgtSvcAccount         = $SQLAgentAccountCredentials
            RSSvcAccount          = $SQLRSAccountCredentials
            SQLSysAdminAccounts   = ".\Administrators"
            InstallSharedDir      = "C:\Program Files\Microsoft SQL Server"
            InstallSharedWOWDir   = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir           = 'C:\Program Files\Microsoft SQL Server'
            InstallSQLDataDir     = "$$DataDriveLetter\Data"
            SQLUserDBDir          = "$($DataDriveLetter)\Data"
            SQLUserDBLogDir       = "$($DataDriveLetter)\Data"
            SQLTempDBDir          = "$($DataDriveLetter)\Data"
            SQLTempDBLogDir       = "$($DataDriveLetter)\Data"
            SQLBackupDir          = "$($DataDriveLetter)\Backup"
            SourcePath            = $SQLSourceFolder
            UpdateEnabled         = 'True'
            UpdateSource          = 'MU'
            ForceReboot           = $false
            BrowserSvcStartupType = 'Automatic'
            #PsDscRunAsCredential  = $SqlInstallCredential
            DependsOn             = '[WindowsFeatureSet]Framework','[Script]Create_Folder_Link'

        
        }

        SqlRS DefaultConfiguration

        {

            InstanceName         = 'MSSQLSERVER'
            DatabaseServerName   = 'localhost'
            DatabaseInstanceName = 'MSSQLSERVER'
            DependsOn = '[SqlSetup]InstallNamedInstance_INST2014'

        }


    SqlServerMemory Set_SQLServerMinAndMaxMemory_ToAuto
        {
            Ensure               = 'Present'
            DynamicAlloc         = $true
            ServerName           = 'sql2014sccm'
            InstanceName         = 'MSSQLSERVER'
            MinMemory            = 8192
            PsDscRunAsCredential = $SqlAdministratorCredential
            DependsOn = '[SqlSetup]InstallNamedInstance_INST2014'
        }

        Group AddADUserToLocalAdminGroup {
            GroupName='Administrators'
            Ensure= 'Present'
            MembersToInclude= "Contosoad\ConfigMgrAdmins"
            Credential = $SQLServerAccountCredentials
            #PsDscRunAsCredential = $DCredential
        }
        

        SqlDatabaseRecoveryModel Set_SqlDatabaseRecoveryModel_ReportsServer
        {
            Name                 = 'ReportServer'
            RecoveryModel        = 'Simple'
            ServerName           = 'localhost'
            InstanceName         = 'MSSQLSERVER'
            #PsDscRunAsCredential = $SqlAdministratorCredential
            DependsOn = '[SqlSetup]InstallNamedInstance_INST2014'
        }

        SqlDatabaseRecoveryModel Set_SqlDatabaseRecoveryModel_ReportServerTempDB
        {
            Name                 = 'ReportServerTempDB'
            RecoveryModel        = 'Full'
            ServerName           = 'localhost'
            InstanceName         = 'MSSQLSERVER'
            #PsDscRunAsCredential = $SqlAdministratorCredential
            DependsOn = '[SqlSetup]InstallNamedInstance_INST2014'
        }

    
        
                      

        


    }
}
ConfigurationSQL -Nodename sql2014sccm.eastus2.cloudapp.azure.com -ConfigurationData $MyData -Outputpath c:\os\temp\testdsc

<#$sqlinstance = "MSSQLSERVER"
$sqlFQDN = "SQL2014SCCM.contosoad.com"
$usernames = @("cmRSPacct","cmSQLAgent","cmSQLsvc")
$usernames | %{New-ADUser -AccountPassword (ConvertTo-SecureString -AsPlainText -Force "P2ssw0rd" ) -ChangePasswordAtLogon $false -Description "Config Manager Account" -Name $_ -DisplayName $_ -SamAccountName $_  -Enabled $true}
New-ADGroup ConfigMgrAdmins -DisplayName "Config Manager Administrators" -GroupCategory Security -GroupScope Global -samaccountname ConfigMgrAdmins
New-ADGroup ConfigMgrOperators -DisplayName "Config Manager Operators" -GroupCategory Security -GroupScope Global -samaccountname ConfigMgrOps
New-ADGroup ConfigMgrSecurityAdmins -DisplayName "Config Manager Security Administrators" -GroupCategory Security -GroupScope Global -samaccountname ConfigMgrsecAdmin
Start-Sleep -Seconds 5
get-aduser $usernames[2] | Set-ADUser -ServicePrincipalNames @{Add="MSSQLSERVER/$($sqlFQDN):1433","MSSQLSERVER/$($sqlFQDN.Split(".")[0]):1433"}
([ADSI]("WinNT://$($sqlFQDN.Split(".")[0])/administrators,group")).Add("WinNT://contosoad/ConfigMgrAdmins,group")#>



