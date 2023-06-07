

$workbook = get-content "./Vulnerability Assessment Findings (Custom).workbook" | convertfrom-json -depth 99

#? update queries in workbook with new lines

for($i=0; $i -lt $workbook.items.length; $i++) {
    $workbook.items[$i]
    If (!($workbook.items[$i].content.query -like "securityresources*")) {
        continue
    }
    $queryArray = $workbook.items[$i].content.query.split("|")
    $updatesQuertyArray = @($queryArray[0..3])+@("$([char]32)extend resourceId = properties.resourceDetails.Id`r`n")+@("$([char]32)where resourceId in ({ResourceList})`r`n")+@($queryArray[4..$queryArray.length])
    $newquery = $updatesQuertyArray -join "|"
    $workbook.items[$i].content.query = $newquery
    $workbook.items[$i].content.query
}

$workbook | convertto-json -depth 99 | set-content '.\Vulnerability Assessment Findings (Custom) Tags.workbook'
