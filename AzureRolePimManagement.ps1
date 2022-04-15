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
#eend region