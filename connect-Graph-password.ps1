function Import-Bulkdata {
    param (
        [string]$users,
        [string]$sqlliteconnection
    )
    
$columns = (($tempArray | Get-Member -MemberType NoteProperty).Name -join ", ")
$command = $sqlliteconnection.CreateCommand()

$transaction = $sqlliteconnection.BeginTransaction()

$command.CommandText = "INSERT INTO your_table ($($columns)) VALUES (@Id, @displayName, @lastSignInDateTime, @onPremisesSyncEnabled, @externalUserState);"
$command.Parameters.Add((New-Object Data.SQLite.SQLiteParameter("@Id", $userId)))
$command.Parameters.Add((New-Object Data.SQLite.SQLiteParameter("@displayName", $userDisplayName)))
$command.Parameters.Add((New-Object Data.SQLite.SQLiteParameter("@lastSignInDateTime", $userSignInActivity)))
$command.Parameters.Add((New-Object Data.SQLite.SQLiteParameter("@onPremisesSyncEnabled", $userOnPremisesSyncEnabled)))
$command.Parameters.Add((New-Object Data.SQLite.SQLiteParameter("@externalUserState", $userExternalUserState)))

forEach ($user in $users) {
    $command.Parameters["@Id"].Value = $user.Id
    $command.Parameters["@displayName"].Value = $user.displayName
    $command.Parameters["@lastSignInDateTime"].Value = $user.signInActivity.lastSignInDateTime
    $command.Parameters["@onPremisesSyncEnabled"].Value = $user.onPremisesSyncEnabled
    $command.Parameters["@externalUserState"].Value = $user.externalUserState

    # Execute the command
    $command.ExecuteNonQuery()
}


$transaction.Commit()
$command.Dispose()

}
$uri = "https://login.microsoftonline.com/9dd7796e-60f8-47be-a0e4-c407efe3201c/oauth2/v2.0/token"
#$username = 'dailyuser@azurenow.win'
#$password = "Greencar17"
[int]$batchSize = 500
$clinet_id = '4f150e39-7db0-4382-9ebe-a22ba2a7667f'
$client_secret = '_Q58Q~AQA5iu6OfZoc0i~fEFpeyHCykbWNeHucIS'
$queryURI = "https://graph.microsoft.com/v1.0/users?`$select=Id,displayName,assignedLicenses,signInActivity,onPremisesSyncEnabled,externalUserState&`$count=true"
#$queryURI = "https://graph.microsoft.com/v1.0/users?`$select=Id,displayName,assignedLicenses,signInActivity,onPremisesSyncEnabled,externalUserState&`$count=true&`$filter=id eq '58e4e045-ffec-4e35-8617-496060856417'"
$scope = [System.Web.HTTPUtility]::UrlEncode("https://graph.microsoft.com/.default")
#Generating header values
$tokenRequestQueryHeaderss = @{
    ContentType = "application/x-www-form-urlencoded"
}
Write-Host $queryURI
#Create body to pass when requesting access token
$body = "client_id=$($clinet_id)&scope=$($scope)&client_secret=$($client_secret)&grant_type=client_credentials"

#$body = "client_id=$($clinet_id)&scope=$($scope)&username=$($username)&password=$($password)&grant_type=password"
$ErrorActionPreference = "continue"
#Send a post request to obtain bearer token
try {
    $result = Invoke-RestMethod -Uri $uri -Body $body -Method Post -Headers $tokenRequestQueryHeaderss
}
catch {
    write-host $_.Exception.response.StatusCode
}

write-host "Obtained access token"
#Generate Header for query by adding Access Token obtained earlier

#create sqllite database and table

$sqliteDB = "C:\Temp\graph.db"
$sqlightDll = "C:\Program Files\SQLite\System.Data.SQLite.dll"
[Reflection.Assembly]::LoadFile($sqlightDll)
if (Test-Path $sqliteDB) {
    Remove-Item $sqliteDB -Force
 }
[System.Data.SQLite.SQLiteConnection]::CreateFile($sqliteDB)
$databaseConnectionString=[string]::Format("data source={0}",$sqliteDB)
$sqliteDBConnection = New-Object System.Data.SQLite.SQLiteConnection
$sqliteDBConnection.ConnectionString = $databaseConnectionString
$sqliteDBConnection.open()
$sqlitedbCommand = $sqliteDBConnection.CreateCommand()
$sqlitedbCommand.CommandText="create table users (Id varchar(100), displayName varchar(100), lastSignInDateTime varchar(100), onPremisesSyncEnabled varchar(100), externalUserState varchar(100))"
$sqlitedbCommand.CommandType = [System.Data.CommandType]::Text
$sqlitedbCommand.ExecuteNonQuery()


