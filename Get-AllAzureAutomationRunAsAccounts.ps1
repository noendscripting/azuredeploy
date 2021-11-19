[CmdletBinding()]

class AutomationAccount {
    [string] $Name
    [string] $ResourceId
    [string] $Region
    [string] $ResourceGroup
    [string] $SubscriptionId
    [string] $RunAsAppId
    [DateTimeOffset] $RunAsConnectionCreationTime
    [bool] $UsesThirdParytCert
}

$allAccounts = New-Object System.Collections.ArrayList
$defaultDate = (Get-Date 01-01-1970)
$queryResults = Search-AzGraph -Query 'resources | where type == "microsoft.automation/automationaccounts"' -OutVariable $account
$output = @()


 foreach($queryResult in $queryResults)
{

    $accountItem = [AutomationAccount]@{
        ResourceId                  = $queryResult.ResourceId
        Name                        = $queryResult.Name
        Region                      = $queryResult.Location
        ResourceGroup               = $queryResult.resourceGroup
        SubscriptionId              = $queryResult.subscriptionId
        RunAsAppId                  = ""
        RunAsConnectionCreationTime = $defaultDate
        UsesThirdParytCert          = $false
    }
    Write-Debug "$($accountItem.Name), $($accountItem.Region), $($accountItem.ResourceGroup), $($accountItem.SubscriptionId)"

    $allAccounts.Add($accountItem) | Out-Null
}


$accountsGroups = $allAccounts| Group-Object { $_.SubscriptionId }

    foreach ($accountsGroup in $accountsGroups) {
        Write-Output ""
        Write-Output "Procesing accounts in subscription $($accountsGroup.Name): $($accountsGroup.Group.Count)"
        Select-AzSubscription -SubscriptionId $accountsGroup.Name | Out-Null

        foreach ($accountItem in $accountsGroup.Group) {

         $item = Get-AzAutomationConnection -AutomationAccountName $accountItem.Name -ResourceGroupName $accountItem.ResourceGroup -Name "AzureRunAsConnection" | Select-Object AutomationAccountName,@{Label="ApplicationId";Expression={$_.FieldDefinitionValues.ApplicationId}},@{Label="SubscriptionName";Expression={(Get-AzSubscription -SubscriptionId $_.FieldDefinitionValues.SubscriptionId).Name}},@{Label="SubscriptionId";Expression={$_.FieldDefinitionValues.SubscriptionId}}, ResourceGroupName
        $output += $item
        Clear-Variable item
            
        }
        
    }

$output
$output | Export-Csv ./automationAccountAppId.csv -Force