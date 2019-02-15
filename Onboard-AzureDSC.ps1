﻿ 


[DscLocalConfigurationManager()]
Configuration DscMetaConfigs
{
     param
     (
         [Parameter(Mandatory=$True)]
         [String]$RegistrationUrl,

         [Parameter(Mandatory=$True)]
         [String]$RegistrationKey,

         [Parameter(Mandatory=$True)]
         [String[]]$ComputerName,

         [Int]$RefreshFrequencyMins = 30,

         [Int]$ConfigurationModeFrequencyMins = 15,

         [String]$ConfigurationMode = 'ApplyAndMonitor',

         [String]$NodeConfigurationName,

         [Boolean]$RebootNodeIfNeeded= $True,

         [String]$ActionAfterReboot = 'ContinueConfiguration',

         [Boolean]$AllowModuleOverwrite = $False,

         [Boolean]$ReportOnly
     )

     if(!$NodeConfigurationName -or $NodeConfigurationName -eq '')
     {
         $ConfigurationNames = $null
     }
     else
     {
         $ConfigurationNames = @($NodeConfigurationName)
     }

     if($ReportOnly)
     {
         $RefreshMode = 'PUSH'
     }
     else
     {
         $RefreshMode = 'PULL'
     }

     Node $ComputerName
     {
         Settings
         {
             RefreshFrequencyMins           = $RefreshFrequencyMins
             RefreshMode                    = $RefreshMode
             ConfigurationMode              = $ConfigurationMode
             AllowModuleOverwrite           = $AllowModuleOverwrite
             RebootNodeIfNeeded             = $RebootNodeIfNeeded
             ActionAfterReboot              = $ActionAfterReboot
             ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins
         }

         if(!$ReportOnly)
         {
         ConfigurationRepositoryWeb AzureAutomationStateConfiguration
             {
                 ServerUrl          = $RegistrationUrl
                 RegistrationKey    = $RegistrationKey
                 ConfigurationNames = $ConfigurationNames
             }

             ResourceRepositoryWeb AzureAutomationStateConfiguration
             {
             ServerUrl       = $RegistrationUrl
             RegistrationKey = $RegistrationKey
             }
         }

         ReportServerWeb AzureAutomationStateConfiguration
         {
             ServerUrl       = $RegistrationUrl
             RegistrationKey = $RegistrationKey
         }
     }
}

 # Create the metaconfigurations
 # NOTE: DSC Node Configuration names are case sensitive in the portal.
 # TODO: edit the below as needed for your use case
$Params = @{
     RegistrationUrl = 'https://eus2-agentservice-prod-1.azure-automation.net/accounts/7cbb540d-c20a-441b-ab00-d3fc02416f0c';
     RegistrationKey = 'tVjsObUIMUauIC8HUWwCuMK8c9UfyKhknRUoQdihQoHWYWs/vs2KG1AlSjGTBvUl3PkAJBEkO1ll6UXi0oRV+Q==';
     ComputerName = @('localhost');
     NodeConfigurationName = 'DomainControllerConfig.localhost';
     RefreshFrequencyMins = 15;
     ConfigurationModeFrequencyMins = 5;
     RebootNodeIfNeeded = $True;
     AllowModuleOverwrite = $False;
     ConfigurationMode = 'ApplyAndMonitor';
     ActionAfterReboot = 'ContinueConfiguration';
     ReportOnly = $False;  # Set to $True to have machines only report to AA DSC but not pull from it
}

DscMetaConfigs @Params
Set-DscLocalConfigurationManager -Path ./DscMetaConfigs