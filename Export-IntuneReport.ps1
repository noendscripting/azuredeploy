#Requires -Modules "Microsoft.Graph.Authentication"
#Requires -Version 7.1
param(
    $reportName='Devices',
    $saveReportLocation='c:\temp\myreport.csv',
    $appId = 'ecc181a9-d06a-482a-b124-bb538549316f',
    $tennatID = 'd65b7371-c385-4060-8b4c-b6510616cb67',
    $redirectURI = 'msal://redirect'
)

#Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -TenantId 'd65b7371-c385-4060-8b4c-b6510616cb67'  -ClientId 'ecc181a9-d06a-482a-b124-bb538549316f' 

# Getting Access Token

<#$loginURI = "https://login.microsoftonline.com/$($tennatID)/oauth2/v2.0/authorize?client_id=$($appId)&response_type=code&redirect_uri=$([System.Web.HTTPUtility]::UrlEncode($redirectURI))&response_mode=query&scope=DeviceManagementManagedDevices.Read.All&state=$(get-random -Maximum 10000000000)"
$loginURI
Invoke-WebRequest -Uri $loginURI

$tokenData

exit 
$requestBody = @"
{ 
    "reportName": "$($reportName)", 
}
"@

$orderreport = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs" -Body $requestBody -Method POST -OutputType PSObject

do {

    $verifyCompletion = $null
    $verifyCompletion = Invoke-MgGraphRequest -Uri  "https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs('$($orderreport.id)')" -Method GET -OutputType PSObject
    Start-Sleep -Seconds 30
    
} until ($verifyCompletion.status = 'completed')

Invoke-WebRequest -Method Get -Uri $verifyCompletion.url -OutFile $saveReportLocation#>
#$user = ""






####################################################

function Get-AuthToken {



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $User
)

$userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User

$tenant = $userUpn.Host

Write-Host "Checking for AzureAD module..."

    $AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null) {

        Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
        $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable

    }

    if ($AadModule -eq $null) {
        write-host
        write-host "AzureAD Powershell module not installed..." -f Red
        write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        write-host "Script can't continue..." -f Red
        write-host
        exit
    }

# Getting path to ActiveDirectory Assemblies
# If the module count is greater than 1 find the latest version

    if($AadModule.count -gt 1){

        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]

        $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }

            # Checking if there are multiple versions of the same module found

            if($AadModule.count -gt 1){

            $aadModule = $AadModule | select -Unique

            }

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

    else {

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
$CredPrompt = "Always"
$clientId = $appId
$redirectUri = $redirectUri
$resourceAppIdURI = 'https://graph.microsoft.com'
$authority = "https://login.microsoftonline.com/$tennatID"

    try {

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
    # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters"   -ArgumentList $CredPrompt

    $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")

    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result



    #Adding some error checking async request
do {
    write-host $authResult.Status
    start-sleep -Seconds 5
} while ($authResult.Status -eq "WaitingForActivation")


if ($authResult.Status -eq "Faulted") {
    $authResult.Exception | select *
    write-host "error encountered terminating script"
    exit
}

        # If the accesstoken is valid then create the authentication header

        if($authResult.AccessToken){

        # Creating header for Authorization token

        $authHeader = @{
            'Content-Type'='application/json'
            'Authorization'="Bearer " + $authResult.AccessToken
            'ExpiresOn'=$authResult.ExpiresOn
            }

        return $authHeader

        }

        else {

        Write-Host
        Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
        Write-Host
        break

        }

    }

    catch {

    write-host $_.Exception.Message -f Red
    write-host $_.Exception.ItemName -f Red
    write-host
    break

    }

}

####################################################



Write-Host "####################################################"

#region Authentication

write-host

# Checking if authToken exists before running authentication
if($global:authToken){

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

            # Defining User Principal Name if not present

            if($User -eq $null -or $User -eq ""){

            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

            }

        $global:authToken = Get-AuthToken -User $User

        }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    if($User -eq $null -or $User -eq ""){

    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host

    }

# Getting the authorization token
$global:authToken = Get-AuthToken -User $User

}

#endregion


$orderreport = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs" -Body $requestBody -Method POST -Headers $global:authToken

do {

    $verifyCompletion = $null
    $verifyCompletion = Invoke-RestMethod -Uri  "https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs('$($orderreport.id)')" -Method GET -Headers $global:authToken
    Start-Sleep -Seconds 30
    
} until ($verifyCompletion.status = 'completed')

Invoke-WebRequest -Method Get -Uri $verifyCompletion.url -OutFile $saveReportLocation

