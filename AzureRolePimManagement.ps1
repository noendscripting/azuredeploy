[CmdletBinding()]

param(
    [string]$RoleActivationMaximumDuration,
    [bool]$RequireJustificationOnRoleActivation,
    [bool]$RequireTicketInformationOnRoleActivation,
    [bool]$RequireApprovalToActivateRole,
    [string[]]$RoleActivationApprovers,
    [Parameter(Mandatory)]
    [string]$role,
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [string]$Id

)

<#
    5 RULES
    unifiedRoleManagementPolicyApprovalRule
     {   "id": "Approval_EndUser_Assignment",
        "ruleType": "RoleManagementPolicyApprovalRule",
        "target": {
          "caller": "EndUser",
          "operations": [
            "All"
          ],
          "level": "Assignment",
          "targetObjects": null,
          "inheritableSettings": null,
          "enforcedSettings": null
        }
        "setting": {
                "isApprovalRequired": false,
                "isApprovalRequiredForExtension": false,
                "isRequestorJustificationRequired": true,
                "approvalMode": "SingleStage",
                "approvalStages": [
                    {
                        "approvalStageTimeOutInDays": 1,
                        "isApproverJustificationRequired": true,
                        "escalationTimeInMinutes": 0,
                        "isEscalationEnabled": false,
                        "primaryApprovers": [],
                        "escalationApprovers": []
                    }
                ]
            }
      }

    unifiedRoleManagementPolicyAuthenticationContextRule                {
           
    unifiedRoleManagementPolicyEnablementRule
    Eligibility
    {
        "enabledRules": [],
        "id": "Enablement_Admin_Eligibility",
        "ruleType": "RoleManagementPolicyEnablementRule",
        "target": {
          "caller": "Admin",
          "operations": [
            "All"
          ],
          "level": "Eligibility",
          "targetObjects": null,
          "inheritableSettings": null,
          "enforcedSettings": null
        }
    }
    Assigniment
    { 
     "enabledRules": [
              "MultiFactorAuthentication",
              "Justification",
              "Ticketing"
            ],
            "id": "Enablement_EndUser_Assignment",
            "ruleType": "RoleManagementPolicyEnablementRule",
            "target": {
              "caller": "EndUser",
              "operations": [
                "All"
              ],
              "level": "Assignment",
              "targetObjects": null,
              "inheritableSettings": null,
              "enforcedSettings": null
            }
     }
          

          
    unifiedRoleManagementPolicyExpirationRule
    Eligibility
       {
        "isExpirationRequired": true,
        "maximumDuration": "P90D",
        "id": "Expiration_Admin_Eligibility",
        "ruleType": "RoleManagementPolicyExpirationRule",
        "target": {
          "caller": "Admin",
          "operations": [
            "All"
          ],
          "level": "Eligibility",
          "targetObjects": null,
          "inheritableSettings": null,
          "enforcedSettings": null
        }
      }
    Assigniment
    {
        "isExpirationRequired": false,
        "maximumDuration": "P90D",
        "id": "Expiration_Admin_Assignment",
        "ruleType": "RoleManagementPolicyExpirationRule",
        "target": {
          "caller": "Admin",
          "operations": [
            "All"
          ],
          "level": "Assignment",
          "targetObjects": null,
          "inheritableSettings": null,
          "enforcedSettings": null
        }
      } 
    unifiedRoleManagementPolicyNotificationRule



Properties
Caller
Operations
level
inhetitableSettings
enforcedSettings

#>


#region Classes

#root class for PIM polciies 
class PolicySettings
{
        [PolicyProperties]$properties=[PolicyProperties]::New()
}
#class for policy settings array 
class PolicyProperties
{
        [array]$rules 
}

#class to define target object
class Target
{
    [string]$caller = "EndUser"
    [string[]]$operations = @("All")
    [string]$level
    [object]$targetObjects = $null
    [object]$enforcedSettings= $null
    [object]$inheritableSettings=$null
}

Class Expiration
    {
        [bool] $isExpirationRequired
        [string] $maximumDuration
        [string] $id
        [string] $ruleType
        [Target]$target = [Target]::New()
    }
#end region




#$resourceId = "/subscriptions/87008fdf-ae91-4584-b623-7ecb86459002/resourceGroups/Group-test/providers/Microsoft.Storage/storageAccounts/101csvprocesstest"
$subscriptionId = $Id.Split("/")[2]
$roleDefenitionId = (Get-AzRoleDefinition -Name $role -Scope $Id).Id
Write-Verbose $roleDefenitionId
$filter = '$filter'
#region collect current policy settings
$policyResult = (Invoke-AzRest -Path "$($Id)/providers/Microsoft.Authorization/roleManagementPolicies?api-version=2020-10-01-preview&$filter=roleDefinitionId%20eq%20'$($Id)/providers/Microsoft.Authorization/roleDefinitions/$($roleDefenitionId)'" -Method GET).Content | ConvertFrom-Json
$policyName = $policyResult.value.name
$policyName

#create root policy object
$policyObject = [PolicySettings]::New()
#endregion

#region Setting Activation Rules
$Expiration_EndUser_Assignment = [Expiration]::New()
$Expiration_EndUser_Assignment.id = 'Expiration_EndUser_Assignment'
$Expiration_EndUser_Assignment.ruleType = 'RoleManagementPolicyExpirationRule'
$Expiration_EndUser_Assignment.maximumDuration = $RoleActivationMaximumDuration
$Expiration_EndUser_Assignment.isExpirationRequired = $true
$Expiration_EndUser_Assignment.target.level = 'Assignment'
#endregion

$policySettings = @()

$policySettings += $Expiration_EndUser_Assignment

$policyObject.properties.rules = $policySettings
$policyObject.properties.rules

#region update policy 
$policyUpdate = $policyObject | ConvertTo-Json -Depth 99
$policyUpdate
Invoke-AzRest -Path "$($resourceId)/providers/Microsoft.Authorization/roleManagementPolicies/$($policyName)?api-version=2020-10-01-preview" -Method PATCH -Payload $policyUpdate
#endregion