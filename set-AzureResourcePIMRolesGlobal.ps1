<#
.DESCRIPTION
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
 
 
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$role = "Contributor",
    [string]$resourceId = "/subscriptions/87008fdf-ae91-4584-b623-7ecb86459002/resourceGroups/AADBkup-RG/providers/Microsoft.Storage/storageAccounts/aadbkup",
    [string]$apiVersion = '2020-10-01'
)
  
  

#$ErrorActionPreference = 'Stop'


#region Classes




Class ruleType {
    [string]$RoleManagementPolicyEnablementRule = "RoleManagementPolicyEnablementRule"
    [string]$RoleManagementPolicyExpirationRule = "RoleManagementPolicyExpirationRule"
    [string]$RoleManagementPolicyNotificationRule = "RoleManagementPolicyNotificationRule"
    [string]$RoleManagementPolicyApprovalRule = 'RoleManagementPolicyApprovalRule'
    [string]$RoleManagementPolicyAuthenticationContextRule = 'RoleManagementPolicyAuthenticationContextRule'
}

Class Caller {
    [string]$Admin = "Admin"
    [string]$Enduser = "EndUser"
}

Class Approver {
    [string]$id
    [string]$description
    [string]$isBackup
    [ValidateSet('Group', 'User')]
    [string]$userType
}

class Target {
    [string]$caller 
    [string[]]$operations = @("All")
    [string]$level
   #[object]$targetObjects = $null
   #[object]$enforcedSettings = $null
   #[object]$inheritableSettings = $null
}

#class for policy settings array 
class PolicyProperties {
    [array]$rules 
}

#root class for PIM polciies 
class PolicySettings {
    [PolicyProperties]$properties = [PolicyProperties]::New()
}


Class Expiration_Admin_Eligibility {
    [bool] $isExpirationRequired
    [string] $maximumDuration
    [string] $id = 'Expiration_Admin_Eligibility'
    [string] $ruleType
    [Target] $target = [Target]::New()
}

Class Enablement {
      
    [string[]]$enabledRules = @() # possible values "MultiFactorAuthentication", "Justification","Ticketing"
    [string]$id 
    [string]$ruleType
    [Target]$target = [Target]::New()
    
}


Class Expiration {
    [bool]$isExpirationRequired
    [string]$maximumDuration # must use dateInterval , starting with PT and hours only 
    [string]$id
    [string]$ruleType
    [Target]$target = [Target]::New()
}
Class Approval {
      
    [approvalSetting]$setting = [approvalSetting]::New()
    [string]$id 
    [string]$ruleType
    [Target]$target = [Target]::New()

}

class Notification {
    [string] $id
    [string] $ruleType
    [string] $notificationType = "Email"
    [ValidateSet('Approver','Requestor','Admin')]
    [string] $recipientType
    [string] $notificationLevel
    [bool] $isDefaultRecipientsEnabled
    [string[]] $notificationRecipients = @()
    [Target]$target = [Target]::New()
}
class approvalStage {
    [int]$approvalStageTimeOutInDays = 1
    [bool]$isApproverJustificationRequired = $true
    [int]$escalationTimeInMinutes = 0
    [bool]$isEscalationEnabled = $false
    [array]$primaryApprovers = @()
    #[array]$escalationApprovers = @()
}
class  approvalSetting {
    [bool]$isApprovalRequired
    [bool]$isApprovalRequiredForExtension = $false
    [bool]$isRequestorJustificationRequired = $true
    [string]$approvalMode = "SingleStage"
    [System.Collections.ArrayList]$approvalStages = @()
}


#endregion
$roleDefenitionId = (Get-AzRoleDefinition -Name $role -Scope $resourceId).Id
Write-Verbose $roleDefenitionId
$filter = '$filter'
#region collect and backup current policy settings

