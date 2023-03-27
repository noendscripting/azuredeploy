enum ensure {
    Absent
    Present
}

<#
    This class is used within the DSC Resource to standardize how data
    is returned about the compliance details of the machine. Note that
    the class name is prefixed with the module name - this helps prevent
    errors raised when multiple modules with DSC Resources define the
    Reasons property for reporting when they're out-of-state.
#>
class MyDscResourceReason {
    [DscProperty()]
    [string] $Code

    [DscProperty()]
    [string] $Phrase
}

<#
   Public Functions
#>

Get-Share {
    param(
        [ensure]$ensure,
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$,

    )


}