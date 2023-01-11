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


# Below are samples for multiple options to retrieve Graph Data. This is not intended to run as a script

#region Manual Applkication Non Interactive flow no ADAL\MSAL

$uri = "https://login.microsoftonline.com/d65b7371-c385-4060-8b4c-b6510616cb67/oauth2/v2.0/token"
$clinet_id = #<clkient id of the service principal>
$client_secret = #<value of the secret kiey of the servcie principal'
$scope = [System.Web.HTTPUtility]::UrlEncode("https://graph.microsoft.com/.default")


#Creating header for Access Token request
$tokenRequestQueryHeaders =@{
    ContentType = "application/x-www-form-urlencoded"
}


#creating request body for Access Token request
$body = "client_id=$($clinet_id)&scope=$($scope)&client_secret=$($client_secret)&grant_type=client_credentials"

Write-Verbose $body

#Call auth enpoint to get Access Token
$result = Invoke-RestMethod -Uri $uri -Body $body -Method Post -Headers $

#Create Authorization Header using Access Token received in the step one

$queryHeaders = @{
    Authorization = "Bearer $($result.access_token)"

}


$resultQuery = (Invoke-WebRequest -Headers $queryHeaders -Uri "https://graph.microsoft.com/v1.0/groups?$filter=onPremisesSyncEnabled ne true").Content
$resultQuery







