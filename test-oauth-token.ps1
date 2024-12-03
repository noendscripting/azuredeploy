

$loginURl="login.microsoftonline.com"
$tennatId="d65b7371-c385-4060-8b4c-b6510616cb67"
#$tennatId="your tenant id"
$clinetId="57fad061-1cd8-4d53-b44f-35d306d8350d"
#$clinetId="your client id"
$clientSecret = "xuO8Q~E1bMmddBfU4kOAp4do0sFdJJd-6wbRKdhA"
#$clientSecret="your client secret"
#$scope=[System.Web.HTTPUtility]::UrlEncode("your client id/.default")
$scope=[System.Web.HTTPUtility]::UrlEncode("57fad061-1cd8-4d53-b44f-35d306d8350d/MyAppAccess")


$headers = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}
$uriString = "https://$($loginURl)/$($tennatId)/oauth2/v2.0/token"
$body = "client_id=$($clinetId)&scope=$($scope)&client_secret=$($clientSecret)&grant_type=client_credentials"
$result = Invoke-WebRequest -Uri $uriString -Method Post -Headers $headers -Body $body

Write-Output ($result.Content | ConvertFrom-Json -Depth 99).access_token