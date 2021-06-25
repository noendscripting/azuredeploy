#Requires -Modules @{ ModuleName="Microsoft.Graph.Applications"; ModuleVersion="1.6.0"}
#Requires -Modules @{ ModuleName="Microsoft.Graph.Authentication"; ModuleVersion="1.6.0"}

param(
   
    [Parameter(Mandatory=$true)]
    [string]$targetAppId,
    [Parameter(Mandatory=$true)]
    [string[]]$permissions,
    [string]$resourceAppId = '00000003-0000-0000-c000-000000000000'
)

Connect-MgGraph -Scopes Directory.AccessAsUser.All

$resourceAppObjId = (Get-MgServicePrincipal -Filter "appid eq '$($resourceAppId)'").Id
$targetAppObjId = (Get-MgServicePrincipal -Filter "appid eq '$($targetAppId)'").Id


foreach($permission in $permissions)
{
    $permissioinId = ((Get-MgServicePrincipal -ServicePrincipalId $resourceAppObjId  | Select-Object -ExpandProperty AppRoles | Group-Object Value -AsHashTable -AsString)[$permission]).id
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $targetAppObjId -AppRoleId $permissioinId -PrincipalId $targetAppObjId -ResourceId $resourceAppObjId
    Clear-Variable permissioinId
}