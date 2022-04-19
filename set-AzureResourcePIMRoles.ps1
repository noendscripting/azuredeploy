  [CmdletBinding()]
  param (
  [Parameter(Mandatory)]
  [string[]]$roles,
  [string]$resourceId,
  # Parameter help description
  [Parameter(ParameterSetName='hello')]
  [bool]
  $ParameterName
    
  )
  
  




#region Classes
class Target
{
    [string]$caller = "EndUser"
    [string[]]$operations = @("All")
    [string]$level
    [object]$targetObjects = $null
    [object]$enforcedSettings= $null
    [object]$inheritableSettings=$null
}

class PolicyProperties
    {
        [array]$rules 
    }

    class PolicySettings
    {
        [PolicyProperties]$properties=[PolicyProperties]::New()
    }

Class Expiration_Admin_Eligibility
    {
        [bool] $isExpirationRequired
        [string] $maximumDuration
        [string] $id='Expiration_Admin_Eligibility'
        [string] $ruleType='RoleManagementPolicyExpirationRule'
        [Target]$target = [Target]::New()
    }

Class Enablement_EndUser_Assignment
    {
           [string[]]$enabledRules =@()
           [string]$id = "Enablement_EndUser_Assignment"
           [string]$ruleType = "RoleManagementPolicyEnablementRule"
          [Target]$target = [Target]::New()
    }
Class Expiration_EndUser_Assignment
{
    [bool]$isExpirationRequired
    [string]$maximumDuration
    [string]$id ="Expiration_EndUser_Assignment"
    [string]$ruleType = "RoleManagementPolicyExpirationRule"
    [Target]$target = [Target]::New()
}




#endregion
$resourceId = "/subscriptions/87008fdf-ae91-4584-b623-7ecb86459002/resourceGroups/Group-test/providers/Microsoft.Storage/storageAccounts/101csvprocesstest"
$subscriptionId = $resourceId.Split("/")[2]
$roleDefenitionId = "b24988ac-6180-42a0-ab88-20f7382dd24c"
$filter = '$filter'
#region collect current policy settings
$policyResult = (Invoke-AzRest -Path "$($resourceId)/providers/Microsoft.Authorization/roleManagementPolicies?api-version=2020-10-01-preview&$filter=roleDefinitionId%20eq%20'$($resourceId)/providers/Microsoft.Authorization/roleDefinitions/$($roleDefenitionId)'" -Method GET).Content | ConvertFrom-Json
$policyName = $policyResult.value.name
#create root policy object
$policyObject = [PolicySettings]::New()
#endregion
#region Setting Role Assignment Rules
$Expiration_Admin_Eligibility = [Expiration_Admin_Eligibility]::New()
$Expiration_Admin_Eligibility.isExpirationRequired = $false
$Expiration_Admin_Eligibility.target.level = 'Eligibility'

$Enablement_EndUser_Assignment = [Enablement_EndUser_Assignment]::New()
$Enablement_EndUser_Assignment.enabledRules = @("Justification","MultiFactorAuthentication")
$Enablement_EndUser_Assignment.target.level = 'Assignment'
#endregion
#region Setting Activation Rules
$Expiration_EndUser_Assignment = [Expiration_EndUser_Assignment]::New()
$Expiration_EndUser_Assignment.maximumDuration = "PT6H"
$Expiration_EndUser_Assignment.isExpirationRequired = $true
$Expiration_EndUser_Assignment.target.level = 'Assignment'
#endregion

#region Creating rules array
$policySettings = @()

$policySettings += $Expiration_Admin_Eligibility
$policySettings += $Enablement_EndUser_Assignment
$policySettings += $Expiration_EndUser_Assignment

$policyObject.properties.rules = $policySettings

$policyObject.properties.rules
#endregion

#region update policy 
$policyUpdate = $policyObject | ConvertTo-Json -Depth 99
Invoke-AzRest -Path "$($resourceId)/providers/Microsoft.Authorization/roleManagementPolicies/$($policyName)?api-version=2020-10-01-preview" -Method PATCH -Payload $policyUpdate
#endregion



