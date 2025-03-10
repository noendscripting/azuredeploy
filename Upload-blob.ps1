param(
    [string]$storageAccountname,
    [string]$containerName,
    [string]$localFile
)

$blobName = (Get-Item $localFile).Name
$ctx = New-AzStorageContext -StorageAccountName $storageAccountname -UseConnectedAccount
Set-AzStorageBlobContent -Container $containerName -File $localFile -Context $ctx -Blob $blobName -Verbose
