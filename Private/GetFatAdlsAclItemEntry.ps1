Function Get-FatAdlsAclItemEntry {
    param(
        [parameter(Mandatory = $true)] [string]$dataLakeStoreName,
        [parameter(Mandatory = $true)] [string]$path

    )
    $aclEntry = Get-AzDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path $path
    return $aclEntry
}