#$createTable = "CREATE TABLE IF NOT EXISTS users (Id TEXT PRIMARY KEY, displayName TEXT, lastSignInDateTime TEXT, onPremisesSyncEnabled TEXT, externalUserState TEXT);"
#$insertData = "INSERT OR REPLACE INTO users (Id, displayName, lastSignInDateTime, onPremisesSyncEnabled, externalUserState) VALUES (@Id, @displayName, @lastSignInDateTime, @onPremisesSyncEnabled, @externalUserState);"
#execute the command to create the table

#& $sqlightCMD $sqliteDB $createTable

$function_started = get-date

$queryHeaders = @{
    Authorization = "Bearer $($result.access_token)"

}
#Generate Header for query by adding Access Token obtained earlier
$queryHeaders = @{
    Authorization    = "Bearer $($result.access_token)"
    ConsistencyLevel = "eventual"
}


$outputData = @()
#Send request 
while (!([string]::IsNullOrEmpty($queryURI))) {
    
    if((New-TimeSpan -Start $function_started  -end (get-date)).Hours -gt 1){
        write-host "Terminating script after set time"
        $queryURI = $null
    }
    try {
        $queryResult = Invoke-RestMethod -Headers $queryHeaders -Body $body -Uri $queryURI  -Method Get 
        #$tempArray = extract-lastsignin -users $queryResult.value

       
        $columns = (($tempArray | Get-Member -MemberType NoteProperty).Name -join ", ")
        $values = ($tempArray | ForEach-Object { "('$($_.Id)', '$($_.displayName)', '$($_.lastSignInDateTime)', '$($_.onPremisesSyncEnabled)', '$($_.externalUserState)')" }) -join ", "
        $sql_insert_statement = "INSERT INTO users ($columns) VALUES $values;"
      #& $sqlightCMD $sqliteDB "INSERT OR REPLACE INTO users (Id, displayName, lastSignInDateTime, onPremisesSyncEnabled, externalUserState) VALUES ('$userId', '$userDisplayName', '$userSignInActivity', '$userOnPremisesSyncEnabled', '$userExternalUserState');"
      Write-Progress -Activity "Gteting data form Graph" -Status "Processing $($processedBatch) of $($totalusers) users" -percentcomplete (($processedBatch / $totalusers) * 100)
      Import-Bulkdata -users $queryResult.value -sqlliteconnection $sqliteDBConnection
        $queryURI = $queryResult.'@odata.nextLink'
        if (!([string]::IsNullOrEmpty($queryResult.'@odata.count'))) {
           [int]$totalusers = [int]$queryResult.'@odata.count'
        }
        [int]$processedBatch += $queryResult.value.Count
       
    } 
    catch [Microsoft.PowerShell.Commands.HttpResponseException]
     {
        switch ($_.Exception.response.StatusCode) {
            "TooManyRequests" {
                write-host "TooManyRequests Throtling triggered. Waiting for $($_.Exception.response.Headers.RetryAfter) seconds"
                start-sleep -Seconds  $_.Exception.response.Headers.RetryAfter
              }
              "Unauthorized" {
                Write-Host "Token expired, generating new token"
                $result = Invoke-RestMethod -Uri $uri -Body $body -Method Post -Headers $tokenRequestQueryHeaderss
                $queryHeaders = @{
                    Authorization = "Bearer $($result.access_token)"
                    ConsistencyLevel = "eventual"
                }
              }
              "BadRequest" {
                Write-Host "BadRequest. Rewirte URI before retrying terminating script"
                $queryURI = $null
                
              }
              "Request_UnsupportedQuery" {
                Write-Host "Request_UnsupportedQuery. Rewirte URI beofre retrying terminating script"
                $queryURI = $null
                
              }
              'Forbidden' {
                Write-Host "$(($Error[0].ErrorDetails.Message | ConvertFrom-Json).error.message).Terminating script"
                $queryURI = $null
                
              } 
            Default {
                write-host $Error[0].ErrorDetails.Message
                write-host $Error[0].Exception.response.StatusCode
                $queryURI = $null
            }
        }
     }
    catch {
        write-host "catch"
        write-host $_.Exception.GetType().FullName
        write-host $_.Exception.Message
        write-host ($null -eq $_.Exception.Response)
        $_.Exception.Response
    }
}

$sqliteDBConnection.Close()
$sqliteDBConnection.Dispose()

