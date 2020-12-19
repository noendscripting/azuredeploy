Function add-vertix ($data, $dbParams) {
    
    $headers = ($data | Get-member -MemberType 'NoteProperty').Name
    
    foreach ($item in $data) {
    
        $query = "g.addV('trustee')"
    
        foreach ($header in $headers) {
            $query += ".property('$($header)','$(($item.$header).Replace("\","\\"))')"
        }

        Invoke-Gremlin @dbParams -query $query
    

    }
}

Function add-edge ($data, $dbParams)
{
    foreach ($item in $data) {
    
        #$query = "g.V().hasLabel('trustee').has('GUID','$($item.Member)').addE('memberof').to(g.V().hasLabel('trustee').has('GUID','$($item.Group)').property('memberGUID','$($item.Member)').property('groupGUID','$($item.Group)'))"
        $query = "g.V().hasLabel('trustee').has('GUID','$($item.Member)').as('a').V().hasLabel('trustee').has('GUID','$($item.Group)').addE('memberof').from('a').property('memberGUID','$($item.Member)').property('groupGUID','$($item.Group)')"
        Write-Host $query
        Invoke-Gremlin @dbParams -query $query
    }
}


$hostname = "aclxray-db.gremlin.cosmos.azure.com"
$authKey = ConvertTo-SecureString -AsPlainText -Force -String 'owCMlxAeOeYgZK6GQXD6Mk1Mj0gZf8bVxA5ufwRZf7dEeaouwxztGbUKID7kEAiSlpBvTf2IOaQmmEJNrEjrJQ=='
$database = "aclxrayDB"
$collection = "aclxray"

$gremlinParams = @{
    Hostname   = $hostname
    Credential = New-Object System.Management.Automation.PSCredential "/dbs/$database/colls/$collection", $authKey
}

$dataVertix = Import-Csv C:\Temp\ACLXRAYData\eucontosodc1.eu.contosoad.com_Trustees.csv
add-vertix $dataVertix $gremlinParams
$dataEdge = Import-Csv "C:\Temp\ACLXRAYData\eucontosodc1.eu.contosoad.com_GroupExpandedPrincipals.csv","C:\Temp\ACLXRAYData\eucontosodc1.eu.contosoad.com_GroupMembers.csv","C:\Temp\ACLXRAYData\eucontosodc1.eu.contosoad.com_GroupExpandedPrincipals.csv"
add-edge $dataEdge $gremlinParams



