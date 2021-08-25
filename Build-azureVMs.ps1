$Password = ConvertTo-SecureString -AsPlainText -Force "Test@2016"

"test1", "test2", "test3" | % {  $parameters = @{

        "Name"                   = "DeleteVmtest$($psItem)"
        "ResourceGroupName"      = 'DeleteTest-RG'
        "TemplateFile"           = 'c:\gitrepo\azuredeploy\vm-base.json'
        "virtualMachineName"     = $psItem
        "virtualMachineLongname" = $psItem 
        "VNETResourceGroup"      = 'Network-RG-WestUS'
        "adminUsername"          = 'vadmin'
        "nicType"                = 'Public'
        "VNET"                   = 'BaseVnet-WestUS'
        "subnetName"             = 'FirstSubnetWest'
        "sku"                    = "2019-Datacenter"
        "adminPassword"          = $Password
    }
    New-AzResourceGroupDeployment -AsJob @parameters

}
    
