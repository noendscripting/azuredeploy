param(
   
    
    [Parameter(Mandatory=$true)]
    [string[]]$permissionId,
    [string]$resourceAppId = '00000003-0000-0000-c000-000000000000'
)


$resourceAppObjId = (Get-MgServicePrincipal -Filter "appid eq '$($resourceAppId)'").Id

Get-MgServicePrincipal -ServicePrincipalId $resourceAppObjId  | Select-Object -ExpandProperty AppRoles | ?{$_.Id -eq $permissionId} | select Value,Description | Format-List