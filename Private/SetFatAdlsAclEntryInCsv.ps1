Function Set-FatAdlsAclEntryInCsv {
    param(
        [parameter(Mandatory = $true)] [System.IO.StreamWriter] $csvStreamWriter,
        [parameter(Mandatory = $true)] [String] $Folder,
        [parameter(Mandatory = $true)] [String] $ADGroupDisplayName,
        [parameter(Mandatory = $true)] [String] $ADGroupID,
        [parameter(Mandatory = $true)] [String] $Permission,
        [parameter(Mandatory = $true)] [String] $IncludeInDefault,
        [parameter(Mandatory = $false)] [String] $recurse
        
    )
    #$writeLine = '{0}, {1}, {2}, {3}, {4}, {5}' -f $Folder, $ADGroupDisplayName, $ADGroupID, $Permission, $IncludeInDefault, $recurse
    $writeLine = '{0}, {1}, {2}, {3}, {4}' -f $Folder, $ADGroupDisplayName, $ADGroupID, $Permission, $IncludeInDefault
    Write-Verbose ('Writing into csv {0}' -f $writeLine)
    $csvStreamWriter.WriteLine(('{0}' -f $writeLine))
}