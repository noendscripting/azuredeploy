param(
    [Parameter(Madatory = $true)]
    [string]$vaultName = "MainVault",
    [Parameter(Madatory = $true)]
    [string]$vaultRG = 'BaseLab',
    [Parameter(Madatory = $true)]
    [string]$vmName = "IIS",
    [Parameter(Madatory = $true)]
    [string]$vnetName = "VNET02",
    [Parameter(Madatory = $true)]
    [string]$newVMname = "IISbkupTest",
    [Parameter(Madatory = $true)]
    [string]$vmRG = "BaseLab",
    [Parameter(Madatory = $true)]
    [string]$storageAccountName = "101baselabstore",
    [Parameter(Madatory = $true)]
    [string]$storageAccountRG = "Baselab",
    [Parameter(Madatory = $true)]
    [string]$subnetName = "FrontEndSubnet",
    [Parameter(Madatory = $true)]
    [int]$backupDateLookbackDays = 1,
    [Parameter(Madatory = $true)]
    [string]$recoveryRGname = "BMcDPOC"

)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

Write-Information "Gathering VNET information"
$vnet = Get-AzVirtualNetwork -Name $vnetName
Write-Information "Settinh up recovery location in $($vnet.Location) region to match VNET"
$recoveryRGlocation = $vnet.Location
Write-Information "Create recovery Resource Group"
New-AzResourceGroup -Name $recoveryRGName -Location $recoveryRGlocation -force | Out-Null

Write-Information "Getting backup configuration data"
$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $vaultRG -Name $vaultName
$namedContainer = Get-AzRecoveryServicesBackupContainer  -ContainerType "AzureVM" -Status "Registered" -FriendlyName $vmName -VaultId $targetVault.ID
$backupitem = Get-AzRecoveryServicesBackupItem -Container $namedContainer  -WorkloadType "AzureVM" -VaultId $targetVault.ID


$startDate = (Get-Date).AddDays(-$backupDateLookbackDays)
$endDate = Get-Date
Write-Information "getting backup instances from $($backupDateLookbackDays) day ago"
$rp = Get-AzRecoveryServicesBackupRecoveryPoint -Item $backupitem -StartDate $startdate.ToUniversalTime() -EndDate $enddate.ToUniversalTime() -VaultId $targetVault.ID
write-InWrite-Information "Found  $($rp.count) instances"

Write-Information "Restoring with most recent backup instance"
$restorejob = Restore-AzRecoveryServicesBackupItem -RecoveryPoint $rp[0] -StorageAccountName $storageAccountName -StorageAccountResourceGroupName $storageAccountRG -TargetResourceGroupName $recoveryRGname -VaultId $targetVault.ID -VaultLocation $targetVault.Location   
Write-Information "Restore job $($restorejob.id) started. Waiting on completion"
Wait-AzRecoveryServicesBackupJob -Job $restorejob -Timeout 43200 -VaultId $targetVault.ID
$restorejobData = Get-AzRecoveryServicesBackupJob -Job $restorejob -VaultId $targetVault.ID 
Write-Information "Restore job completed, checking details "
$details = Get-AzRecoveryServicesBackupJobDetails -Job $restorejobData -VaultId $targetVault.ID


Write-Information "Obtaining retsore configuration document and setting deployent parameters"
$containerName = $details.Properties["Config Blob Container Name"]
$configBlobname = $details.Properties["Config Blob Name"]
$destinationPath = "$($env:temp)\vmconfig.json"
Set-AzCurrentStorageAccount -Name $storageAccountName -ResourceGroupName $storageAccountRG 
#$configBlobFullURI = New-AzStorageBlobSASToken -Container $containerName -Blob $configBlobname  -Permission r -FullUri


Get-AzStorageBlobContent -Container $containerName -Blob $configBlobName -Destination $destinationPath -force 
$recoverySettings = ((Get-Content -Path $destinationPath -Raw -Encoding Unicode)).TrimEnd([char]0x00) | ConvertFrom-Json


$vm = New-AzVMConfig -VMSize $recoverySettings.'properties.hardwareProfile'.vmSize -VMName $newVMname
$OsDisk = Get-AzDisk -ResourceGroupName $recoveryRGName -Name $recoverySettings.'properties.StorageProfile'.osDisk.name
$vm = Set-AzVMOSDisk -VM $vm -ManagedDiskId $osDisk.Id -CreateOption Attach -Windows

foreach ($dd in $obj.'properties.StorageProfile'.DataDisks) {
    $disk = Get-AzDisk -ResourceGroupName $recoveryRGName  -DiskName $dd.name
    $vm = Add-AzVMDataDisk -CreateOption Attach -Lun $dd.lun -VM $vm -ManagedDiskId $disk.id
    Clear-Variable disk
}

write-InWrite-Information "Setting virtual network data"
$vnet = Get-AzVirtualNetwork -Name $vnetName
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName

$pubNicName = "$($newVMName)$(get-date -UFormat %Y%m%d%I%M)PIP"
$nicName = "$($newVMName)$(get-date -UFormat %Y%m%d%I%M)NIC"
$pip = New-AzPublicIpAddress -Name $pubNicName -ResourceGroupName $recoveryRGName  -Location $recoveryRGlocation  -AllocationMethod Dynamic
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $recoveryRGName  -Location $recoveryRGlocation  -SubnetId $subnet.Id -PublicIpAddressId $pip.Id
$nic.DnsSettings.DnsServers.Add("168.63.129.16")
$nic.DnsSettings.DnsServers.Add("169.254.169.254")
$nic | Set-AzNetworkInterface
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id


Write-Information "Creating VM"
New-AzVM -ResourceGroupName $recoveryRGName -Location $recoveryRGlocation -VM $vm -Verbose


Write-Information "Saving system rename script"

Set-Content -Path "$($env:TEMP)\temp.ps1" -Value "remove-computer -force`nrename-computer -newName $($newVMname)" -Force

write-InWrite-Information "Running system rename script inside the vm"
Invoke-AzVMRunCommand -ResourceGroupName $recoveryRGname -VMName $newVMname -CommandId 'RunPowerShellScript' -ScriptPath "$($env:TEMP)\temp.ps1"

Write-Information "Clearing DNS settings back to production "

$nic.DnsSettings.DnsServers.Clear()
$nic | Set-AzNetworkInterface

write-InWrite-Information "Restarting VM for rename operation to complete"
Restart-AzVM -Name $newVMname -ResourceGroupName $recoveryRGname



