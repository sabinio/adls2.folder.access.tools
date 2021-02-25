Function Test-FatAADGroupsExist {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] $csvPath
    )

    $ADGroups = @{}

    $csvPath = Resolve-Path $csvPath
    $myCsv = import-csv $csvPath
    $ADGroupNames = $myCsv | Select-Object -ExpandProperty ADGroup -Unique
    foreach ($ADGroupName in $ADGroupNames) { 
        Write-Host "Testing that"$ADGroupName"exists in Azure Active Directory"
        $ADGroupId = (Get-FatCachedAdGroupId -DisplayName $ADGroupName).Id
        $ADGroups.Add($ADGroupName, $ADGroupId)
    }
    $notFoundGroups = @{}
    $notFoundGroups = $AdGroups.GetEnumerator() | Where-Object { -not $_.Value }
    if ($notFoundGroups.count -gt 0) {
        Write-Host "The following groups were not found -"
        Foreach ($Name in $notFoundGroups.Name)
        {Write-Host "$Name"}
        Throw
    }
}

