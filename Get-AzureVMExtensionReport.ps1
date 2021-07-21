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


$extensionName = "MDE.Windows"
#$extensionName = "contoso-DSC-ForestBuild"
$report = @()
$subscriptions = Get-AzSubscription
foreach ($subscription in $subscriptions) {
    Set-AzContext $subscription.Name | Out-Null
    $VMResources = Get-AzResource -ResourceType 'Microsoft.Compute/virtualMachines'
    foreach ($VMResource in $VMResources) {
        # Check if VM has extension and add to report
        if (((Get-AzVMExtension -ResourceGroupName $VMResource.ResourceGroupName -VMName $VMResource.Name) | Select-Object -ExpandProperty  Name) -contains $extensionName) {
            $item = [PSCustomObject]@{
                SubscriptionName = $subscription.Name
                SubscriotionId = $subscription.Id
                VMName = $VMResource.Name

            }
        $item
           $report += $item
           Clear-Variable item
        }
        
    }
}
if ($report.count -ne 0)
{
$report | Export-Csv .\extensionReport.csv -NoTypeInformation
}
else{
    Write-Host "No VMs with extension name $($extensionName) found"
}