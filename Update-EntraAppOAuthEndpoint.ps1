<#
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
    .SYNOPSIS
    Updates the requestedAccessTokenVersion for specified applications in Microsoft Entra ID (Azure AD).
    .DESCRIPTION
    This script updates the requestedAccessTokenVersion property for one or more applications in Microsoft Entra ID (Azure AD).
    The requestedAccessTokenVersion property is used to specify the version of the access token that the application should request.
    .PARAMETER AppId
    The unique identifier of the application to update. If not specified, all applications in the tenant will be updated.
    .EXAMPLE
    Update-EntraAppOAuthEndpoint.ps1 -AppId "59961cba-0ff3-487c-9376-215ea0a9e5ff"
    Updates the requestedAccessTokenVersion for the specified application with the given AppId.
    .EXAMPLE
    Update-EntraAppOAuthEndpoint.ps1
    Updates the requestedAccessTokenVersion for all applications in the tenant.
    .EXAMPLE
    '59961cba-0ff3-487c-9376-215ea0a9e5ff' | Update-EntraAppOAuthEndpoint.ps1
    Updates the requestedAccessTokenVersion for the specified application with the given AppId by piping the AppId to the script.
    
    #>



#Requires -Modules @{ ModuleName="Microsoft.Graph.Applications"; ModuleVersion="2.25.0"}
#Requires -Modules @{ ModuleName="Microsoft.Graph.Authentication"; ModuleVersion="2.25.0"}
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
    [string]$AppId
    
)

$ErrorActionPreference = "Stop"

$tenantId = (Get-MgContext).TenantId

if ([string]::IsNullOrEmpty($AppId) ){
    Write-Verbose "No AppId provided, retrieving all applications in the tenant."
    # Retrieve all applications in the tenant
    $AppId = $AppId = (Get-MgApplication -All).AppId
    
} 
    

$requiredAccessTokenVersion = @{
    
        requestedAccessTokenVersion = 2
    
}
foreach ($app in $AppId) {
    Write-Verbose "Updating requestedAccessTokenVersion for AppId: $($app)"
    Update-MgApplicationByAppId -AppId $app -Api $requiredAccessTokenVersion -ErrorAction Stop | Out-Null
    
}