[CmdletBinding()]

#requires -modules @{Modulename = "Microsoft.Graph.Authentication";ModuleVersion="2.16.0"}




param(
    $outPutFilePath = "$($PWD)\capolicy.csv",
    [string]$policyName = "All",
    [PSDefaultValue(Help = 'Global Commercial Tenant')]
    [ValidateSet("China", "Global", "USGovDoD", "USGov", "Germany")]
    [string]$TenantEnvironment = "Global",
    [switch]$RemoveOrphaned
    
)
$ErrorActionPreference = "Stop"
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
        
        return $data
    }
    foreach ($value in $Settings) {
        if ($value -match $redexGUID -and $propertyName -ne "id") {
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
            "includeLocations" {
                If ($policyValue -eq "All" -or $policyValue -eq "AllTrusted") {
                    
                    Build-OutputArray -Settings $policyValue -Id $caId -Name "$($conditionName)_$($policyName)_All" -Area $policyArea -propertyName $policyName -PolicyName $displayName
                    continue
                }
                Else {

                    foreach ($locationId in $policyValue) {
                        $locationSettings = Build-LocationArray -locationId $locationId
                        foreach ($locationSetting in $locationSettings) {
                            Build-OutputArray -Settings $locationSetting.LocationValue -Id $caId -Name "$($conditionName)_$($policyName)_$($locationSetting.displayName)" -Area $policyArea -propertyName $locationSetting.LocationType -PolicyName $displayName
                        }
                        
                    }
                    continue
                }
                
            }
            "excludeLocations" {
                If ($policyValue -eq "All" -or $policyValue -eq "AllTrusted") {
                    
                    Build-OutputArray -Settings $policyValue -Id $caId -Name "$($conditionName)_$($policyName)_All" -Area $policyArea -propertyName $policyName -PolicyName $displayName
                    continue
                }
                Else {

                    foreach ($locationId in $policyValue) {
                        $locationSettings = Build-LocationArray -locationId $locationId
                        foreach ($locationSetting in $locationSettings) {
                            Build-OutputArray -Settings $locationSetting.LocationValue -Id $caId -Name "$($conditionName)_$($policyName)_$($locationSetting.displayName)" -Area $policyArea -propertyName $locationSetting.LocationType -PolicyName $displayName
                        }
                        
                    }
                    continue
                }
            }
            "combinationConfigurations@odata.context" {
                continue
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
        $outputArray += (Invoke-MgGraphRequest -Uri "https://$($graphEnvFQDN)/v1.0/identity/conditionalAccess/authenticationContextClassReferences/$($PSItem)").DisplayName
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

            try { $appDisplayName = (Invoke-MgGraphRequest -Uri "https://$($graphEnvFQDN)/v1.0/servicePrincipals(appId='$($data)')").displayName }
            catch { $appDisplayName = $data }

            return $appDisplayName
        }
        'users' {
            try { $userDisplayName = (Invoke-MgGraphRequest -Uri "https://$($graphEnvFQDN)/v1.0/directoryObjects/$($data)").displayName }
            catch { $userDisplayName = $data }

            return $userDisplayName
        }
        Default {}
    }
    
}
function Build-LocationArray {
    param (
        $locationId
    )
    $locationOutput = @()
    Try {
        $locationData = Invoke-MgGraphRequest -Uri "https://$($graphEnvFQDN)/v1.0/identity/conditionalAccess/namedLocations/$($locationId)" -Method Get
    }
    Catch {
        $outPutValue = New-Object PsCustomObject -Property @{
            DisplayName   = $locationId
            LocationType  = "orphaned"
            LocationValue = "orphaned"
        }
        return $outPutValue
    }

    $locationDisplayName = $locationData.DisplayName
    if ($locationData.'@odata.type' -match 'ipNamedLocation') {
        $ipAdressList = Find-LocationIpRanges -ipRangeData $locationSettings.ipRanges
        forEach ($IpAddress in $ipAdressList) {
            $outPutValue = New-Object PsCustomObject -Property @{
                DisplayName   = $locationDisplayName
                LocationType  = "cidrAddress"
                LocationValue = $IpAddress
            }
            $locationOutput += $outPutValue
        }
        $outPutValue = New-Object PsCustomObject -Property @{
            DisplayName   = $locationDisplayName
            LocationType  = "isTrusted"
            LocationValue = $locationSettings.isTrusted
        }
        $locationOutput += $outPutValue
        return $locationOutput
    }
    elseif ($locationSettings.'@odata.type' -match 'countryNamedLocation') {
        foreach ($country in $locationSettings.countriesAndRegions) {
            $outPutValue = New-Object PsCustomObject -Property @{
                DisplayName   = $locationDisplayName
                LocationType  = "countriesAndRegions"
                LocationValue = $country
            }
            $locationOutput += $outPutValue
        }
        $outPutValue = New-Object PsCustomObject -Property @{
            DisplayName   = $locationDisplayName
            LocationType  = "countryLookupMethod"
            LocationValue = $locationSettings.countryLookupMethod
        }
        $locationOutput += $outPutValue
        $outPutValue = New-Object PsCustomObject -Property @{
            DisplayName   = $locationDisplayName
            LocationType  = "includeUnknownCountriesAndRegions"
            LocationValue = $locationSettings.includeUnknownCountriesAndRegions
        }
        $locationOutput += $outPutValue
        return $locationOutput
    }
    
}

