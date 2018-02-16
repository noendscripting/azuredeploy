$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $env:COMPUTERNAME
Enable-PSRemoting -SkipNetworkProfileCheck -Force
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP
Set-NetFirewallProfile -All -LogAllowed True -LogBlocked True -LogIgnored True


#Verify if PowerShellGet module is installed. If not install
if (!(Get-Module -Name PowerShellGet))
{
    Invoke-WebRequest 'https://download.microsoft.com/download/C/4/1/C41378D4-7F41-4BBE-9D0D-0E4F98585C61/PackageManagement_x64.msi' -OutFile "$($PWD)\PackageManagement_x64.msi"
    Start-Process "$($PWD)\PackageManagement_x64.msi" -ArgumentList "/qn" -Wait
  }
    

  
    
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name SQLServerDSC,StorageDSC,XtimeZone,PSDscResources -Scope AllUsers -Confirm:$false -Force
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=839516" -OutFile "$($PWD)\wmf5.1.msu"
Start-Process -FilePath 'wusa.exe' -ArgumentList "$($PWD)\wmf5.1.msu /quiet /noreboot" -NoNewWindow -Wait

