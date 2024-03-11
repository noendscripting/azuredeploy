[CmdletBinding()]

param()

$currentRoles = (Get-MgContext -ErrorAction SilentlyContinue).scopes 

If ([string]::IsNullOrEmpty($currentRoles)) {
    Write-Host "No roles found"
    Throw "No roles found. Please login with a user that has the appropriate roles" 
}



$listPolicyIds = (Get-MgIdentityConditionalAccessPolicy -Filter "state ne 'disabled'" -Select "id" -PageSize 200).Id
write-verbose "Found $($listPolicyIds.count) policies"

forEach ($policyId in $listPolicyIds) {
    New-Item -ItemType Directory -Path "C:\temp\CA" -Name $policyId 
    $policyData = Get-MgIdentityConditionalAccessPolicy -Filter "id eq '$policyId'"
    #
    $policyData | Select-Object -Property id,DisplayName,CreatedDateTime,Description,ModifiedDateTime,State,TemplateId | ConvertTo-Csv -NoHeader  | Out-File -FilePath "C:\temp\CA\$($policyId)\$($policyId)_basic.csv" 
    exit 
}