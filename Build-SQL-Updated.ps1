

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
		#[PSCredential]$DriveCredentials,
        #[PSCredential]$DomainCredentials,
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



Import-DscResource -ModuleName SQLServerDSC -ModuleVersion 11.1.0.0
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



        SqlSetup InstallNamedInstance_INST2014
        {

            Action                = 'Install'
            InstanceName          = 'SCCM2017LAB'
            Features              = 'SQLENGINE,FULLTEXT,RS,SSMS,ADV_SSMS'
            SQLCollation          = 'SQL_Latin1_General_CP1_CI_AS'
            SQLSvcAccount         = $SQLServerAccountCredentials
            AgtSvcAccount         = $SQLAgentAccountCredentials
            RSSvcAccount          = $SQLRSAccountCredentials
            SQLSysAdminAccounts   = ".\Administrators"
            InstallSharedDir      = "C:\Program Files\Microsoft SQL Server"
            InstallSharedWOWDir   = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir           = 'C:\Program Files\Microsoft SQL Server'
            InstallSQLDataDir     = "$($DataDriveLetter):\Data"
            SQLUserDBDir          = "$($DataDriveLetter):\Data"
            SQLUserDBLogDir       = "$($DataDriveLetter):\Data"
            SQLTempDBDir          = "$($DataDriveLetter):\Data"
            SQLTempDBLogDir       = "$($DataDriveLetter):\Data"
            SQLBackupDir          = "$($DataDriveLetter):\Backup"
            SourcePath            = $SQLSourceFolder
            UpdateEnabled         = 'True'
            UpdateSource          = 'MU'
            ForceReboot           = $false
            BrowserSvcStartupType = 'Automatic'
            #PsDscRunAsCredential  = $SqlInstallCredential
            DependsOn             = '[WindowsFeatureSet]Framework','[WaitforDisk]Wait_Data_Disk'

        }

        SqlRS DefaultConfiguration

        {

            InstanceName         = 'MSSQLSERVER'
            DatabaseServerName   = 'sql2014sccm'
            DatabaseInstanceName = 'MSSQLSERVER'
            DependsOn = '[SqlSetup]InstallNamedInstance_INST2014'

        }




        Group AddADUserToLocalAdminGroup {
            GroupName='Administrators'
            Ensure= 'Present'
            MembersToInclude= "Contosoad\ConfigMgrAdmins"
            Credential = $SQLServerAccountCredentials
            #PsDscRunAsCredential = $DCredential
            DependsOn = '[SqlSetup]InstallNamedInstance_INST2014'
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

        <#SqlWindowsFirewall Create_FirewallRules
       {
             Ensure               = 'Present'
             Features             = 'SQLENGINE,AS,RS,IS'
             InstanceName         = 'SCCM2017LAB'
             SourcePath           = $SQLSourceFolder
         }#>
         Script EnableFirewall
         {
             # Must return a hashtable with at least one key
             # named 'Result' of type String
             GetScript= {
                 Return @{
                     Result = Get-NetFirewallRule -DisplayName "SQL*"
                 }
             }
             # Must return a boolean: $true or $false
             TestScript = {

                 $sqlrules = Get-NetFirewallRule -DisplayName "SQL*"
                 if ($sqlrules -eq $null -xor $sqlrules.count -ne 3)
                 {
                     return $false
                 }
                 else
                 {
                     return $true
                 }

                 }
             # Returns nothing
             SetScript= {
                 Write-Verbose "Setting firewall rule SQL Server Access via TCP Port 1433"
                 New-NetFirewallRule -Name "SQL-TCP-Port-1433-Allow-Inbound" -DisplayName "SQL Server Access via TCP Port 1433" -Direction Inbound -Action Allow -Protocol TCP –LocalPort 1433 -Description "SQL Server Port Access Rule" -Enabled True -Profile Domain
                 Write-Verbose "Setting firewall rule SQL Browser via UDP port 1434"
                 New-NetFirewallRule -DisplayName "SQL Browser via UDP port 1434" -Direction Inbound -Action Allow -Protocol UDP –LocalPort 1434 -Description "SQL Browser Port Access Rule" -Enabled True -Profile Domain -Name "SQL-Browser-UDP-Port-1434-Allow-Inbound"
                 Write-Verbose "Setting firewall rule SQL Service Broker via TCP port 4022"
                 New-NetFirewallRule -DisplayName "SQL Service Broker via TCP port 4022" -Direction Inbound -Action Allow -Protocol UDP –LocalPort 4022 -Description "SQL Service Broker Access Rule" -Enabled True -Profile Domain -Name "SQL-Broker-TCP-Port-4022-Allow-Inbound"
             }
         }










    }
}
ConfigurationSQL -Nodename sql2014sccm.eastus2.cloudapp.azure.com -ConfigurationData $MyData -Outputpath c:\os\temp\testdsc




