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

    [CmdletBinding()]
    param (
        $GraphEndpoint = 'https://graph.microsoft.com/v1.0/users?$top=5',
        $maxResults = 1000,
        $TimeLimitHours = 1
    )
$tenantId = '9dd7796e-60f8-47be-a0e4-c407efe3201c'
$uri = "https://login.microsoftonline.com/$($tenantId)/oauth2/v2.0/token"
$clinet_id = '59961cba-0ff3-487c-9376-215ea0a9e5ff'
$client_secret = 'vm68Q~a.ofGMJiPwdOGkpk1mS4xgUTdw~p6tXcQD'
$scope = [System.Web.HTTPUtility]::UrlEncode("https://graph.microsoft.com/.default")
#$scope = "api://6998b17f-4cf5-4235-931d-0e22076b0ac0/.default"

Function Get-GraphAccessToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$signinURI,
        [Parameter(Mandatory = $true)]
        [string]$appid,
        [Parameter(Mandatory = $true)]
        [string]$Secret,
        [Parameter(Mandatory = $true)]
        [string]$clientscope
        
    )
    
    
    
#Creating header for Access Token request
$tokenRequestQueryHeaders =@{
    ContentType = "application/x-www-form-urlencoded"
}


#creating request body for Access Token request
$body = "client_id=$($appid)&scope=$($clientscope)&client_secret=$($secret)&grant_type=client_credentials"

Write-Verbose $body

#Call auth enpoint to get Access Token
$result = Invoke-RestMethod -Uri $signinURI -Body $body -Method Post -Headers $tokenRequestQueryHeaders
return $result.access_token
}
#Create Authorization Header using Access Token received in the step one

<#$queryHeaders = @{
    Authorization = "Bearer $($result.access_token)"

}#>

$authAttempts = 0
    $index = 0
    $spinner = @('|', '/', '-', '\')
    $InformationPreference = "Continue"
    $ErrorActionPreference = "Continue"
    $startTime = Get-Date
    $queryURI = $GraphEndpoint
    $outputData = @()
    $accessToken = Get-GraphAccessToken -signinURI $uri -appid $clinet_id -Secret $client_secret -clientscope $scope
    
    if ($null -eq $accessToken) {
        Write-Error "Failed to obtain access token."
        return $Error[0]
    }
    else {
        $queryHeaders = @{
            Authorization = "Bearer $($accessToken)"
            ConsistencyLevel = "eventual"
        
        }
    }
    while (!([string]::IsNullOrEmpty($queryURI))) {
        Write-Host "Current results count: $($outputData.Count)"
        if((New-TimeSpan -Start $startTime  -end (get-date)).Hours -gt $TimeLimitHours){
            Write-Information "Terminating script after set time"
            $queryURI = $null
            continue
        }
        elseif ($outputData.Count -ge $maxResults) {
            Write-Information "Max results reached. Terminating script"
            $queryURI = $null
            continue 
        }
        
        try {
            
            $queryResult = Invoke-RestMethod -Headers $queryHeaders -Body $body -Uri $queryURI  -Method Get 
            $outputData +=  $queryResult.value
            $queryURI = $queryResult.'@odata.nextLink'
            Write-Host -NoNewline -ForegroundColor Green ("`r" + $spinner[$index])
            $index = ($index + 1) % $spinner.Length
            
           
            
        } 
        catch [Microsoft.PowerShell.Commands.HttpResponseException]
         {
            switch ($_.Exception.response.StatusCode) {
                "TooManyRequests" {
                    Write-Information "TooManyRequests Throtling triggered. Waiting for $($_.Exception.response.Headers.RetryAfter) seconds"
                    start-sleep -Seconds  $_.Exception.response.Headers.RetryAfter
                  }
                  "Unauthorized" {
                    Write-Error $_.Exception.response.StatusCode
                    Write-Information $Error[0].Exception.response.StatusCode
                    Write-Information "Token expired, generating new token"
                    if ($authAttempts -le 5) {
                        $authAttempts++
                        $result = Get-GraphAccessToken -AssessmentId $AssessmentId
                        $queryHeaders = @{
                            Authorization = "Bearer $($result)"
                            ConsistencyLevel = "eventual"
                        }
                    }
                    else {
                        Write-Error "Failed to obtain valid access token after multiple attempts."
                        return $Error[0]
                    }
                  }
                  "BadRequest" {
                    Write-Information "BadRequest. Rewrite URI before retrying terminating script"
                    $queryURI = $null
                    
                  }
                  "Request_UnsupportedQuery" {
                    Write-Information "Request_UnsupportedQuery. Rewirte URI beofre retrying terminating script"
                    $queryURI = $null
                    
                  }
                  "Forbidden" {
                    Write-Information "$(($Error[0].ErrorDetails.Message | ConvertFrom-Json).error.message).Terminating script"
                    $queryURI = $null
                    
                  } 
                Default {
                    Write-Information $Error[0].ErrorDetails.Message
                    Write-Information $Error[0].Exception.response.StatusCode
                    $queryURI = $null
                }
            }
         }
        catch {
            Write-Information "catch"
            Write-Information $_.Exception.GetType().FullName
            Write-Information $_.Exception.Message
            Write-Information ($null -eq $_.Exception.Response)
            return "$($_.Exception.Message) - $($_.Exception.GetType().FullName)"
        }
    }
    
     Write-Host -NoNewline "`r "
 $caPolicies =  $outputData | Where-Object { !($_.conditions.users.includeUsers -ne "All") -and $_.conditions.applications.includeApplications -notin "All","None","Office365" }



$aadsp = @()
    foreach ($cap in $caPolicies) {
      $cap | select -ExpandProperty conditions | select -ExpandProperty applications | select -ExpandProperty includeApplications
}



