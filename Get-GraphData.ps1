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



$uri = "https://login.microsoftonline.com/d65b7371-c385-4060-8b4c-b6510616cb67/oauth2/v2.0/token"
$username = 'engineer@azurenow.onmicrosoft.com'
$password = "Greencar16"
$clinet_id = '4fa10f26-0baf-441d-bc3c-9deb37d880e0'
#$clinet_id = 'a9a6c770-d636-4d9e-a4bd-72fe1db8ab28'
$client_secret = 'X~_IkB22kcpSR5PqX6kcQr7u9L-61C1n.y'
#$scope = 'EntitlementManagement.Read.All'
$scope = [System.Web.HTTPUtility]::UrlEncode("https://graph.microsoft.com/.default")

$tokenRequestQueryHeaderss =@{
    ContentType = "application/x-www-form-urlencoded"
}


#$body = "client_id=$($clinet_id)&scope=$($scope)&username=$($username)&password=$($password)&grant_type=password"
$body = "client_id=$($clinet_id)&scope=$($scope)&client_secret=$($client_secret)&grant_type=client_credentials"

Write-Host $body
$result = Invoke-RestMethod -Uri $uri -Body $body -Method Post -Headers $tokenRequestQueryHeaderss

$queryHeaders = @{
    Authorization = "Bearer $($result.access_token)"

}


#$resultQuery = (Invoke-WebRequest -Headers $queryHeaders -Uri "https://graph.microsoft.com/v1.0/groups?$filter=onPremisesSyncEnabled ne true").Content
(Invoke-RestMethod -Headers $queryHeaders -Uri "https://graph.microsoft.com/v1.0/groups?$filter=onPremisesSyncEnabled ne true").value
#$resultQuery = (Invoke-RestMethod -Headers $queryHeaders -Uri "https://graph.microsoft.com/v1.0/groups?$filter=onPremisesSyncEnabled ne true").Content
#$resultQuery

#$hash = Get-AzureADServicePrincipal -filter "appid eq '00000003-0000-0000-c000-000000000000'" | select -ExpandProperty AppRoles | group id -AsHashTable -AsString




