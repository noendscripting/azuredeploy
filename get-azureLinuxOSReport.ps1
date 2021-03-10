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

$geVMData = Import-Csv .\gelinuxoms.csv

#create Linux script to use with run command
'cat /etc/os-release' | Out-File .\linuxversion.sh





$output = @()

foreach($vmEntry in $geVMData)
{
    $vmEntry.resourceId
    $result = (Invoke-AzVMRunCommand -ResourceId  $vmEntry.resourceId -CommandId 'RunShellScript' -ScriptPath .\linuxversion.sh -ErrorVariable outerror -ErrorAction SilentlyContinue).Value.message

    #basic error checking
    if($outerror)
    {
        $result = $outerror
    }
    $item = New-Object [PSCustomObject] @{
        SubscriptionName = $vmEntry.subscriptionName
        ResourceGroupName = $vmEntry.resourceGroup
        VMName = $vmEntry.resourceName
        OSdata = $result

    }
    $output += $item
    Clear-Variable result
    Clear-Variable item
    Clear-Variable outerror

}

$output