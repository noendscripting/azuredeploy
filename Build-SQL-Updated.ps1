

$MyData = 
@{
    AllNodes = @(
    
    @{
            NodeName="SQL2014SCCM"
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
		[string]$DomainName,
		[array]$DNSSearchSuffix,
		[string]$dNSIP

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



Node $NodeName {
    LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyAndAutoCorrect'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
		}
        
        WindowsFeature Frameowork_4.5
		{ 
			Ensure = "Present" 
			Name = "AS-NET-Framework"
		}

		WindowsFeature Framework_3.5
		{ 
			Ensure = 'Present' 
			Name = 'NET-Framework-Features' 
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
			DriveLetter = "F"
			AllocationUnitSize = 4096
			DependsOn = '[WaitforDisk]Wait_Data_Disk'
		}

        
        
        SqlServiceAccount SetServiceAccount
        {
            ServerName     = "sql2014sccm"
            InstanceName   = 'MSSQLSERVER'
            ServiceType    = 'DatabaseEngine'
            ServiceAccount = $SQLServerAccountCredentials
            RestartService = $true
        }

        SqlServiceAccount SetRSAccount
        {
            ServerName     = "sql2014sccm"
            InstanceName   = 'MSSQLSERVER'
            ServiceType    = 'ReportingServices'
            ServiceAccount = $SQLRSAccountCredentials
            RestartService = $true
        }

        SqlServiceAccount SetAgentAccount
        {
            ServerName     = "sql2014sccm"
            InstanceName   = 'MSSQLSERVER'
            ServiceType    = 'SQLServerAgent'
            ServiceAccount = $SQLAgentAccountCredentials
            
        }

        File CreateLogsDirectory
        {
           DestinationPath = "F:\Logs"
           Ensure = "Present"
           Type = "Directory"
           DependsOn = "[Disk]Data_Disk"
        }
        
        File CreateDBDirectory
        {
           DestinationPath = "F:\Data"
           Ensure = "Present"
           Type = "Directory"
           DependsOn = "[Disk]Data_Disk"
        }
        File CreateBackupDirectory
        {
           DestinationPath = "F:\Backup"
           Ensure = "Present"
           Type = "Directory"
           DependsOn = "[Disk]Data_Disk"
        }
        
    SqlDatabaseDefaultLocation SetLogLocation

    {
            ServerName     = "sql2014sccm"
            InstanceName   = 'MSSQLSERVER'
            Type = "Log"
            Path = "F:\Logs"
            RestartService = $true
            DependsOn = '[File]CreateLogsDirectory'

    }

    SqlDatabaseDefaultLocation SetDBLocation

    {
            ServerName     = "sql2014sccm"
            InstanceName   = 'MSSQLSERVER'
            Type = "Data"
            Path = "F:\Data"
            RestartService = $true
            DependsOn = '[File]CreateDBDirectory'


    }

    SqlDatabaseDefaultLocation SetBackupLocation

    {
            ServerName     = "sql2014sccm"
            InstanceName   = 'MSSQLSERVER'
            Type = "Backup"
            Path = "F:\Backup"
            RestartService = $true
            DependsOn = '[File]CreateBackupDirectory'


    }

    
        
                      

        


}
}
ConfigurationSQL -Nodename sql2014sccm -ConfigurationData $MyData

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