Function Find-LocationIpRanges {
    param( $ipRangeData)
    $ipOutput = @()
    foreach ($ipRange in $ipRangeData) {
        $ipOutput += $ipRange.cidrAddress
    }
    return $ipOutput
}

#Check if the user has the appropriate roles
$currentRoles = (Get-MgContext -ErrorAction SilentlyContinue).scopes 

If ([string]::IsNullOrEmpty($currentRoles)) {
    Write-Host "No roles found"
    Throw "No roles found. Please login with a user that has the appropriate roles" 
}
<#elseif ($currentRoles -notcontains "Policy.Read.All" -and $currentRoles -notcontains "Directory.Read.All") {
    throw "This script requires the Policy.Read.All and Directory.Read.All permissions. Please login with an appropriate permissions scope"
}#>
New-Variable -Name graphEnvFQDN -Value $null -Scope Script -Force
switch ($TenantEnvironment) {
    "Global" { $graphEnvFQDN = "graph.microsoft.com" } 
    "China" { $graphEnvFQDN = "microsoftgraph.chinacloudapi.cn" }
    "USGovDoD" { $graphEnvFQDN = "dod-graph.microsoft.us" }
    "USGov" { $graphEnvFQDN = "graph.microsoft.us" }
    "Germany" { $graphEnvFQDN = "graph.microsoft.de" }
}

if (Test-Path  $outPutFilePath ) {
    Remove-Item -Path  $outPutFilePath  -Force
}

$results = [System.Collections.Generic.List[System.Object]]::new()
if ($PSVersionTable.PSVersion.Major -ge 7) {

    $PSStyle.Progress.View = 'Minimal'
}
    

