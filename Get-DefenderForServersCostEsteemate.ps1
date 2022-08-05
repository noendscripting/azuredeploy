<#
DESCRIOTION:
The script will iterate though all accessible subscriotions and LogAnalytics workstaions to create initial part of the kusto query to cross query all workspaces.
If the numbre of LogAnalytics workspaces is more than 100, script will out put union queries in batches of 100 or less. 
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


[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("P1","P2")]
    [string]
    $sku,
    [Parameter(Mandatory=$true)]
    [ValidateSet("Week","Month")]
    [string]
    $TimeRange
)


Function Get-QueryData {
    Param(
        $queryPrefix,
        $workspaceId,
        $costVariable,
        $DateRange

    )

    $queryFilters = "| where TimeGenerated > ago($($DateRange))  and ResourceProvider in ('Microsoft.Compute', 'Microsoft.HybridCompute') and Computer !contains ""."" "  
    $queryDynamicValue1 = "| extend state_per_hour=iff(heartbeats_per_hour>0, true, false)"
    $queryOutPutPreFilter = "| summarize heartbeats_per_hour=count() by bin(TimeGenerated, 1h), Computer, SubscriptionId"
    $queryOutputFinalView = "| summarize total_running_hours=countif(state_per_hour==true) by Computer, SubscriptionId"
    $queryOutputViewFilter = "| where total_running_hours > 0 and isnotempty (SubscriptionId)"

    $queryString = "$($queryPrefix.TrimEnd(","," "))$($queryFilters)$($queryOutPutPreFilter)$($queryDynamicValue1)$($queryOutputFinalView)$($queryOutputViewFilter)"
    Write-Verbose $queryString
    (Invoke-AzOperationalInsightsQuery -WorkspaceId $workspaceId -Query $queryString).Results | ForEach-Object {

        $outPutObject = New-Object psobject -Property @{
            'Computer'          = $PSItem.Computer.ToString()
            'SubscriptionId'    = $PSItem.SubscriptionId
            'TotalRunningHours' = $PSItem.total_running_hours
            'CostEsteemate($)'     = "$"+ "$([int]$PSItem.total_running_hours * $costVariable)"
        }
        return $outPutObject
    }

    

}



# verify current session is loged on to Azure and prompt for login if not
$context = Get-AzContext

if (!$context) {
    Write-Host "No connected to Azure. Please follow steps below to login" -ForegroundColor DarkYellow
    Connect-AzAccount 
} 
$list = @()
$output = @()

Switch ($sku)
{
    "P1" {[decimal]$adjustment = '0.01' }
    "P2" {[decimal]$adjustment = '0.02' }
     
}

Switch($TimeRange)
{
    "Week" {$daysAgo = "7d"}
    "Month"{$daysAgo = "30d"}
}

$queryPrefix = "union "
$tableName = "Heartbeat"
$list = @{}
#discover all availble workspaces

$workspaceQuery = 'resources|where type== "microsoft.operationalinsights/workspaces" |  extend workspaceId = properties.customerId |  summarize workspaceID=make_set(workspaceId) by location'



(Search-AzGraph -Query $workspaceQuery).Data | ForEach-Object {
    $list.Add($_.location, $_.workspaceId)
}




# Iterate through Log Analytics Entries to put together union query string
ForEach ($region in $list.keys) {
    $workspaces = $list[$region]

    Write-Host "Processing $($workspaces.Count) workspaces from $($region) region" -ForegroundColor DarkGreen
    for ($i = 0; $i -le $workspaces.Length - 1; $i++) {
        $queryPrefix += "workspace(""$($workspaces[$i])"").$($tableName),"
        #if number of entries is 100 print out current query string and start a new query string
        if ($i % 100 -eq 0 -or $i -eq $workspaces.Length -1) {
            Get-QueryData -queryPrefix $queryPrefix -workspaceId $workspaces[0] -costVariable $adjustment -DateRange $daysAgo | ForEach-Object {
                $output += $PSItem
            }
            $queryPrefix = "union "
        
        }
    }
    

}


$output | Export-Csv C:\Temp\costesteemate.csv -Force