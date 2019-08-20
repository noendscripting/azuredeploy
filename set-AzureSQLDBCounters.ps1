<#
DISCLAIMER
    THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
    We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object
    code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software
    product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the
    Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims
    or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
    Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained within
    the Premier Customer Services Description.
#>


#Requires -Version 6.0
#Requires -Modules @{ModuleName="Az"; ModuleVersion="2.5.0"}



$ResourceGroup = '' # name of the resource group where database server is located
$server = '' # name of the SQL server
$actionGroupName = '' # name of the Action Group for the alerts
$actionGroupRescourceGroupName = '' # name of the resource group where Action Group is located
$metricName = '' # name of the metric for the counter e.g dtu_consumption_percent
$TimeAggregation = '' # time aggregation value e.g Maximum, Minmum, Average 
$criteriaOperator = '' #criterai operator e.g GreaterThanOrEqual
[int]$Threshold = 90  # Threshold value
$windowSize = New-TimeSpan -Minutes 5 # windows size value
$frequency = New-TimeSpan -Minutes 5 # frequiency value 
$rulenamePrefix = "" # name prefix for the rul e.g "STG Critical Alert DTU is over 90 percent for"
[int]$alertSeverity = 3 # control severity , a numerical value


Try {
    Get-AzSubscription | Out-Null
}
Catch{
    Write-Host "You are not logged on to Azure.`rPlease login and run the script again`rTerminating script" -ForegroundColor DarkRed
}

# Get list of databases
$Databases = $null
$Databases = Get-AzSqlDatabase -ServerName $server -ResourceGroupName $ResourceGroup | Where-Object { $_.DatabaseName -ne 'master' } | Select-Object ResourceId, DatabaseName

if ($Databases -ne $null) {
    Write-Host "$($databases.count) databases found on server $($server)" -ForegroundColor DarkGreen
}
else {
    Write-Host "No databases found. Treminating script"  -ForegroundColor DarkRed
    exit   
}

#Geting ActionGroup ID
$actionGroupId = (Get-AzActionGroup  -ResourceGroupName $actionGroupRescourceGroupName   -Name $actionGroupName).Id
$act = New-AzActionGroup -ActionGroupId $actionGroupId

#Cretaing criteria for alerts
$condition = New-AzMetricAlertRuleV2Criteria -MetricName $metricName  -TimeAggregation $TimeAggregation -Operator $criteriaOperator -Threshold $Threshold

#Cretaing rule for each DB
foreach ($Database in $Databases) {
    $AlertParams = @{
        Name             = "$($ruleNamePrefix) $($Database.DatabaseName)"
        ResourceGroup    = $ResourceGroup
        TargetResourceID = $Database.ResourceID 
        Frequency        = $frequency
        WindowSize       = $windowSize 
        ActionGroup      = $act
        condition        = $condition
        severity         = $alertSeverity        
    }
    Add-AzMetricAlertRuleV2 @AlertParams
}
 
