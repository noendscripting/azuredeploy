
$proretiesArray = @()


foreach($line in [System.IO.File]::ReadLines("C:\Users\miresnic\OneDrive - Microsoft\Documents\DCCollector-BASELIST.TXT"))
{
    if (!($line -match "^\\"))
    {
         $line = "\$($line)"
    }

    
     [string[]]$counterArray = $line -split "\\"
    
    if ($counterArray[1].IndexOf("(") -ge 0)
   {
        [string[]]$objectNameArray = $counterArray[1] -split "\("
        $objectName = $objectNameArray[0]
        $instanceName = ($objectNameArray[1] -split "\)")[0]

   }
   else {
        $objectName = $counterArray[1]
        $instanceName = "*"
   }
   $counterName = $counterArray[2]
   $laesourceName = $line -replace "[^a-zA-Z0-9]+"
   Write-Verbose "$($objectName), $($instanceName), $($counterName)"
   $newPerofmanceArgs = @{
     ObjectName = $objectName
     InstanceName = $instanceName
     CounterName = $counterName
     Name = $laesourceName
     intervalSeconds="[parameters('intervalSeconds')]"
   }

   #New-AzOperationalInsightsWindowsPerformanceCounterDataSource -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName @newPerofmanceArgs  #-ObjectName "Database" -InstanceName "lsass" -CounterName "Version Buckets Allocated" -IntervalSeconds 20 -Name "Database(lsass)\Version Buckets Allocated"
   $proretiesArray+=$newPerofmanceArgs
   Clear-Variable objectName
   Clear-Variable instanceName
   Clear-Variable laesourceName
   Clear-Variable counterArray
   Clear-Variable objectNameArray
}

$proretiesArray | ConvertTo-Json | Out-File C:\Temp\perfcounter-base.json








