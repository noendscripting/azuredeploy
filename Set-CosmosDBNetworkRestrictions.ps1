param(
    $VirtualNetworkName,
    $subnetName,
    [string[]]$IpAddress,
    $cosmosDBAccountname

)

#verify paremeters are not empty
If ([string]::IsNullOrEmpty($IpAddress) -and [string]::isNullorEmpty($VirtualNetworkName) -and [string]::isNullorEmpty($subnetName))
{
    Throw "Insufficent information provided. Can not proceed. Please set values for VirtualNetworkName and SubnetName or IpAddress in order to complete configuraton"
}

$cosmosDBAccountData = Get-AzCosmosDBAccount -Name $cosmosDBAccountname
#verify CosmosDB account exsts
if ([string]::IsNullOrEmpty($cosmosDBAccountData))
{
    Throw "Insufficent information provided. Can not proceed. Please provide a valid CosmosDB account"
}



$vnetData =  Get-AzVirtualNetwork -Name $VirtualNetworkName | out-null

#verify correct VNET, Subnet or IpAddress information is provided
if ([string]::IsNullOrEmpty($vnetData) -and [string]::IsNullOrEmpty($IpAddress))
{
    Throw "Insufficent information provided. Can not proceed. Please set values for VirtualNetworkName and SubnetName or IpAddress in order to complete configuraton"
}
else {
    Update-AzCosmosDBAccount -ResourceId $cosmosDBAccountData.Id -PublicNetworkAccess 'Disabled' -IpRule $IpAddress
    exit
}


#verify VNET and CosmosDB account are in the same region
if (!([string]::IsNullOrEmpty($vnetData))){
if ($vnetData.Location -ne $cosmosDBAccountData.Location)
{
    Throw "Unable to proceed Virtual Network must be in the same region as CosmosDB"
}

$subnetId = ($vnetData.Subnets | Where-Object {$_.Name -eq $subnetName}).id
if ([string]::IsNullOrEmpty($subnetId))
{
    Throw "Unable to proceed. Please provide a valid subnetName"
}

if ((($vnetData.subnets |  Where-Object {$_.Name -eq $subnetName}).ServiceEndpoints | Where-Object {$_.Service -eq 'Microsoft.AzureCosmosDB'}).count -ne 1)
{
    throw "Unable to proceed. Service endpoint 'Microsoft.AzureCosmosDB' does not exist in subnet $($subnetName). Please enable service endpoint before proceeding "
}
$vnetRule = New-AzCosmosDBVirtualNetworkRule -Id $subnetId
Update-AzCosmosDBAccount -ResourceId $cosmosDBAccountData.Id -PublicNetworkAccess 'Disabled' -IpRule @()
Update-AzCosmosDBAccount -ResourceId $cosmosDBAccountData.Id -PublicNetworkAccess 'Disabled' -EnableVirtualNetwork $true -VirtualNetworkRuleObject @($vnetRule)

}