$policyResult = (Invoke-AzRest -Path "$($resourceId)/providers/Microsoft.Authorization/roleManagementPolicies?api-version=$($apiVersion)&$filter=roleDefinitionId%20eq%20'$($resourceId)/providers/Microsoft.Authorization/roleDefinitions/$($roleDefenitionId)'" -Method GET).Content
#backup current policy 
$policyResult | Out-File ./policyResult.json -Force
$policyName = ($policyResult | ConvertFrom-Json).value.name

#region create root policy object
$policyObject = [PolicySettings]::New()
#endregion

#region Setting Role Assignment Rules
$Expiration_Admin_Eligibility = [Expiration_Admin_Eligibility]::New()
$Expiration_Admin_Eligibility.isExpirationRequired = $false
$Expiration_Admin_Eligibility.target.level = 'Eligibility'
#endregion

#region create support class intances

$ruleType = [ruleType]::New()
$caller = [Caller]::New()


#endregion 
#region Setting Activation Rules

#set role duration settings
$Expiration_EndUser_Assignment = [Expiration]::New()
$Expiration_EndUser_Assignment.id = "Expiration_EndUser_Assignment"
$Expiration_EndUser_Assignment.ruleType = "RoleManagementPolicyExpirationRule"
$Expiration_EndUser_Assignment.maximumDuration = "PT240H"
$Expiration_EndUser_Assignment.isExpirationRequired = $true
$Expiration_EndUser_Assignment.target.level = "Assignment"
$Expiration_EndUser_Assignment.target.caller = $caller.Enduser

#set role activation requirments other than approval
$Enablement_EndUser_Assignment = [Enablement]::New()
$Enablement_EndUser_Assignment.enabledRules = @("Justification")
$Enablement_EndUser_Assignment.id = "Enablement_EndUser_Assignment"
$Enablement_EndUser_Assignment.ruleType = "RoleManagementPolicyEnablementRule"
$Enablement_EndUser_Assignment.target.level = "Assignment"
$Enablement_EndUser_Assignment.target.caller = $caller.Admin

#set role activation approval requiements 
$Approval_EndUser_Assignment = [Approval]::New()
$AprrovalStage = [approvalStage]::New()
$Approval_EndUser_Assignment.setting.approvalStages += $AprrovalStage
$Approval_EndUser_Assignment.setting.isApprovalRequired = $true
$Approval_EndUser_Assignment.id = "Approval_EndUser_Assignment"
$Approval_EndUser_Assignment.ruletype = $ruleType.RoleManagementPolicyApprovalRule 
$Approval_EndUser_Assignment.target.level = "Assigniment"
$Approval_EndUser_Assignment.target.caller = $caller.Enduser

#set approvers for the role
[Approver]$Approver1 = [Approver]::New()
$Approver1.description = "GiveMeAccess"
$Approver1.id = "c72990ad-8cf9-45dd-ab9a-016d2dd88c67"
$Approver1.isBackup = $false
$Approver1.userType = "Group"

[Approver]$Approver2 = [Approver]::New()
$Approver2.description = "Beth F. Woodard"
$Approver2.id = "82b18233-7541-4789-a139-f8221174ebb8"
$Approver2.isBackup = $false
$Approver2.userType = "User"

$AprrovalStage.primaryApprovers += $Approver1
$AprrovalStage.primaryApprovers += $Approver2

#region notifications when members are assigned as eligible to this role

#Role assignment alert
$Notification_Admin_Admin_Eligibility = [Notification]::New()
$Notification_Admin_Admin_Eligibility.id = "Notification_Admin_Admin_Eligibility"
$Notification_Admin_Admin_Eligibility.ruleType= $ruleType.RoleManagementPolicyNotificationRule
$Notification_Admin_Admin_Eligibility.isDefaultRecipientsEnabled = $true
$Notification_Admin_Admin_Eligibility.notificationLevel = "All"
$Notification_Admin_Admin_Eligibility.notificationRecipients = @()
$Notification_Admin_Admin_Eligibility.recipientType = "Admin"
$Notification_Admin_Admin_Eligibility.target.caller = $caller.Admin
$Notification_Admin_Admin_Eligibility.target.level = "Assignment"

