<#
 
.SYNOPSIS  
  The script is deisgned to restore Azure VM from Azure Backup into a diffirent VNET
.DESCRIPTION
  Script can be used with Azure Automation to create resource group for restore , run azure restore to recover disk and then create a VM in a separate VNET and set default Azure DNS.
  Post restore steps will remove it from Domain, rename VM and set DNS back to inherit from VNET
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
.Parameter vaultName
 Name of the backup vault where backup is tored
.Parameter vaultRG
 Name of the Resource Group where backup vault is located
.Parameter vmName
 Name of the backed up VM
.Parameter targetVnetname
 Name of the VNET where recovered VM will be stored
.Parameter newVMname
 Name of the restored VM
.Parameter vmRG
 Resource group for original VM
.Parameter storageAccountName
 Name of the storage account where restore configuration will be stored
.Parameter storageAccountRG
 Name of the Resource Group for the storage account
.Parameter targetSubnetName
 Name of the subnet used by retsored VM
.Parameter backupDateLookbackDays
 Number of day search for backup versions
.Parameter recoveryRGname
 Resource Group name where all recovered componenets will be stored


  
   
#>

#Requires -Modules @{ ModuleName="Az"; ModuleVersion="4.6.1" }
param(
    [Parameter(Madatory = $true)]
    [string]$vaultName,
    [Parameter(Madatory = $true)]
    [string]$vaultRG,
    [Parameter(Madatory = $true)]
    [string]$vmName,
    [Parameter(Madatory = $true)]
    [string]$targetVnetname,
    [Parameter(Madatory = $true)]
    [string]$newVMname,
    [Parameter(Madatory = $true)]
    [string]$storageAccountName ,
    [Parameter(Madatory = $true)]
    [string]$storageAccountRG ,
    [Parameter(Madatory = $true)]
    [string]$targetSubnetName ,
    [Parameter(Madatory = $true)]
    [int]$backupDateLookbackDays,
    [Parameter(Madatory = $true)]
    [string]$recoveryRGname

)



$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
#region Azure Automation Authentication

# comment this section out if running out side of Azure Automation
$connection = Get-AutomationConnection -Name AzureRunAsConnection
while (!($connectionResult) -and ($logonAttempt -le 10)) {
    $LogonAttempt++
    # Logging in to Azure...
    $connectionResult = Connect-AzAccount `
        -ServicePrincipal `
        -Tenant $connection.TenantID `
        -ApplicationId $connection.ApplicationID `
        -CertificateThumbprint $connection.CertificateThumbprint

    Start-Sleep -Seconds 30
}
#end region

#region Preparing envinroment 
Write-Information "Gathering VNET information"
$vnet = Get-AzVirtualNetwork -Name $targetVnetname

Write-Information "Setting up recovery location in $($vnet.Location) region to match VNET"
$recoveryRGlocation = $vnet.Location

Write-Information "Create recovery Resource Group"
New-AzResourceGroup -Name $recoveryRGName -Location $recoveryRGlocation -force | Out-Null
#endregion 

#region Collecting back up information 
Write-Information "Getting backup configuration data"
$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $vaultRG -Name $vaultName
$namedContainer = Get-AzRecoveryServicesBackupContainer  -ContainerType "AzureVM" -Status "Registered" -FriendlyName $vmName -VaultId $targetVault.ID
$backupitem = Get-AzRecoveryServicesBackupItem -Container $namedContainer  -WorkloadType "AzureVM" -VaultId $targetVault.ID

#setting up date for the oldesr back up set
$startDate = (Get-Date).AddDays(-$backupDateLookbackDays)
$endDate = Get-Date

Write-Information "getting backup instances from $($backupDateLookbackDays) day ago"
$rp = Get-AzRecoveryServicesBackupRecoveryPoint -Item $backupitem -StartDate $startdate.ToUniversalTime() -EndDate $enddate.ToUniversalTime() -VaultId $targetVault.ID
Write-Information "Found  $($rp.count) instances"
#endregion 
#region Executing Restore
Write-Information "Restoring with most recent backup instance"
$restorejob = Restore-AzRecoveryServicesBackupItem -RecoveryPoint $rp[0] -StorageAccountName $storageAccountName -StorageAccountResourceGroupName $storageAccountRG -TargetResourceGroupName $recoveryRGname -VaultId $targetVault.ID -VaultLocation $targetVault.Location

