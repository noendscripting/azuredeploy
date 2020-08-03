

$report = @()
  (Get-AzKeyVault).VaultName | ForEach-Object {

    $keyVaultName = $_ 
    (Get-AzKeyVault -VaultName $keyVaultName).AccessPolicies | ForEach-Object {

        $policyObject = new-object psobject  -Property @{
            KeyVaultName                 = $keyVaultName
            ObjectId                     = $_.ObjectId
            DisplayName                  = $_.DisplayName
            ApplicationId                = $_.ApplicationId
            ApplicationIdDisplayName     = $_.ApplicationIdDisplayName
            PermissionsToCertificates    = $_.PermissionsToCertificates -join " "   
            PermissionsToCertificatesStr = $_.PermissionsToCertificatesStr -join " "
            PermissionsToKeys            = $_.PermissionsToKeys -join " "          
            PermissionsToKeysStr         = $_.PermissionsToKeysStr -join " "
            PermissionsToSecrets         = $_.PermissionsToSecrets -join " "
            PermissionsToSecretsStr      = $_.PermissionsToSecretsStr -join " "
            PermissionsToStorage         = $_.PermissionsToStorage -join " "
            PermissionsToStorageStr      = $_.PermissionsToStorageStr -join " "
            TenantId                     = $_.TenantId
            TenantName                   = $_.TenantName
        }
         
        $report += $policyObject
       
    }

    

}

$report

#optional export into csv
#$report | Export-Csv -NoTypeInformation -Path ./mycsv.csv
