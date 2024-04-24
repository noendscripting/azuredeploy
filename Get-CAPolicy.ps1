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

function Build-OutputArray {
    param (
        [array]$Settings,
        [string]$Id,
        [string]$Name,
        [string]$Area,
        [string]$propertyName,
        [string]$PolicyName
    )

    $redexGUID = "^(\\{){0,1}[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}(\\}){0,1}$"
    If ($Settings -eq $null -or $Settings.Length -eq 0) {
        $data = New-Object PsCustomObject -Property @{
            Id                = $Id
            PropertyName      = $propertyName
            PropertySetting   = ""
            ConditionName     = $Name
            PolicySection     = $Area
            PolicyDisplayName = $PolicyName
        }
        #$outputArray += $data
        return $data
    }
    foreach ($value in $Settings) {
        if ($value -match $redexGUID) {
            $expandedValue = Find-Resources -type $Name -data $value
            $data = New-Object PsCustomObject -Property @{
                Id                = $Id
                PropertyName      = $propertyName
                PropertySetting   = $expandedValue
                ConditionName     = $Name
                PolicySection     = $Area
                PolicyDisplayName = $PolicyName
            }
            $data  
        } 
        else {        
            $data = New-Object PsCustomObject -Property @{
                Id                = $Id
                PropertyName      = $propertyName
                PropertySetting   = $value
                ConditionName     = $Name
                PolicySection     = $Area
                PolicyDisplayName = $PolicyName
            }
            $data    
        }
    }
    
}

Function Get-nestedProperties {  
    param(
        $policySettings,
        [string]$CaId,
        [string]$conditionName,
        [string]$policyArea,
        [string]$displayName

    )
    ForEach ($policyName in $policySettings.Keys ) {
        
        $policyValue = $policySettings.$policyName
        switch ($policyName.ToString()) {
            "applicationFilter" {
                $modeValue = $policySettings.$policyName.Mode
                Build-OutputArray -Settings $modeValue -Id $caId -Name $conditionName -Area $policyArea -propertyName "$($policyName)Mode" -PolicyName $displayName
                $ruleValue = $policySettings.$policyName.Rule
                Build-OutputArray -Settings $ruleValue -Id $caId -Name $conditionName -Area $policyArea -propertyName "$($policyName)Rule"-PolicyName $displayName
                continue
            }
            
            "IncludeGuestsOrExternalUsers" {
                $userValue = $policySettings.$policyName.guestOrExternalUserTypes
                Build-OutputArray -Settings $userValue -Id $caId -Name $conditionName -Area $policyArea -propertyName "$($policyName)guestOrExternalUserTypes" -PolicyName $displayName
                $tenantValue = Build-ExternalTenants -extenalTenantSettings $policySettings.$policyName.externalTenants
                Build-OutputArray -Settings $tenantValue -Id $caId -Name $conditionName -Area $policyArea -propertyName "$($policyName)tennats" -PolicyName $displayName                       
                continue
            }
            
            "excludeGuestsOrExternalUsers" {
                $userValue = $policySettings.$policyName.guestOrExternalUserTypes
                Build-OutputArray -Settings $userValue -Id $caId -Name $conditionName -Area $policyArea -propertyName "$($policyName)guestOrExternalUserTypes" -PolicyName $displayName
                $tenantValue = Build-ExternalTenants -extenalTenantSettings $policySettings.$policyName.externalTenants
                Build-OutputArray -Settings $tenantValue -Id $caId -Name $conditionName -Area $policyArea -propertyName "$($policyName)tennats" -PolicyName $displayName
                continue
            }
            "includeAuthenticationContextClassReferences" {
                $authValue = Find-AuthenticationContextClassReferences -authSettings  $policyValue
                Build-OutputArray -Settings $authValue -Id $caId -Name $conditionName -Area $policyArea -propertyName $policyName -PolicyName $displayName
                continue
            }
            "DeviceFilter" {
                $modeValue = $policySettings.$policyName.Mode
                Build-OutputArray -Settings $modeValue -Id $caId -Name $conditionName -Area $policyArea -propertyName "$($policyName)Mode"-PolicyName $displayName
                $ruleValue = $policySettings.$policyName.Rule
                Build-OutputArray -Settings $ruleValue -Id $caId -Name $conditionName -Area $policyArea -propertyName "$($policyName)Rule" -PolicyName $displayName
                continue

            }
            "includeLocations"
            {
                foreach ($locationId in $policyValue) {
                    $locationSettings = Build-LocationArray -locationData $locationId
                    
                }
            }
            "excludeLocations"
            {
                $locationSettings = Build-LocationArray
            }
            default {
                Build-OutputArray -Settings $policyValue -Id $CaId -Name $conditionName -Area $policyArea -propertyName $policyName -PolicyName $displayName
                continue
            }
        }           
        
        
    }

    
}

