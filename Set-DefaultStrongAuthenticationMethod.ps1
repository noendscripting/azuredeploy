<#
.SYNOPSIS
Script is created to change default MFA auth method of indvidual user
.DESCRIPTION
Script uses MSonline powershell module to set default MFA auth method to either SMS or Phone
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
.PARAMETER userprincipalName
UserPrincipalName of the user who's defaults will be changed. Mandatory Parameter
.PARAMETER autheticationMethod
Authetication method that is will be set to default. Mandatory parameter. Allows only two values "TwoWayVoiceMobile","OneWaySMS"
.EXAMPLE
Set SMS as default Authentication method
./Set-DefaultStrongAuthenticationMethod -userprincipalName <myuser@mydomain.test> -autheticationMethod OneWaySMS
#>



#Requires -Modules @{ ModuleName="MSOnline"; ModuleVersion="1.1.183.66"}
[CmdletBinding()]

param
(
    [Parameter(Mandatory=$true)]
    $userprincipalName,
    [Parameter(Mandatory=$true)]
    [ValidateSet("TwoWayVoiceMobile","OneWaySMS")]
    $autheticationMethod

)

function create-AuthMethodObject
{
    param
    (
        $autheMethodObject,
        $default

    )

    $method = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
    $method.IsDefault = $default
    $method.MethodType = $autheMethodObject.MethodType

    return $method

}

$methodArray = @()

Connect-MsolService

$user = Get-MsolUser -UserPrincipalName $userprincipalName

$authmethods = $user.StrongAuthenticationMethods

ForEach ( $authmethod in $authmethods)
{
    If ($authmethod.MethodType -eq $autheticationMethod)
    {
        $methodArray += create-AuthMethodObject -autheMethodObject $authmethod -default $true
    }
    else
    {
        $methodArray += create-AuthMethodObject -autheMethodObject $authmethod -default $false
    }

}

$user | Set-MsolUser -StrongAuthenticationMethods $methodArray
