Function Get-FatAdlsFolderPermissions {
    param(
        [parameter(Mandatory = $true)] [string]$dataLakeStoreName,
        [parameter(Mandatory = $true)] [string]$path,
        [parameter(Mandatory = $true)] [System.IO.StreamWriter] $csvStreamWriter,
        [parameter(Mandatory = $false)] [switch]$recurse
        
    )
    try {
        Write-Host "Verifying $path exists on $dataLakeStoreName..."
        Get-AzDataLakeStoreItem -AccountName $dataLakeStoreName -Path $path | Out-Null
    }
    catch {
        
        Write-Error "Folder not found!"
        Return
    }
    Write-Host "Acquiring permissions for $path"
    $aces = @()
    $aceGroups = @()
    $aces = Get-AzDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path $path 
    $aceGroups = $aces | Where-Object { $_.Type -in ("Group", "Other", "User") } #| Where-Object { $_.Id -ne "" }
    $aceGroups = $aceGroups | Sort-Object @{Expression = "Id"; Descending = $False }, @{Expression = "Scope"; Descending = $False }
    $aceGroups | Format-Table
    for ($i = 0; $i -lt $aceGroups.Count; $i++) {
        $msgGroupDisplayName = "Retrieving GroupDisplayName for " + $($aceGroups[$i].Id)
        Write-Verbose $msgGroupDisplayName
        Write-Verbose $aceGroups[$i].Entry
        $ADGroup = Get-AzADGroup -ObjectId $aceGroups[$i].Id
        if ($aceGroups[$i].Scope -eq "Access") {
            $j = $i + 1
            if (($aceGroups[$i].Id -ne $aceGroups[$j].Id) -or ($aceGroups[$i].Permission -notmatch $aceGroups[$j].Permission)) {
                Set-FatAdlsAclEntryInCsv -csvStreamWriter $csvStreamWriter -Folder $path -ADGroupDisplayName $ADGroup.DisplayName -ADGroupId $aceGroups[$i].Id -Permission $aceGroups[$i].Permission -IncludeInDefault "False" #-Recurse "True"
            } 
            else {
                Write-Verbose "Skipping as next entry in acl is to set $($ADGroup.DisplayName) as default so no need add `"Access`" entry..."
                
            }
        } 
        else {
            Set-FatAdlsAclEntryInCsv -csvStreamWriter $csvStreamWriter -Folder $path -ADGroupDisplayName $ADGroup.DisplayName -ADGroupId $aceGroups[$i].Id -Permission $aceGroups[$i].Permission -IncludeInDefault "True" #-Recurse "True"
        }
    }
    if ($PSBoundParameters.ContainsKey('recurse') -eq $true) {
        $datalakeStoreItems = Get-AzDataLakeStoreChildItem -AccountName $dataLakeStoreName -Path $path | Where-Object { $_.Type -eq "Directory" }
        Foreach ($dataLakeStoreItem in $datalakeStoreItems) {
            Write-Verbose "Getting permissions for subfolder $($dataLakeStoreItem.Path)"
            Get-FatAdlsFolderPermissions -dataLakeStoreName $dataLakeStoreName -path $dataLakeStoreItem.Path -csvStreamWriter $csvStreamWriter -recurse
        }
    }
}