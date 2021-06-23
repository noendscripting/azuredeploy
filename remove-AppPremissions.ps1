param( 
    [Parameter(Mandatory=$true)]
    [string]$targetAppId
)

Connect-MgGraph -Scopes AppRoleAssignment.ReadWrite.All


$targetAppObjId = (Get-MgServicePrincipal -Filter "appid eq '$($targetAppId)'").Id
$approleIds= (Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $targetAppObjId).Id
if ($approleIds)
{
    foreach ($appRoleID in $approleIds)
    {
        Remove-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $targetAppObjId -AppRoleAssignmentId $approleId

    }

}
 

 