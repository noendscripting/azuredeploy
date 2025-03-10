count=55

$currentDomain = Get-ADDomain -Current LocalComputer
for ($i=0; $i -lt $count; $i++)
{
    $users = (invoke-webrequest -UseBasicParsing "https://randomuser.me/api/?results=5000&inc=name,location,cell").Content | convertfrom-json -Depth 99

    foreach($user in $users.results)
    {
        $ou = (Get-ADOrganizationalUnit -Filter {Name -eq "$($user.location.country)"} -SearchBase $currentDomain.DistinguishedName -searchscope subtree  -ErrorAction SilentlyContinue).DistinguishedName
        if ([string]::IsNullOrEmpty($ou))
        {
            $ou = New-ADOrganizationalUnit -Name "$($user.location.country)" -Path "OU=Company Users,$($currentDomain.DistinguishedName)"
        }
    
        
        $ADUser = New-Object psobject -Property @{
            GivenName = $user.name.first
            Surname = $user.name.last
            Initials = $user.name.first.substring(0,1) + $user.name.last.substring(0,1)
            DisplayName = "$($user.name.first.substring(0,1)) $($user.name.last)"
            Name = "$($user.name.first) $($user.name.last)"
            SamAccountName = "$($user.name.first)$($user.name.last)"
            UserPrincipalName = "$($user.name.first)$($user.name.last)"
            City = $user.location.city
            Country = $user.location.country
            MobilePhone = $user.cell
            State = $user.location.state
            Title = $user.name.title
            Path = $ou
        }

        New-ADUser @ADUser -AccountPassword (ConvertTo-SecureString "passw@rd1" -AsPlainText -Force) -PasswordNeverExpires $True -ChangePasswordAtLogon $False -Enabled $True
    }

}



#GivenName,Surname,Initials,DisplayName,Name,SamAccountName,UserPrincipalName,AccountPassword,Path