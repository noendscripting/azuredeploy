<#
.DESCRIPTION
  Script removes performance counters prevously added by a supplied template

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





[string]$WorkspaceName = Read-Host "Type name of Log Analytics workspace below"
[string]$ResourceGroup = Read-Host "Type name of the Resource Group where Log Analytics workspace is located "
[string]$counterList = Read-Host "Type path to the json with counters data in the variabbles"

$counterNames = $null
$counterNames = ( Get-Content $counterList | ConvertFrom-Json).variables.counter.name

if (!($counterNames))
{
  Write-Error "Unable to get list of counters.`nPlease check if the file path is correct and format inside the file matche with one of the templates provided and try again "

}






ForEach($name in $counterNames)
{

    Remove-AzOperationalInsightsDataSource -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -Name $name -Force -verbose
    Start-Sleep -Seconds 2
}