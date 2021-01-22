
$uri = "https://login.microsoftonline.com/d65b7371-c385-4060-8b4c-b6510616cb67/oauth2/v2.0/token"
$username = 'engineer@azurenow.onmicrosoft.com'
$password = "Greencar16"
$clinet_id = '4fa10f26-0baf-441d-bc3c-9deb37d880e0'
#$clinet_id = 'a9a6c770-d636-4d9e-a4bd-72fe1db8ab28'
#$scope = 'EntitlementManagement.Read.All'
$scope = [System.Web.HTTPUtility]::UrlEncode("https://graph.microsoft.com/.default")

$tokenRequestQueryHeaderss =@{
    ContentType = "application/x-www-form-urlencoded"
}


$body = "client_id=$($clinet_id)&scope=$($scope)&username=$($username)&password=$($password)&grant_type=password"

Write-Host $body
$result = Invoke-RestMethod -Uri $uri -Body $body -Method Post -Headers $tokenRequestQueryHeaderss

$queryHeaders = @{
    Authorization = "Bearer $($result.access_token)"

}
Invoke-RestMethod -Headers $queryHeaders -Uri "https://graph.microsoft.com/beta/privilegedAccess/aadroles/resources/d65b7371-c385-4060-8b4c-b6510616cb67/roleSettings"

#$hash = Get-AzureADServicePrincipal -filter "appid eq '00000003-0000-0000-c000-000000000000'" | select -ExpandProperty AppRoles | group id -AsHashTable -AsString


$Token = ([Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::AccessTokens['AccessToken']).AccessToken