#set notifications for assigned user(assignee) 
$Notification_Requestor_Admin_Eligibility = [Notification]::New()
$Notification_Requestor_Admin_Eligibility.id = 'Notification_Requestor_Admin_Eligibility'
$Notification_Requestor_Admin_Eligibility.ruleType = $ruleType.RoleManagementPolicyNotificationRule
$Notification_Requestor_Admin_Eligibility.notificationLevel = "All"
$Notification_Requestor_Admin_Eligibility.isDefaultRecipientsEnabled = $true
$Notification_Requestor_Admin_Eligibility.recipientType = "Requestor"
$Notification_Requestor_Admin_Eligibility.notificationRecipients = @()
$Notification_Requestor_Admin_Eligibility.target.caller = $caller.Admin
$Notification_Requestor_Admin_Eligibility.target.level = "Assignment"

#set Request to approve a role assignment renewal/extension
$Notification_Approver_Admin_Eligibility = [Notification]::New()
$Notification_Approver_Admin_Eligibility.id = 'Notification_Approver_Admin_Eligibility'
$Notification_Approver_Admin_Eligibility.ruleType = $ruleType.RoleManagementPolicyNotificationRule
$Notification_Approver_Admin_Eligibility.notificationLevel = "All"
$Notification_Approver_Admin_Eligibility.notificationRecipients = @()
$Notification_Approver_Admin_Eligibility.isDefaultRecipientsEnabled = $true
$Notification_Approver_Admin_Eligibility.recipientType = "Approver"
$Notification_Approver_Admin_Eligibility.target.caller = $caller.Enduser
$Notification_Approver_Admin_Eligibility.target.level = "Assignment"

#endregion

#region notifications when members are assigned as active to this role

#Role assignment alert
$Notification_Admin_Admin_Assignment = [Notification]::New()
$Notification_Admin_Admin_Assignment.id = 'Notification_Admin_Admin_Assignment'
$Notification_Admin_Admin_Assignment.ruleType = $ruleType.RoleManagementPolicyNotificationRule
$Notification_Admin_Admin_Assignment.isDefaultRecipientsEnabled = $true
$Notification_Admin_Admin_Assignment.notificationLevel = "All"
$Notification_Admin_Admin_Assignment.notificationRecipients = @("notifyme@send.com")
$Notification_Admin_Admin_Assignment.recipientType = "Admin"
$Notification_Admin_Admin_Assignment.target.caller = $caller.Admin
$Notification_Admin_Admin_Assignment.target.level = "Assignment" 

#Notification to the assigned user (assignee)
$Notification_Requestor_Admin_Assignment = [Notification]::New()
$Notification_Requestor_Admin_Assignment.id = 'Notification_Requestor_Admin_Assignment'
$Notification_Requestor_Admin_Assignment.ruleType = $ruleType.RoleManagementPolicyNotificationRule
$Notification_Requestor_Admin_Assignment.isDefaultRecipientsEnabled = $true
$Notification_Requestor_Admin_Assignment.notificationLevel = "All"
$Notification_Requestor_Admin_Assignment.notificationRecipients = @()
$Notification_Requestor_Admin_Assignment.recipientType = "Requestor"
$Notification_Requestor_Admin_Assignment.target.caller = $caller.Admin
$Notification_Requestor_Admin_Assignment.target.level = "Assignment" 

#Request to approve a role assignment renewal/extension
$Notification_Approver_Admin_Assignment = [Notification]::New()
$Notification_Approver_Admin_Assignment.id = 'Notification_Approver_Admin_Assignment'
$Notification_Approver_Admin_Assignment.ruleType = $ruleType.RoleManagementPolicyNotificationRule
$Notification_Approver_Admin_Assignment.isDefaultRecipientsEnabled = $true
$Notification_Approver_Admin_Assignment.notificationLevel = "All"
$Notification_Approver_Admin_Assignment.notificationRecipients = @()
$Notification_Approver_Admin_Assignment.recipientType = "Approver"
$Notification_Approver_Admin_Assignment.target.caller = $caller.Admin
$Notification_Approver_Admin_Assignment.target.level = "Assignment"

