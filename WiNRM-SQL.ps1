


#Verify if PowerShellGet module is installed. If not install
if (!(Get-Module -Name PowerShellGet))
{
    Invoke-WebRequest 'https://download.microsoft.com/download/C/4/1/C41378D4-7F41-4BBE-9D0D-0E4F98585C61/PackageManagement_x64.msi' -OutFile "$($PWD)\PackageManagement_x64.msi"
    Start-Process "$($PWD)\PackageManagement_x64.msi" -ArgumentList "/qn" -Wait
  }





Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name SQLServerDSC,StorageDSC,XtimeZone,PSDscResources -Scope AllUsers -Confirm:$false -Force
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=839516" -OutFile "$($PWD)\wmf5.1.msu"
Start-Process -FilePath 'wusa.exe' -ArgumentList "$($PWD)\wmf5.1.msu /quiet /noreboot" -NoNewWindow -Wait

$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $env:COMPUTERNAME
Enable-PSRemoting -SkipNetworkProfileCheck -Force
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP
Set-NetFirewallProfile -All -LogAllowed True -LogBlocked True -LogIgnored True

$PlainPassword = "1hfxLwbLsT4PbE4JztmeLOm+4I6eEmPMUnlgB0x4tHTN6qMQ4Hdb56oNLZuKIhOnm+uf8lbDMBXl7QdxtSPj/Q=="
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$UserName = "101filepoc"
$DriveCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
New-PSDrive -Name "SQLDISK" -PSProvider FileSystem -Root "\\101filepoc.file.core.windows.net\iso" -Credential $DriveCredentials

Copy-Item -Path \\101filepoc.file.core.windows.net\iso\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso -Destination d:\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso -PassThru
$setupDriveLetter = (Mount-DiskImage -ImagePath D:\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso -PassThru | Get-Volume).DriveLetter

New-Item C:\SQLDISK -ItemType Directory
Copy-Item "$($setupDriveLetter):\*" -Recurse -Destination C:\SQLDISK -Verbose -ErrorAction Stop
