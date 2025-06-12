
$repoRoot = "C:\DevOpsRepo\ServicesHub-Solutions"

$collectorsPath= Join-Path $repoRoot "Solutions.Azure\Packages\Azure.IdentityandAccess.Collection\*"
$analyzersMasterPath = Join-Path $repoRoot "Solutions.Azure\Packages\Azure.IdentityAndAccess.Analysis\MasterConfig.xml"
$assessmentMapping = New-Object System.Collections.ArrayList
$analyzerMapping = @{}
$scriptMaster = @{}

# Get the list of collector files, list of script files and the analyzers master config file
$collectorXMLList = Get-childitem -Path $collectorsPath -Include *.xaml
$collectorPSList = Get-childitem -Path $collectorsPath -Include *.ps1
$analyzerMaster =[xml](Get-Content -Path $analyzersMasterPath) 

# Get names of the collector files, associated pwoershell script and analyzer node name
$collectorXMLList | ForEach-Object {
    Write-Progress -Status "Processing" -CurrentOperation "Parsing file" -Activity "Reading file $($_.Name)" -PercentComplete (($collectorXMLList.IndexOf($_) / $collectorXMLList.Count) * 100)
    $file = $_.FullName
    $collectorConfig = [xml](Get-Content -Path $file)
    
   $collectorData =  ($collectorConfig.Activity.IterateNodes.ActivityAction.Sequence.DataCollectorActivity.'DataCollectorActivity.Arguments'.InArgument | Where-Object {$_.key -eq 'ScriptSource' -or $_.key -eq 'DataNodeName'}).'#text'
   If ([string]::IsNullOrEmpty($collectorData))
   {
    $collectorData = @("Not Found","Not Found")
   }
   elseif ([string]::IsNullOrEmpty($collectorData[0]))
   {
   $collectorData[0] = "Not Found"
   }
   elseif ([string]::IsNullOrEmpty($collectorData[1]))
   {
    $collectorData[1] = "Not Found"
    }

    
        $item = @{
            ScriptName = $collectorData[0]
            AnalyzerNodeName = $collectorData[1]
            ContentId = [string]::Empty
            CollectorConfigFile = $_.Name
        }
        $assessmentMapping += $item
            
    
 
   
    Clear-Variable -Name file, xml, collectorData, item -ErrorAction SilentlyContinue
}


# Create hash table of analyzer node name and contentId from the analyzers master config file
$analyzerMaster.SelectNodes("//Settings")| ForEach-Object {
 $analyzerName = $_.argDataNodeName.DefaultValue
  $contentId = $_.argContentDefinition.DefaultValue
if (!($analyzerMapping.ContainsKey($analyzerName)))
{
    $analyzerMapping.Add($analyzerName,$contentId) | Out-Null
} 
   clear-variable -Name analyzerName, contentId, index -ErrorAction SilentlyContinue
    
}

$collectorPSList | ForEach-Object {
    
    $file = $_.Name
    $scriptMaster.add($file,[string]::Empty) | Out-Null
    Clear-Variable -Name file -ErrorAction SilentlyContinue
}




#match Analyzer node name with contentId from the analyzers master config file and update the contentId in the assessment mapping array
foreach ($assessment in $assessmentMapping) {
    
Write-Progress -Status "Processing" -CurrentOperation "Updating contentId" -Activity "updating contentId for $($assessment.scriptName)" -PercentComplete (($assessmentMapping.IndexOf($assessment) / $assessmentMapping.Count) * 100)
    $analyzerNode = $assessment.analyzerNodeName
    if ($analyzerMapping.ContainsKey($analyzerNode)) {
        $assessment.contentId = $analyzerMapping[$analyzerNode]
    } else {
        $assessment.contentId = "Not Found"
    }

}
   
#identify scripts missing from the collector files and update the contentId in the assessment mapping array
foreach ($assessment in $assessmentMapping) {
    Write-Progress -Status "Processing" -CurrentOperation "Updating contentId" -Activity "updating contentId for $($assessment.scriptName)" -PercentComplete (($assessmentMapping.IndexOf($assessment) / $assessmentMapping.Count) * 100)
    $scriptName = $assessment.scriptName
    if ($scriptMaster.Contains($scriptName)) {
        continue
    } else  {
        $item = @{
            ScriptName = $scriptName
            AnalyzerNodeName = "Not Found"
            ContentId = "Not Found"
            CollectorConfigFile = "Not Found"
        }
        $assessmentMapping += $item
    }
    Clear-Variable -Name scriptName, item -ErrorAction SilentlyContinue
}
Write-Output   $assessmentMapping 