Write-Information "Restore job $($restorejob.id) started. Waiting on completion"
Wait-AzRecoveryServicesBackupJob -Job $restorejob -Timeout 43200 -VaultId $targetVault.ID

Write-Information "Restore job completed, getting details "
$restorejobData = Get-AzRecoveryServicesBackupJob -Job $restorejob -VaultId $targetVault.ID 
$details = Get-AzRecoveryServicesBackupJobDetails -Job $restorejobData -VaultId $targetVault.ID
#endregion
#region Collecting restore configuration
Write-Information "Obtaining restore configuration document propertise"
$containerName = $details.Properties["Config Blob Container Name"]
$configBlobname = $details.Properties["Config Blob Name"]
$destinationPath = "$($env:temp)\vmconfig.json"

Write-Information "Downloading and saving restore configuration"
Set-AzCurrentStorageAccount -Name $storageAccountName -ResourceGroupName $storageAccountRG 
Get-AzStorageBlobContent -Container $containerName -Blob $configBlobName -Destination $destinationPath -force 
$recoverySettings = ((Get-Content -Path $destinationPath -Raw -Encoding Unicode)).TrimEnd([char]0x00) | ConvertFrom-Json
#endregion

#region VM OS and StorageBuild
Write-Information "Configuring VM with size $($recoverySettings.'properties.hardwareProfile'.vmSize)"
$vm = New-AzVMConfig -VMSize $recoverySettings.'properties.hardwareProfile'.vmSize -VMName $newVMname

Write-Information "Setting up OS Disk configuration and adding to VM build data"
$OsDisk = Get-AzDisk -ResourceGroupName $recoveryRGName -Name $recoverySettings.'properties.StorageProfile'.osDisk.name
$vm = Set-AzVMOSDisk -VM $vm -ManagedDiskId $osDisk.Id -CreateOption Attach -Windows

Write-Information "Collecting Data Disk configuration and adding to VM build data"
foreach ($dd in $obj.'properties.StorageProfile'.DataDisks) {
    $disk = Get-AzDisk -ResourceGroupName $recoveryRGName  -DiskName $dd.name
    $vm = Add-AzVMDataDisk -CreateOption Attach -Lun $dd.lun -VM $vm -ManagedDiskId $disk.id
    Clear-Variable disk
}

#endregion
#region Creating VM Network configuration 
Write-Information "Setting virtual network data"
$vnet = Get-AzVirtualNetwork -Name $targetVnetname
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $targetSubnetName


#$pubNicName = "$($newVMName)$(get-date -UFormat %Y%m%d%I%M)PIP"
$nicName = "$($newVMName)$(get-date -UFormat %Y%m%d%I%M)NIC"
#$pip = New-AzPublicIpAddress -Name $pubNicName -ResourceGroupName $recoveryRGName  -Location $recoveryRGlocation  -AllocationMethod Dynamic

Write-Information "Creating a Network Card Resource"
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $recoveryRGName  -Location $recoveryRGlocation  -SubnetId $subnet.Id #-PublicIpAddressId $pip.Id

Write-Information "Setting up DNS servers 168.63.129.16 and 169.254.169.254 and updating NIC configuration"
$nic.DnsSettings.DnsServers.Add("168.63.129.16")
$nic.DnsSettings.DnsServers.Add("169.254.169.254")
$nic | Set-AzNetworkInterface
#endregion 

#region Creating VM
Write-Information "Linking network card to the VM Build data "
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id

Write-Information "Starting VM deployment"
New-AzVM -ResourceGroupName $recoveryRGName -Location $recoveryRGlocation -VM $vm -Verbose
#endregion

#region Post Build configuration

Write-Information "Saving remove from Domain and system rename script"
Set-Content -Path "$($env:TEMP)\temp.ps1" -Value "remove-computer -force`nrename-computer -newName $($newVMname)" -Force

write-Information "Running system rename script inside the vm"
Invoke-AzVMRunCommand -ResourceGroupName $recoveryRGname -VMName $newVMname -CommandId 'RunPowerShellScript' -ScriptPath "$($env:TEMP)\temp.ps1"

Write-Information "Clearing DNS settings back to production "
$nic.DnsSettings.DnsServers.Clear()
$nic | Set-AzNetworkInterface

Write-Information "Restarting VM for rename operation to complete"
Restart-AzVM -Name $newVMname -ResourceGroupName $recoveryRGname
#endregion


