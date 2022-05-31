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
  [string[]]$role,
  [string]$resourceId,
  [string]$apiVersion='2020-10-01'
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
$subscriptionId = $resourceId.Split("/")[2]
$roleDefenitionId = (Get-AzRoleDefinition -Name $role -Scope $Id).Id
$filter = '$filter'
#region collect current policy settings
$policyResult = (Invoke-AzRest -Path "$($resourceId)/providers/Microsoft.Authorization/roleManagementPolicies?api-version=$($apiVersion)&$filter=roleDefinitionId%20eq%20'$($resourceId)/providers/Microsoft.Authorization/roleDefinitions/$($roleDefenitionId)'" -Method GET).Content | ConvertFrom-Json
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

#$policyObject.properties.rules
#endregion

#region update policy 
$policyUpdate = $policyObject | ConvertTo-Json -Depth 99
Invoke-AzRest -Path "$($resourceId)/providers/Microsoft.Authorization/roleManagementPolicies/$($policyName)?api-version=$($apiVersion)" -Method PATCH -Payload $policyUpdate
#endregion