If ($policyName -eq "all") {
    #Get all the policies
    $queryURL = 'https://' + "$($graphEnvFQDN)" + '/beta/identity/conditionalAccess/policies?$select=id'
    
}
else {
    $queryURL = 'https://' + "$($graphEnvFQDN)" + '/beta/identity/conditionalAccess/policies?$filter=displayName eq '''+ "$($policyName)" +'''&$select=id'
    
    
}

$listPolicyIds = (Invoke-MgGraphRequest -Uri $queryURL).value.id
write-verbose "Found $($listPolicyIds.count) policies"
$processed = 0

forEach ($policyId in $listPolicyIds) {
   
    $processedPercent = ($processed / $listPolicyIds.Count) * 100
    
    Write-Progress -Activity "Processing Policies" -Status "Processing Policy $policyId" -PercentComplete $processedPercent
    try {
        $policyData = Invoke-MgGraphRequest -Uri "https://$($graphEnvFQDN)/v1.0/identity/conditionalAccess/policies/$($policyId)" -Method Get
    }
    catch [Microsoft.Graph.PowerShell.Authentication.Helpers.HttpResponseException] {
        if ($_.ErrorDetails.Message -match "contains preview features") {
            $policyData = Invoke-MgGraphRequest -Uri "https://$($graphEnvFQDN)/beta/identity/conditionalAccess/policies/$($policyId)" -Method Get
        }
        else {
            Throw "Error getting policy data for $policyId - $($_.ErrorDetails.Message)"

        }
    }
    catch {
        
        Throw "Error getting policy data for $policyId - $($_.Message)"
    }
    
    
    $conditions = $policyData.Conditions
    $grants = $policyData.GrantControls
    $sessionControls = $policyData.SessionControls
    $displayName = $policyData.DisplayName
    
    [void]$results.Add((Build-OutputArray -Settings $policyData.templateId -Id $policyId -Name 'templateId' -Area "Base" -propertyName 'templateId' -PolicyName $displayName))
    [void]$results.Add((Build-OutputArray -Settings $policyData.createdDateTime -Id $policyId -Name 'createdDateTime' -Area "Base" -propertyName 'createdDateTime' -PolicyName $displayName))
    [void]$results.Add((Build-OutputArray -Settings $policyData.createdDateTime -Id $policyId -Name 'createdDateTime' -Area "Base" -propertyName 'createdDateTime' -PolicyName $displayName))
    [void]$results.Add((Build-OutputArray -Settings $policyData.modifiedDateTime -Id $policyId -Name 'modifiedDateTime' -Area "Base" -propertyName 'modifiedDateTime' -PolicyName $displayName))
    [void]$results.Add((Build-OutputArray -Settings $policyData.state -Id $policyId -Name 'state' -Area "Base" -propertyName 'state' -PolicyName $displayName))
    foreach ($conditionName in $conditions.Keys) {
        $conditionValues = $conditions.$conditionName
        $outputData = $null
        if ($conditionValues.Length -eq 0) {
            [void]$results.Add((Build-OutputArray -Settings "" -Id $policyId -Name $conditionName -Area "Conditions" -propertyName $conditionName -PolicyName $displayName))
            
        }
        elseif ($conditionValues.GetType().Name -eq "String" -or $conditionValues.GetType().Name -eq "Object[]") {
            [array]$settingsArray = $conditionValues.Split(",")
            #$outputData = Build-OutputArray -Settings $settingsArray -Id $policyId -Name $conditionName -Area "Conditions" -propertyName $conditionName -PolicyName $displayName

            forEach ($output in $outputData) {
                [void]$results.Add($output)
            }
        }
        elseif ($conditionValues.GetType().Name -eq "Hashtable" ) {
            $outputData = Get-nestedProperties -policySettings $conditionValues -CaId $policyId -conditionName $conditionName -policyArea "Conditions" -displayName $displayName
            forEach ($output in $outputData) {
                [void]$results.Add($output)
            }
        }
        else {
            Write-Host "$($displayName) $($policySettings.GetType().Name)"
        }
    }
    
    
  
    forEach ($grantName in $grants.Keys) {
        $outputData = $null
        $grantValue = $grants.$grantName
        if ($grantName -eq "authenticationStrength@odata.context") {
            continue
        }
        if ($grantValue.Length -eq 0) {
            [void]$results.Add((Build-OutputArray -Settings "" -Id $policyId -Name $grantName -Area "GrantControls" -propertyName $grantName -PolicyName $displayName))
            
        }
        elseif ($grantValue.GetType().Name -eq "String" -or $grantValue.GetType().Name -eq "Object[]") {
            [array]$settingsArray = $grantValue.Split(",")
            $outputData = Build-OutputArray -Settings $settingsArray -Id $policyId -Name $grantName -Area "GrantControls" -propertyName $grantName -PolicyName $displayName
            foreach ($output in $outputData) {
                [void]$results.Add($output)
            }
        }
        elseif ($grantValue.GetType().Name -eq "Hashtable" ) {

            $outputData = Get-nestedProperties -policySettings $grantValue -CaId $policyId -conditionName $grantName -policyArea "GrantControls" -displayName $displayName
            foreach ($output in $outputData) {
                [void]$results.Add($output)
            }
        }
        else {
            Write-Host "$($displayName) $($policySettings.GetType().Name)"
        }
    }

    forEach ($sessionControl in $sessionControls.Keys) {
        $outputData = $null
        $sessionControlsValue = $sessionControls.$sessionControl
        if ($sessionControlsValue.Length -eq 0) {
            [void]$results.Add((Build-OutputArray -Settings "" -Id $policyId -Name $sessionControl -Area "SessionControls" -propertyName $sessionControl -PolicyName $displayName))
            
        }
        elseif ($sessionControlsValue.GetType().Name -eq "String" -or $sessionControlsValue.GetType().Name -eq "Object[]") {
            [array]$settingsArray = $sessionControlsValue.Split(",")
            $outputData = Build-OutputArray -Settings $settingsArray -Id $policyId -Name $sessionControl -Area "SessionControls" -propertyName $sessionControl -PolicyName $displayName
            foreach ($output in $outputData) {
                [void]$results.Add($output)
            }
        }
        elseif ($sessionControlsValue.GetType().Name -eq "Hashtable" ) {
            $outputData = Get-nestedProperties -policySettings $sessionControlsValue -CaId $policyId -conditionName $sessionControl -policyArea "SessionControls" -displayName $displayName
            foreach ($output in $outputData) {
                [void]$results.Add($output)
            }
        }
        else {
            Write-Host "$($displayName) $($sessionControlsValue.GetType().Name)"
        }
    }
    
    
    $processed += 1

} 
$results | Select-Object -Property PolicyDisplayName, Id, PolicySection, ConditionName, PropertyName, PropertySetting | Export-Csv -Path $outPutFilePath -NoTypeInformation -Append

        


    
     
