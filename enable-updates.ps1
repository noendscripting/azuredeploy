


$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $env:COMPUTERNAME
Enable-PSRemoting -SkipNetworkProfileCheck -Force
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP
Set-NetFirewallProfile -All -LogAllowed True -LogBlocked True -LogIgnored True


Write-Verbose "Checking installed updates" 
$UpdateSession = New-Object -ComObject "Microsoft.Update.Session"
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

If (($UpdateSearcher.QueryHistory(0,1)| select Date).Date -le (Get-Date).Add(-40))
{
    Write-Verbose "Creating Download Selection" 
    $SearchResults = $UpdateSearcher.Search("IsInstalled=0 and IsHidden=0")
    $availabaleUpdates = $SearchResults.RootCategories.Item(4).Updates
    $DownloadCollection = New-Object -com "Microsoft.Update.UpdateColl"
    ForEach($update in $availabaleUpdates )
    {
        $DownloadCollection.Add($update)
    }
    Write-Verbose "Downloading Updates" 
    $Downloader = $UpdateSession.CreateUpdateDownloader() 
    $Downloader.Updates = $DownloadCollection 
    $Downloader.Download() 
    Write-verbose "Download complete."
    Write-Verbose "Creating Installation Object"
    $InstallCollection = New-Object -com "Microsoft.Update.UpdateColl" 
    ForEach($update in $availabaleUpdates )
    {
        if($update.IsDownloaded)
        {
            $InstallCollection.Add($update) | Out-Null 
        }

    } 
    $Installer = $UpdateSession.CreateUpdateInstaller() 
    $Installer.Updates = $InstallCollection 
    $Results = $Installer.Install()

    if ($Results.RebootRequired) { 
            Write-Verbose "Rebooting..." 
            Restart-Computer ## add computername here 
        } 
        

}