<#
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
#>


#Setting up requirments for script to run
#Requires -Version 5.0
#Requires -Modules @{ ModuleName="AzureAD"; ModuleVersion="2.0.2.16"}


$resourceAppIdURI = "https://mrs-prod.ame.gbl/mrs-RDInfra-prod" #This will tell Azure AD which reosurce we are trying to access
$ClientID = "fa4345a4-a730-4230-84a8-7d9651b86739"   #AKA Application ID
$TenantName = "amrtoday.onmicrosoft.com"             #Your Tenant Name
$CredPrompt = "Auto"                                   #Auto, Always, Never, RefreshSession
$redirectUri = "https://mrs-prod.ame.gbl/mrs-RDInfraClient-prod"                #Your Application's Redirect URI
$Uri = 'https://rdbroker.wvd.microsoft.com/RdsManagement/V1/TenantGroups/Default Tenant Group/Tenants' #The query you want to issue to Invoke a REST command with. 
#You can use look up Graph Api refrence for examples of  URIs searching for single user or selecting specific properties
$Method = "Get"                                    #GET 
#JSON is listed as an example if you decide to use PUT or PATCH methods via API. You will need to pass $JSON into body parament in Invoke-RestMethod
$JSON = @" 
    {
    "userPrincipalName": "MCC-MigAdmin01@cloudlojik.onmicrosoft.com"
    }
"@ 
#Aquiring Access tocken

if (!$CredPrompt) { $CredPrompt = 'Auto' } # verifying authenticaction setting
$AadModule = Get-Module -Name "AzureAD" -ListAvailable # getting list of all AzureAD modules

#Selectting latest verion of the ADAL library if multiple AzureAD modules found
if ($AadModule.count -gt 1) {
    $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
    $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }
    $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
}
else {
    $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
}
#Loading ADAL libriaries
[System.Reflection.Assembly]::LoadFrom($adal) #| Out-Null
[System.Reflection.Assembly]::LoadFrom($adalforms) #| Out-Null

#Creating Authentication context and parameters
$authority = "https://login.microsoftonline.com/$TenantName"
$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
$platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters"    -ArgumentList $CredPrompt

#Sending  async authentication request and saving in a variable
$authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters).Result

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
 
#Querying Azure AD

Write-Progress -Id 1 -Activity "Executing query: $Uri" -CurrentOperation "Invoking ARM REST API"
#Creating request header
$Header = @{
    'Content-Type'  = 'application\json'
    'Authorization' = $authResult.CreateAuthorizationHeader()
}

$QueryResults = @()
# Do loop for receiving Get query results
if ($Method -eq "Get") {
    do {
                        
        #Send Get Rest requests untill all data retrieved
        $Results = Invoke-RestMethod -Headers $Header -Uri $Uri -UseBasicParsing -Method $Method -ContentType "application/json"
           
        if ($Results.value -ne $null) { $QueryResults += $Results.value }
        else { $QueryResults += $Results }
        write-host "Method: $Method | URI $Uri | Found:" ($QueryResults).Count

        $uri = $Results.'@odata.nextlink'
    }until ($uri -eq $null)

            
            
}
#Example of patch method
if ($Method -eq "Patch") {
    #Example of patch requets
    $Results = Invoke-RestMethod -Headers $Header -Uri $Uri -Method $Method -ContentType "application/json" -Body $Body
    write-host "Method: $Method | URI $Uri | Executing"
}

#Exit progress bar and display results in the shell console
Write-Progress -Id 1 -Activity "Executing query: $Uri" -Completed

Return $QueryResults

