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
param()

# verify current session is logen on to Azure and prompt for login if not
$context = Get-AzContext

    if (!$context) 
    {
        Write-Host "No connected to Azure. Please follow steps below to login" -ForegroundColor DarkYellow
        Connect-AzAccount 
    } 
$list = @()

#Enter name of the table to be queried
$tableName = Read-Host "Type case sensitive name of the table you are going to search"

# start itertaing through available subscrioptions and Log Analytics worspaces
Get-AzSubscription | ForEach-Object {
    Write-Host "Processing subscriotion $($_.Name)." -NoNewline
    Select-AzSubscription -SubscriptionId $_.Id | Out-Null
    $LogAnalyticsList = (Get-AzOperationalInsightsWorkspace).CustomerId
    Write-Host " Number of workspaces found: $($LogAnalyticsList.length)"
    #Create a name string for uniqueness
    ForEach($LogAnalyticsItem in $LogAnalyticsList)
    {
       
        $list += $LogAnalyticsItem


    }
    clear-variable LogAnalyticsList
      

}
write-verbose $list.Length

$queryString = "union "

# Iterate through Log Analytics Entries to put together union query string
for($i=0; $i -le $list.Length-1; $i++)
{
    $querystring += "workspace(""$($list[$i])"").$($tableName),`n"
    #if number of entries is 100 print out current query string and start a new query string
    if ($i/99 -eq 1)
    {
        Write-Host "Reached search limit of 100 workspaces priniting search batch now" -ForegroundColor DarkGreen
        Write-Host "$($queryString.TrimEnd(",","`n"))"-ForegroundColor DarkGreen
        $queryString = "union "

    }
}

# print out remaining worksace union string if less than 100 

Write-Host "Printing final search batch:" -ForegroundColor DarkGreen
Write-Host "$($queryString.TrimEnd(",","`n"))" -ForegroundColor DarkGreen

