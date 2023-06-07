<#
.SYNOPSIS  
    The script is deisgned collecting user Authentictaion Methods details repert from Azure AD
.DESCRIPTION
 Scripty will collect all users registered for Windows Hello For Business  or any other method and export them to CSV file. paramater -allMethods will export all users registered for any method.
DISCLAIMER
    THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
    We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object
    code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software
    product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the
    Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims
    or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
    Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained within
    the Premier Customer Services Description.
.PARAMETER MfaType
    Type of MFA method to export. Default is WindowsHelloForBusiness
.PARAMETER allMethods
    Switch to export all users registered for any method
.EXAMPLE
    .\create-AADWH4BRegisteredUsers.ps1 -MfaType "securityQuestion"
    get all the users registered for security question
.EXAMPLE
    .\create-AADWH4BRegisteredUsers.ps1 -allMethods
    get all the users registered for any method
#>

[CmdletBinding()]
param (
    [ValidateSetAttribute("temporaryAccessPass",
    "softwareOneTimePasscode",
    "securityQuestion",
    "officePhone",
    "mobilePhone",
    "microsoftAuthenticatorPasswordless",
    "microsoftAuthenticatorPush",
    "hardwareOneTimePasscode",
    "fido2SecurityKey",
    "alternateMobilePhone",
    "email",
    "WindowsHelloForBusiness")]
    [string]$MfaType = "WindowsHelloForBusiness",
    [switch]$allMethods
)


Connect-MgGraph -Scopes "Policy.Read.All","Reports.Read.All","AuditLog.Read.All","Directory.Read.All","Directory.Read.All","User.Read.All","AuditLog.Read.All","IdentityRiskyUser.Read.All","IdentityRiskEvent.Read.All","Reports.Read.All","UserAuthenticationMethod.Read.All","AuditLog.Read.All"


write-host "Exporting users registered for Windows Hello For windowsHelloForBusiness, this may take a while"

if ($allMethods)
{
    $uri = "https://graph.microsoft.com/beta/reports/authenticationMethods/userRegistrationDetails?"
}
else {
    $uri = "https://graph.microsoft.com/beta/reports/authenticationMethods/userRegistrationDetails?$filter=methodsRegistered/any(s:s eq '$($MfaType)')"
}
    do{
        $results = $null
        $output = @()
        for($i=0; $i -le 3; $i++){
            try{
                $results = Invoke-MgGraphRequest -Uri $uri -Method GET -OutputType PSObject
                break
            }catch{#if this fails it is going to try to authenticate again and rerun query
                if(($_.Exception.response.statuscode -eq "TooManyRequests") -or ($_.Exception.Response.StatusCode.value__ -eq 429)){
                    #if this hits up against to many request response throwing in the timer to wait the number of seconds recommended in the response.
                    write-host "Error: $($_.Exception.response.statuscode), trying again $i of 3"
                    Start-Sleep -Seconds $_.Exception.response.headers.RetryAfter.Delta.seconds
                }
            }
        }
        #formatting registered methods results to be more readable
        foreach($result in $results.value){
            if ($result.methodsRegistered -ne [System.DBNull]::Value -and $result.methodsRegistered -ne $null)
            {
              
                $result | Add-Member -MemberType NoteProperty -Name "methodsRegistered" -Value ($result.methodsRegistered -join ",") -Force
            }
            else {
                $result | Add-Member -MemberType NoteProperty -Name "methodsRegistered" -Value "None" -Force
            }
            $output += $result
        }

    
        $uri = $Results.'@odata.nextlink'
        Write-Verbose "Next Link: $uri"
        $output |Export-Csv .\wh4bregistered.csv -NoTypeInformation -ErrorAction Continue -Append
    }until ([string]::isNullOrEmpty($uri)) # if there is no next link it will break out of the loop

