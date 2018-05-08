


#Verify if PowerShellGet module is installed. If not install
if (!(Get-Module -Name PowerShellGet))
{
    Invoke-WebRequest 'http://packagesource.contosoad.com/downloads/PackageManagement_x64.msi' -OutFile "$($PWD)\PackageManagement_x64.msi" -ErrorAction Stop
    Start-Process "$($PWD)\PackageManagement_x64.msi" -ArgumentList "/qn" -Wait
  }


Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
#Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Register-PSRepository -Name "Internal" -SourceLocation http://packagesource.contosoad.com/nuget -InstallationPolicy Trusted -ErrorAction Stop
Install-Module -Name SQLServerDSC,StorageDSC,XtimeZone,PSDscResources,xWebAdministration,xWindowsUpdate,xNetworking -Scope AllUsers -Confirm:$false -Force -Repository "Internal" -ErrorAction Stop
#Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=839516" -OutFile "$($PWD)\wmf5.1.msu"

Invoke-WebRequest -Uri "http://packagesource.contosoad.com/downloads/wmf5.1.msu" -OutFile "$($PWD)\wmf5.1.msu" -ErrorAction Stop
Start-Process -FilePath 'wusa.exe' -ArgumentList "$($PWD)\wmf5.1.msu /quiet /noreboot" -NoNewWindow -Wait -ErrorAction Stop

$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $env:COMPUTERNAME
Enable-PSRemoting -SkipNetworkProfileCheck -Force
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP
Set-NetFirewallProfile -All -LogAllowed True -LogBlocked True -LogIgnored True

<#$PlainPassword = "1hfxLwbLsT4PbE4JztmeLOm+4I6eEmPMUnlgB0x4tHTN6qMQ4Hdb56oNLZuKIhOnm+uf8lbDMBXl7QdxtSPj/Q=="
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$UserName = "101filepoc"
$DriveCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
New-PSDrive -Name "SQLDISK" -PSProvider FileSystem -Root "\\101filepoc.file.core.windows.net\iso" -Credential $DriveCredentials -Persist $false

copy-item -Path SQLDISK:\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso -Destination D:\ -PassThru
Remove-PSDrive -Name "SQLDISK"#>
try {
  Invoke-WebRequest -Uri "http://packagesource.contosoad.com/downloads/en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso" -OutFile "D:\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso"
  $setupDriveLetter = (Mount-DiskImage -ImagePath D:\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso -PassThru | Get-Volume).DriveLetter

New-Item C:\SQLCD -ItemType Directory -Force
Copy-Item "$($setupDriveLetter):\*" -Recurse -Destination C:\SQLCD -Verbose -ErrorAction Stop
}
catch {

    $Error[0].PSMessageDetails | Out-File "$($PWD)\error.log"

}


