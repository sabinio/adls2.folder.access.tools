Function Get-FatCsvAsArray {
    param(
        [parameter(Mandatory = $true)] [string]$csvPath,
        [parameter(Mandatory = $false)] [switch]$RecurseOnly
    )
    $csvPath = Resolve-Path $csvPath
    Test-FatCsvHeaders -csvPath $csvPath
    $myCsv = Import-Csv $csvPath
    $GroupNameList = $myCsv | Select-Object ADGroup -Unique
    Measure-FatGroupNameLength -GroupNameList $GroupNameList
    If ($PSBoundParameters.ContainsKey('RecurseOnly')) {
        $myCsv = $myCsv | Where-Object -Property Recurse -eq "True" | Group-Object Container, Folder, Recurse | ForEach-Object { [pscustomobject]@{Container = $_.Name.split(",")[0].Trim(); Folder = $_.Name.split(",")[1].Trim(); Recurse = $_.Name.split(",")[2].Trim(); Items = $_.Group } }
    }
    else {
        $myCsv = $myCsv | Where-Object -Property Recurse -in "True", "False" | Group-Object Container, Folder, Recurse | ForEach-Object { [pscustomobject]@{Container = $_.Name.split(",")[0].Trim(); Folder = $_.Name.split(",")[1].Trim(); Recurse = $_.Name.split(",")[2].Trim(); Items = $_.Group } }
    }
    return $myCsv
}