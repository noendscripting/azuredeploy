$WorkspaceName = 'logcollection'
$ResourceGroup = 'stagegroup'
#$countreList = '.\add-DC-counters-loganalytics-basic.json'
$countreList = '.\add-DC-counters-loganalytics-full.json'

$counterNames = ( Get-Content $countreList | ConvertFrom-Json).variables.counter.name






ForEach($name in $counterNames)
{

    Remove-AzOperationalInsightsDataSource -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -Name $name -Force -verbose
    Start-Sleep -Seconds 2
}