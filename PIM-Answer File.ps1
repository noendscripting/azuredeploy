



$configData = (select-String -Pattern '^(?!.*#).*$' -Path .\test.yml -AllMatches).Line

$mymatches = $configData | Select-String -Pattern '^[\-].*' -AllMatches

for ($classEntry = 0;$classEntry -lt $mymatches.Length; $classEntry++){
    write-host "Starting values for $($mymatches[$classEntry].Line.Split(':')[1])"
    if ($classEntry -eq ($mymatches.Length - 1))
    {
        $endofClass = ($configData.Length)
    }
    else {
        $endofClass = ($mymatches[$classEntry+1].LineNumber - 1)
    }
    for ($configEntry = $mymatches[$classEntry].LineNumber; $configEntry -lt $endofClass; $configEntry++)
    {
        [array]$objectProperties += $configData[$configEntry].Replace(" -","")


        
       
        
       
        

    }
    $title = $mymatches[$classEntry].Line.Split(':')[1].Replace('"','')
    switch -Exact ($mymatches[$classEntry].Line.Split(':')[1].Replace('"',''))
    {
        "Activation maximum duration (hours)" {
            Write-Host "Expiration_EndUser_Assignment found"
            Break
    }
    "On activation, require"{
        Write-Host "Enablement_EndUser_Assignment found"
        Break
    }
    "Require approval to activate"{
        Write-Host "Approval_EndUser_Assignment found"
        Break
    }
}
    $objectProperties
    Clear-Variable objectProperties
Write-Host "---------------"


}
