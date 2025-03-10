param(
    [string]$vmName,
    [string]$vmPath = "E:\VM",
    [string]$isoPath,
    [string]$diskSize = "32GB",
    [string]$memory = "8GB",
    [string]$cpuCount = "2"
)


# Create VM
New-VM -Name $vmName -MemoryStartupBytes $memory -Generation 2 -Path $vmPath

# Set CPU count
Set-VMProcessor -VMName $vmName -Count $cpuCount

# Add virtual hard disk
New-VHD -Path "$vmPath\$vmName.vhdx" -SizeBytes $diskSize
Add-VMHardDiskDrive -VMName $vmName -Path "$vmPath\$vmName.vhdx"

# Add ISO as DVD drive
Add-VMDvdDrive -VMName $vmName -Path $isoPath

# Enable TPM
Set-VMFirmware -VMName $vmName -EnableSecureBoot On
Enable-VMTPM -VMName $vmName

# Set boot order to boot from DVD
Set-VMFirmware -VMName $vmName -FirstBootDevice (Get-VMDvdDrive -VMName $vmName)

# Start VM
Start-VM -Name $vmName