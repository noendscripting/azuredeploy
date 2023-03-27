
[CmdletBinding()]

param()

$configData = (select-String -Pattern '^-.|.-.' -Path .\test.yml -AllMatches).Line
$parserStack = New-Object System.Collections.Stack
$indentIndex = 0
$deidentIndex = 0

foreach ($configLine in $configData)
{
    $spacesCount = ($confuigLine | Select-String "^\s+").Length
    Write-Verbose "Line $($configLine) has $($spacesCount) space(s) in front"
    if ($spacesCount -eq $indentIndex)
    {
        $parserStack.Push($configLine)
    }
    elseif ($spacesCount -gt $indentIndex ) {
        $deidentIndex = $indentIndex
        $indentIndex = $spacesCount
        $parserStack.Pop()
        $parserStack.Push($configLine)
       
    }

}



