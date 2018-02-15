$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $env:COMPUTERNAME
Enable-PSRemoting -SkipNetworkProfileCheck -Force
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP
Set-NetFirewallProfile -All -LogAllowed True -LogBlocked True -LogIgnored True

try
{
  #Verify if PowerShellGet module is installed. If not install
  if (!(Get-Module -Name PowerShellGet))
  {
      Invoke-WebRequest 'https://download.microsoft.com/download/C/4/1/C41378D4-7F41-4BBE-9D0D-0E4F98585C61/PackageManagement_x64.msi' -OutFile $($env:temp +'\PackageManagement_x64.msi')
      Start-Process "$($env:temp)\PackageManagement_x64.msi" -ArgumentList "/qn" -Wait
  }
    
  ##Verify if PSWindowsUpdate PowerShell Module is installed. If not install.
  #  if (!(Get-Module -Name PSWindowsUpdate -List)){
  #      Install-Module -Name PSWindowsUpdate -Scope AllUsers -Confirm:$false -Force
  #  }
  #  Get-WUInstall -WindowsUpdate -AcceptAll -AutoReboot -Confirm:$FALSE -ErrorAction stop
}
catch
{
    Write-Output "Oops. Something failed"
}
