[CmdletBinding()]

#requires -modules @{Modulename = "Microsoft.Graph.Authentication";ModuleVersion="2.16.0"}
#requires -modules @{ModuleName = "Microsoft.Graph.Beta.Identity.SignIns";ModuleVersion="2.16.0"}




param(
    $outPutFilePath = "$($PWD)\capolicy.csv",
    [string]$policyName = "All",
    [PSDefaultValue(Help = 'Global Commercial Tenant')]
    [ValidateSet("China", "Global", "USGovDoD", "USGov", "Germany")]
    [string]$TenantEnvironment = "Global",
    [Parameter(ParameterSetName = 'AllSections')]
    [switch]$AllSections,
    [Parameter(ParameterSetName = 'Sections')]
    [switch]$Users,
    [Parameter(ParameterSetName = 'Sections')]
    [switch]$Locations,
    [Parameter(ParameterSetName = 'Sections')]
    [switch]$Applications
    
)
<#
class ConditionalAccessPolicy
    {
        
        [conditions]$conditions = [conditions]::new()
        
    }
    class conditions
    {
        [users]$users = [users]::new()
        [object]$locations
        [applications]$applications = [applications]::new()
        
    }
    class users
    {
        [string[]]$excludeUsers
        [string[]]$includeUsers
        [string[]]$includeGroups
        [string[]]$excludeGroups
    }
    class Applications
    {
        [string[]]$excludeApplications
        [string[]]$includeApplications
    }
   #>

   

$ErrorActionPreference = "Stop"
#Check if the user has the appropriate roles
$currentRoles = (Get-MgContext -ErrorAction SilentlyContinue).scopes 

If ([string]::IsNullOrEmpty($currentRoles)) {
    Write-Host "No roles found"
    Throw "No roles found. Please login with a user that has the appropriate roles" 
}

New-Variable -Name graphEnvFQDN -Value $null -Scope Script -Force
switch ($TenantEnvironment) {
    "Global" { $graphEnvFQDN = "graph.microsoft.com" } 
    "China" { $graphEnvFQDN = "microsoftgraph.chinacloudapi.cn" }
    "USGovDoD" { $graphEnvFQDN = "dod-graph.microsoft.us" }
    "USGov" { $graphEnvFQDN = "graph.microsoft.us" }
    "Germany" { $graphEnvFQDN = "graph.microsoft.de" }
}

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
if ($AllSections) {
    $Users = $true
    $Locations = $true
    $Applications = $true
}

Write-Host $Parameterlist

$listPolicyIds = (Invoke-MgGraphRequest -Uri $queryURL).value.id
write-verbose "Found $($listPolicyIds.count) policies"
$processed = 0
forEach ($policyId in $listPolicyIds) {
   
    $processedPercent = ($processed / $listPolicyIds.Count) * 100
    
    #Write-Progress -Activity "Processing Policies" -Status "Processing Policy $policyId" -PercentComplete $processedPercent
    #$policyData = Get-MgBetaIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policyId
   try {
        $policyData = Invoke-MgGraphRequest -Uri "https://$($graphEnvFQDN)/v1.0/identity/conditionalAccess/policies/$($policyId)" -Method Get -OutputType PSObject
    }
    catch [Microsoft.Graph.PowerShell.Authentication.Helpers.HttpResponseException] {
        if ($_.ErrorDetails.Message -match "contains preview features") {
            $policyData = Invoke-MgGraphRequest -Uri "https://$($graphEnvFQDN)/beta/identity/conditionalAccess/policies/$($policyId)" -Method Get -OutputType PSObject
        }
        else {
            Throw "Error getting policy data for $policyId - $($_.ErrorDetails.Message)"

        }
    }
    catch {
        
        Throw "Error getting policy data for $policyId - $($_.Message)"
    }

    $policyObject = @{}
    $policyObject.displayName = $policyData.DisplayName
    $policyObject.conditions = $policyData.Conditions
    $policyObject.grantControls = $policyData.GrantControls
    $policyObject.id = $policyData.sessionControls
    $policyObject | ConvertTo-Json -Depth 99
}
 <#  ForEach($propertyName in ($policyData.Conditions.users | Get-Member  -MemberType Property).name  ) 
   {
       If ([string]::IsNullOrEmpty($policyData.Conditions.users.$propertyName)) {
           Write-Host $propertyName
       }
    #$policyData.Conditions.applications
    #$policyData.Conditions.locations
    #$policyData.GrantControls.AuthenticationMethods

    #$grants = $policyData.GrantControls
    #$displayName = $policyData.DisplayName
   }

}#>