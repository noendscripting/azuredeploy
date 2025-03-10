param (
    [string]$stringToSearch
)

[xml]$analyzerMasterConfig = Get-Content "C:\DevOpsRepo\ServicesHub-Solutions\Solutions.Azure\Packages\Azure.IdentityAndAccess.Analysis\MasterConfig.xml"




$analyzerNameId = ($analyzerMasterConfig.IPConfiguration.Analyzers.Analyzer | Where-Object { $_.Name -like  "*$($stringToSearch)" }).settings.argContentDefinition.DefaultValue

Write-Host $analyzerNameId