# Specifies a path to one or more locations. Wildcards are permitted.
param(
    # Parameter help description
    # Specifies a path to one or more locations.
    [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,message="Distnguished name of the OU for MDI account to disable users.")]
    [ValidateNotNullOrEmpty()]
    [string]$adObjectDN,
    [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true,message="Distnguished name of the OU for MDI account to disable users.")]
    [ValidateNotNullOrEmpty()]
    [string]$mdiUser


)



$mdiUser = 'litware\mdisvc02$'
$daclSwitches = "/I:S /G" 


dsacls $adObjectDN $daclSwitches "$($mdiUser):CA;Reset password;user"
dsacls $adObjectDN $daclSwitches "$($mdiUser):RP;pwdLastSet;user"
dsacls $adObjectDN $daclSwitches "$($mdiUser):WP;pwdLastSet;user"
dsacls $adObjectDN $daclSwitches "$($mdiUser):RP;userAccountControl;user"
dsacls $adObjectDN $daclSwitches "$($mdiUser):WP;userAccountControl;user"
dsacls $adObjectDN $daclSwitches "$($mdiUser):RP;member;group"
dsacls $adObjectDN $daclSwitches "$($mdiUser):WP;member;group"