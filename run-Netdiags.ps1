[hashtable]$Destinations = @{

    <#"IPMCS" = '10.42.8.33'
    "Amsterdam" = '10.137.0.252'
    "Bangalore" = '10.71.62.48'
    "Barcelona" = '10.6.253.100'
    "Greenville" = '3.29.222.104'
    "Queretaro" = '10.71.62.48'
    "Salzbergen" = '10.136.82.16'
    "Shanghai" = '10.68.4.122'#>
    "ContosoAD" = "10.1.0.4"
    
    }
    
    $report = @()
    $timeout = new-timespan -Minutes 5
    $sw = [diagnostics.stopwatch]::StartNew()
    while ($sw.elapsed -lt $timeout){
    foreach ($destination in $Destinations.GetEnumerator())
    {
      $pingResult = Test-NetConnection -ComputerName $destination.value -TraceRoute
    
      $item = New-Object psobject -Property @{
      
      'Destination' = $Destination.key
      'RemoteIpAddress' = $pingResult.RemoteAddress.IPAddressToString
      'SourceAddress' = $pingResult.SourceAddress.IPAddress
      'PingStatus' = $pingResult.PingReplyDetails.Status
      'PingResponse' = $pingResult.PingReplyDetails.RoundtripTime
      'RouteHopsCount' = $pingResult.TraceRoute.Length
      }
    
      $report += $item
      iperf3.exe -c $destination.value -f m -w 85KB -t 15 -J --logfile $somelogfilelater
      Clear-Variable item
      Clear-Variable pingResult
      start-sleep -Seconds 10
    }
    }
    $report
    $report | Export-Csv C:\Packages\test.csv -NoTypeInformation
  # Connect-azAccount
    1..4|ForEach-Object {

      $randomFileName = [System.IO.Path]::GetRandomFileName()
      $out = new-object byte[] 1048576
      (new-object Random).NextBytes($out)
      [IO.File]::WriteAllBytes("C:\temp\$($randomFileName)", $out)
      (Measure-Command -Expression {Get-AzStorageAccount -ResourceGroupName Group-test -Name 101csvprocesstest |Get-AzStorageContainer -Name csvdata | Set-AzStorageBlobContent -File C:\temp\$($randomFileName)}).Milliseconds
      start-sleep -Seconds 5
      Remove-Item -Path "C:\temp\$($randomFileName)"
    }