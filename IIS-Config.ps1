
Configuration IISConfig
{
    Import-DscResource -ModuleName xWebAdministration 
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Node localhost
    {

        WindowsFeatureSet AddAllFeatures
        {
            Name                    = @('NET-WCF-Services45','Web-Server','Web-Mgmt-Tools')
            Ensure                  = 'Present'
            IncludeAllSubFeature    = $true
        }
        xIisLogging 'IISLogDefaults'
        {
            LogPath = "$($env:SystemDrive)\inetpub\logs\LogFiles"
            LogFormat = 'W3C'
            LogPeriod = 'Hourly'
            LogFlags = @('Date', 'Time', 'ClientIP', 'UserName', 'SiteName', 'ComputerName', 'ServerIP', 'Method', 'UriStem', 'UriQuery', 'HttpStatus', 'Win32Status', 'BytesSent', 'BytesRecv', 'TimeTaken', 'ServerPort', 'UserAgent', 'Cookie', 'Referer', 'ProtocolVersion', 'Host', 'HttpSubStatus')
            DependsOn = '[WindowsFeatureSet]AddAllFeatures'
        }
        TimeZone 'SetLocalTimezone'
        {
            IsSingleInstance = 'yes'
            TimeZone = 'Eastern Standard Time'
        }
    }
}

IISConfig -OutputPath C:\Temp\configs