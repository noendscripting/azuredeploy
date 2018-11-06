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

param(
    [int]$minutes=30
)

Function get-RunErrors
{
    param(
    $RunResults
    )

    [xml]$xmlDetails = $RunResults.RunDetails().ReturnValue

    $exportErrors = $xmlDetails.'run-history'.'run-details'.'step-details'.'synchronization-errors'.'export-error'
    $importErrors = $xmlDetails.'run-history'.'run-details'.'step-details'.'synchronization-errors'.'import-error'
    $output =@()
    if ($exportErrors.count -ne 0)
    {

        $output +=  $exportErrors
    }

    if ($importErrors.count -ne 0)
    {
      $output += $importErrors
    }

Return $output

}

$report=@()


$date= Get-Date (Get-Date).AddMinutes(-$minutes).ToUniversalTime() -Format 'yyyy-MM-dd HH:mm:ss'
$filter = "RunStartTime > '$($date)' and RunStatus <> 'success'"
$RunData = Get-WmiObject -ClassName 'MIIS_RunHistory' -Namespace 'root\MicrosoftIdentityintegrationServer' -Filter $filter
if ($RunData.Count -eq $null)
{
   $report += (get-RunErrors -RunResults $RunData)

}
else
{

    forEach( $runItem in $RunData)
    {
        $report += (get-RunErrors -RunResults $runItem)


    }

}

$report