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


[cmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$groupName,
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [string]$Id
)

#region Classes
class ScheduleInfo {
    [string]$StartDateTime # format "2020-09-09T21:31:27.91Z"
    [Expiration]$Expiration = [Expiration]::New()
  }
  class Expiration {
    [string]$Type  # Values: AfterDuration, AfterDateTime, NoExpiration
    [string]$EndDateTime
    [string]$Duration  #"P365D"  Use ISO 8601 format
  }
#endrgeion


Write-Debug $Id
exit
$filter = '$filter'
$select = '$select'

$groupData = (Invoke-AzRestMethod -Uri "https://graph.microsoft.com/v1.0/groups?$($filter)=startswith(displayName, '"$($groupName)"'&$($select)=id").Content | ConvertFrom-Json -Depth 99
$groupObjectId = $groupData.value.id

$roleEligibilityScheduleRequestName = (new-guid).Guid



$eligibilityScheduleObject = [EligibilityAssignment]::New()


$eligibilityScheduleObject.properties.PrincipalId = $groupObjectId
$eligibilityScheduleObject.properties.RoleDefinitionId="/subscriptions/$($subscriptionId)/providers/Microsoft.Authorization/roleDefinitions/$($roleDefenitionId)"
$eligibilityScheduleObject.properties.ScheduleInfo.StartDateTime = Get-Date -UFormat %Y-%m-%eT%T.%SZ
$eligibilityScheduleObject.properties.ScheduleInfo.Expiration.Type='NoExpiration'

Invoke-AzRest -Path "$($resourceId)/providers/Microsoft.Authorization/roleEligibilityScheduleRequests/$($roleEligibilityScheduleRequestName)?api-version=2020-10-01-preview" -Method PUT -Payload $assignmentPayload
