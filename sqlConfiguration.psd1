@{
    AllNodes = @(

    @{
            NodeName="localhost"
			RetryCount = 20
            RetryIntervalSec = 30
            PSDscAllowPlainTextPassword=$true
			PSDscAllowDomainUser = $true
         }

    )
 }