
$uri = "https://login.microsoftonline.com/d65b7371-c385-4060-8b4c-b6510616cb67/oauth2/v2.0/token"
$username = 'dailyuser@azurenow.win'
$password = "Greencar16"
$clinet_id = 'ecc181a9-d06a-482a-b124-bb538549316f'
#$clinet_id = 'a9a6c770-d636-4d9e-a4bd-72fe1db8ab28'
#$scope = 'EntitlementManagement.Read.All'
$scope = [System.Web.HTTPUtility]::UrlEncode("https://graph.microsoft.com/.default")

$tokenRequestQueryHeaderss =@{
    ContentType = "application/x-www-form-urlencoded"
}


$body = "client_id=$($clinet_id)&scope=$($scope)&username=$($username)&password=$($password)&grant_type=password"

$result = Invoke-RestMethod -Uri $uri -Body $body -Method Post -Headers $tokenRequestQueryHeaderss

$queryHeaders = @{
    Authorization = "Bearer $($result.access_token)"

}
Invoke-RestMethod -Headers $queryHeaders -Uri "https://graph.microsoft.com/beta/identityGovernance/entitlementManagement/accessPackages"