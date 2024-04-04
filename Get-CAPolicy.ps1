[CmdletBinding()]
#requires -modules @{Modulename = "Microsoft.Graph.Applications";ModuleVersion="2.16.0"}
#requires -modules @{Modulename = "Microsoft.Graph.Authentication";ModuleVersion="2.16.0"}
#requires -modules @{Modulename = "Microsoft.Graph.DirectoryObjects";ModuleVersion="2.16.0"}
#requires -modules @{Modulename = "Microsoft.Graph.Groups";ModuleVersion="2.16.0"}
#requires -modules @{Modulename = "Microsoft.Graph.Users";ModuleVersion="2.16.0"}
#requires -modules @{Modulename = "Microsoft.Graph.Identity.SignIns";ModuleVersion="2.16.0"}

param(
    $outPutFolder = "C:\temp\CA"
)
Function Get-nestedProperties {  
    param(
        $policySettings
    )
    [PSCustomObject]$dataHash = @{} 
    ForEach ($propertyName in ($policySettings | Get-Member  -MemberType Property).Name) {    
        
    If ($policySettings.$propertyName -eq $null) {
        $propertyValue = ""
        $dataHash[$propertyName] = $propertyValue
    }
    elseif ($policySettings.$propertyName.GetType().Name -eq "String[]") {
            
            $propertyValue = $policySettings.$propertyName
            $dataHash[$propertyName] = $propertyValue -join ","
        }
    else {
            <# Action when all if and elseif conditions are false #>
        
        switch ($propertyName.ToString()) {
                       
            "includeAllApplications" {
                $propertyValue = $policySettings.$propertyName
                $dataHash[$propertyName] = $propertyValue -join ","
               
            }
            "excludeAllApplications" {
                $propertyValue = $policySettings.$propertyName
                $dataHash[$propertyName] = $propertyValue -join ","
            }
            "IncludeAuthenticationContextClassReferences" {
                $propertyValue = $policySettings.$propertyName
                $dataHash[$propertyName] = $propertyValue -join ","
            }
            
            "applicationFilter"
            {
                $propertyValue = $policySettings.$propertyName
                $dataHash[$propertyName] = $propertyValue -join ","
            }
            
            "IncludeGuestsOrExternalUsers" {
                $propertyValue = $userSettings.$propertyName
                $dataHash[$propertyName] = $propertyValue -join ","
            }
            
            "excludeGuestsOrExternalUsers" {
                $propertyValue = $userSettings.$propertyName
                $dataHash[$propertyName] = $propertyValue -join ","
            }
            "DeviceFilter"
            {
                $modeValue = $policySettings.$propertyName.Mode
                $dataHash['Mode'] = $modeValue
                $ruleValue = $policySettings.$propertyName.Rule
                $dataHash['Rule'] = $ruleValue

            }
            "ExcludePlatforms"
            {
                $propertyValue = $policySettings.$propertyName
                $dataHash[$propertyName] = $propertyValue -join ","
            }
            "IncludePlatforms"
            {
                $propertyValue = $policySettings.$propertyName
                $dataHash[$propertyName] = $propertyValue -join ","
            }
            default {
                $propertyValue = "New Property Type No processing code available"
                $dataHash[$propertyName] = $propertyValue
            }
        }
    }     
    }
    return $dataHash
}



#Check if the user has the appropriate roles
$currentRoles = (Get-MgContext -ErrorAction SilentlyContinue).scopes 

If ([string]::IsNullOrEmpty($currentRoles)) {
    Write-Host "No roles found"
    Throw "No roles found. Please login with a user that has the appropriate roles" 
}



#Get all the policies
$listPolicyIds = (Get-MgIdentityConditionalAccessPolicy -Select "id" -PageSize 200).Id
write-verbose "Found $($listPolicyIds.count) policies"

forEach ($policyId in $listPolicyIds) {
    
    New-Item -ItemType Directory -Path $outPutFolder -Name $policyId -Force
    $outputFilePrefix = "$outPutFolder\$policyId\$policyId"
    $policyData = Get-MgIdentityConditionalAccessPolicy -Filter "id eq '$policyId'"

    #Save basic policy data
    $policyData | Select-Object -Property id, DisplayName, CreatedDateTime, ModifiedDateTime, State, TemplateId | Export-Csv -Path "$($outputFilePrefix)_basic.csv" -Force -NoTypeInformation
    $conditions = $policyData.Conditions

    foreach ($conditionName in ($conditions| Get-Member -MemberType Property).Name)
    {
        if ($conditions.$conditionName.GetType().Name -eq "String[]") {
            $conditionValues = $conditions.$conditionName
            #[PSCustomObject]$conditionPolicies = Get-nestedProperties -policySettings $conditionValues
            [PSCustomObject]$conditionPolicies[$conditionName] = $conditionValues -join ","
            [PSCustomObject]$conditionPolicies | Export-Csv -Path "$($outputFilePrefix)_$($conditionName).csv" -Force -NoTypeInformation
            continue
        }
        else {

        $conditionValues = $policyData.Conditions.$conditionName
        [PSCustomObject]$conditionPolicies = Get-nestedProperties -policySettings $conditionValues
        [PSCustomObject]$conditionPolicies | Export-Csv -Path "$($outputFilePrefix)_$($conditionName).csv" -Force -NoTypeInformation
            
        }
        
        
        
    }
   <# #Save user conditions data
    $userSettings = $policyData.Conditions.Users
    [PSCustomObject]$userPolicies = Get-nestedProperties -policySettings $userSettings
    [PSCustomObject]$userPolicies | Export-Csv -Path "$($outputFilePrefix)_users.csv" -Force -NoTypeInformation

    #Save application conditions data
    $appSettings = $policyData.Conditions.Applications
    [PSCustomObject]$appPolicies = Get-nestedProperties -policySettings $appSettings
    [PSCustomObject]$appPolicies | Export-Csv -Path "$($outputFilePrefix)_applications.csv" -Force -NoTypeInformation

    #Save device conditions data
    $deviceSettings = $policyData.Conditions.Devices
    [PSCustomObject]$devicePolicies = Get-nestedProperties -policySettings $deviceSettings
    [PSCustomObject]$devicePolicies | Export-Csv -Path "$($outputFilePrefix)_devices.csv" -Force -NoTypeInformation

    #Save platforms conditions data
    $platformSettings = $policyData.Conditions.Platforms
    [PSCustomObject]$platformPolicies = Get-nestedProperties -policySettings $platformSettings
    [PSCustomObject]$platformPolicies | Export-Csv -Path "$($outputFilePrefix)_platforms.csv" -Force -NoTypeInformation
#>

    
    #Other conditions
    #"userRiskLevels"
    #"signInRiskLevels": [],
    #"clientAppTypes": 
    #"servicePrincipalRiskLevels": [],
    #"platforms": null,
    #"locations": null,
    #"clientApplications": null,
    Exit

    
     
}