function Build-ExternalTenants {
    param(
        $extenalTenantSettings
    )
    if ($extenalTenantSettings.membershipKind -eq "All") {
        return "All"
    }
    else {
        return $extenalTenantSettings.members
    }
    



}
function Find-AuthenticationContextClassReferences {
    param (
        $authSettings
    )
    [string[]]$outputArray = $()
    $authSettings | ForEach-Object {
        $outputArray += (Get-MgIdentityConditionalAccessAuthenticationContextClassReference -AuthenticationContextClassReferenceId $_).DisplayName
    }
    return $outputArray
}

function Find-Resources {
    param (
        $type,
        $data
    )

    switch ($type) {
        'applications' {
            return (Get-MgApplication -Filter "appId eq '$data'").DisplayName

        }
        'users' {
            return (Get-MgDirectoryObject -DirectoryObjectId $data).AdditionalProperties.displayName
        }
        Default {}
    }
    
}
function Build-LocationArray {
    param (
        $locationId
    )
    
}


#Check if the user has the appropriate roles
$currentRoles = (Get-MgContext -ErrorAction SilentlyContinue).scopes 

If ([string]::IsNullOrEmpty($currentRoles)) {
    Write-Host "No roles found"
    Throw "No roles found. Please login with a user that has the appropriate roles" 
}

$results = @()

#Get all the policies
$listPolicyIds = (Get-MgIdentityConditionalAccessPolicy -Select "id" -PageSize 200).Id
write-verbose "Found $($listPolicyIds.count) policies"
Remove-Item -Path "c:\temp\capolicy.csv" -Force
forEach ($policyId in $listPolicyIds) {
    
    #$outputFilePrefix = "$outPutFolder\$policyId\$policyId"
    #$policyData = Get-MgIdentityConditionalAccessPolicy -Filter "id eq '$policyId'"
    $policyData = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies/$policyId" -Method Get
    $conditions = $policyData.Conditions 
    $displayName = $policyData.DisplayName

    foreach ($conditionName in $conditions.Keys) {
        $conditionValues = $conditions.$conditionName
        if ($conditionName -ne "locations") {
            #-or $conditionName -ne "clientAppTypes" -or $conditionName -ne "locations" -or $conditionName -ne "platforms" -or $conditionName -ne "signInRiskLevels" -or $conditionName -ne "userRiskLevels" -or $conditionName -ne "servicePrincipalRiskLevels") 
            continue
        }
        if ($conditionValues -eq $null) {
            $results += Build-OutputArray -Settings "" -Id $policyId -Name $conditionName -Area "Conditions" -propertyName $conditionName -PolicyName $displayName
            
        }
        elseif ($conditionValues.GetType().Name -eq "String" -or $conditionValues.GetType().Name -eq "Object[]") {
            [array]$settingsArray = $conditionValues.Split(",")
            $results += Build-OutputArray -Settings $settingsArray -Id $policyId -Name $conditionName -Area "Conditions" -propertyName $conditionName -PolicyName $displayName
        }
        elseif ($conditionValues.GetType().Name -eq "Hashtable" ) {
            $results += Get-nestedProperties -policySettings $conditionValues -CaId $policyId -conditionName $conditionName -policyArea "Conditions" -displayName $displayName
        }
        else {
            Write-Host "$($displayName) $($policySettings.GetType().Name)"
        }
    
        
        
}
    
#Save basic policy data
#$policyData | Select-Object -Property id, DisplayName, CreatedDateTime, ModifiedDateTime, State, TemplateId | Export-Csv -Path "$($outputFilePrefix)_basic.csv" -Force -NoTypeInformation
  
    
$results | Select-Object -Property PolicyDisplayName, Id, PolicySection, ConditionName, PropertyName, PropertySetting | Export-Csv -Path "c:\temp\capolicy.csv" -NoTypeInformation -Append
Exit      

} 

        
        

    

    
#Other conditions
#"userRiskLevels"
#"signInRiskLevels": [],
#"clientAppTypes": 
#"servicePrincipalRiskLevels": [],
#"platforms": null,
#"locations": null,
#"clientApplications": null,

    
     