#endregion

#region notifications when eligible members activate this role

#Role activation alert
$Notification_Admin_EndUser_Assignment = [Notification]::New()
$Notification_Admin_EndUser_Assignment.id = 'Notification_Admin_EndUser_Assignment'
$Notification_Admin_EndUser_Assignment.ruleType = $ruleType.RoleManagementPolicyNotificationRule
$Notification_Admin_EndUser_Assignment.isDefaultRecipientsEnabled = $true
$Notification_Admin_EndUser_Assignment.notificationLevel = "All"
$Notification_Admin_EndUser_Assignment.notificationRecipients = @()
$Notification_Admin_EndUser_Assignment.recipientType = "Admin"
$Notification_Admin_EndUser_Assignment.target.caller = $caller.Enduser
$Notification_Admin_EndUser_Assignment.target.level = "Assignment"

#set Notification to activated user (requestor)
$Notification_Requestor_EndUser_Assignment = [Notification]::New()
$Notification_Requestor_EndUser_Assignment.id = 'Notification_Requestor_EndUser_Assignment'
$Notification_Requestor_EndUser_Assignment.ruleType = $ruleType.RoleManagementPolicyNotificationRule
$Notification_Requestor_EndUser_Assignment.notificationLevel = "All"
$Notification_Requestor_EndUser_Assignment.notificationRecipients = @()
$Notification_Requestor_EndUser_Assignment.isDefaultRecipientsEnabled = $true
$Notification_Requestor_EndUser_Assignment.recipientType = "Requestor"
$Notification_Requestor_EndUser_Assignment.target.caller = $caller.Enduser
$Notification_Requestor_EndUser_Assignment.target.level = "Assignment"

#Request to approve an activation
$Notification_Approver_EndUser_Assignment = [Notification]::New()
$Notification_Approver_EndUser_Assignment.id = 'Notification_Approver_EndUser_Assignment'
$Notification_Approver_EndUser_Assignment.ruleType = $ruleType.RoleManagementPolicyNotificationRule
$Notification_Approver_EndUser_Assignment.isDefaultRecipientsEnabled = $true
$Notification_Approver_EndUser_Assignment.notificationLevel = "All"
$Notification_Approver_EndUser_Assignment.notificationRecipients = @() # must be empty array at all time
$Notification_Approver_EndUser_Assignment.recipientType = "Approver"
$Notification_Approver_EndUser_Assignment.target.caller = $caller.Enduser
$Notification_Approver_EndUser_Assignment.target.level = "Assignment" 


#endregion

#set 





#Role activation alert






#region Creating rules array

$policySettings = @()


$policySettings += $Expiration_Admin_Eligibility
$policySettings += $Enablement_EndUser_Assignment
$policySettings += $Expiration_EndUser_Assignment
$policySettings += $Approval_EndUser_Assignment
$policySettings += $Notification_Requestor_Admin_Eligibility #
$policySettings += $Notification_Requestor_EndUser_Assignment
$policySettings += $Notification_Approver_Admin_Eligibility #
$policySettings += $Notification_Approver_Admin_Assignment
$policySettings += $Notification_Admin_EndUser_Assignment
$policySettings += $Notification_Approver_EndUser_Assignment
$policySettings += $Notification_Requestor_Admin_Assignment
$policySettings += $Notification_Admin_Admin_Eligibility #
$policySettings += $Notification_Admin_Admin_Assignment
$policyObject.properties.rules = $policySettings
#endregion

#region update policy 
$policyUpdate = $policyObject | ConvertTo-Json -Depth 99




Write-Verbose $policyUpdate
Invoke-AzRest -Path "$($resourceId)/providers/Microsoft.Authorization/roleManagementPolicies/$($policyName)?api-version=$($apiVersion)" -Method PATCH -Payload $policyUpdate

#endregion



