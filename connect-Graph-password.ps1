
$uri = "https://login.microsoftonline.com/d65b7371-c385-4060-8b4c-b6510616cb67/oauth2/v2.0/token"
#$username = 'dailyuser@azurenow.win'
#$password = "Greencar17"
$clinet_id = 'ecc181a9-d06a-482a-b124-bb538549316f'
$client_secret = 'UDP8Q~Ff6dt.hxJ0sbjRtxVGgxTQCmZmcnf6pb6E'
$queryURI = 'https://graph.microsoft.com/v1.0/applications/?$select=id,displayName&$count'
$scope = [System.Web.HTTPUtility]::UrlEncode("https://graph.microsoft.com/.default")
#Generating header values
$tokenRequestQueryHeaderss =@{
    ContentType = "application/x-www-form-urlencoded"
}

#Create body to pass when requesting access token
$body = "client_id=$($clinet_id)&scope=$($scope)&client_secret=$($client_secret)&grant_type=client_credentials"

#$body = "client_id=$($clinet_id)&scope=$($scope)&username=$($username)&password=$($password)&grant_type=password"


#Send a post request to obtain bearer token
$result = Invoke-RestMethod -Uri $uri -Body $body -Method Post -Headers $tokenRequestQueryHeaderss


$queryHeaders = @{
    Authorization = "Bearer $($result.access_token)"

}
#Generate Header for query by adding Access Token obtained earlier
$queryHeaders = @{
    Authorization = "Bearer $($result.access_token)"
}

#Send request 
$queryResult = (Invoke-RestMethod -Headers $queryHeaders -Body $body -Uri $queryURI  -Method Get).value

$queryResult