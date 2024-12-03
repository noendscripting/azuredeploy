

$loginURl="login.microsoftonline.com"
$tennatId="your tenant id"
$clinetId="your client id"
$clientSecret="your client secret"
$scope=[System.Web.HTTPUtility]::UrlEncode("your client id/.default")


$headers = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}
$uriString = "https://$($loginURl)/$($tennatId)/oauth2/v2.0/token"
$body = "client_id=$($clinetId)&scope=$($scope)&client_secret=$($clientSecret)&grant_type=client_credentials"
$result = Invoke-WebRequest -Uri $uriString -Method Post -Headers $headers -Body $body

Write-Output ($result.Content | ConvertFrom-Json -Depth 99).access_token