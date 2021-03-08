if ( $null -ne (Get-AzContext)) {
    Write-Host "Connected to Azure."
    Get-AzContext
}
else {
    Connect-AzAccount
}

Function New-FatAzDataLakeContainer {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)][PSCustomObject]$ctx,
        [parameter(Mandatory = $true)][string]$ContainerName
    )
    do {
        Start-Sleep -Seconds 2
            $container = Get-AzStorageContainer -Context $ctx -Name $ContainerName -ErrorAction SilentlyContinue -ErrorVariable nocontainer | Out-Null
    }
    until ($nocontainer)
    Do {
        Start-Sleep -Seconds 2
        $container = $null 
        New-AzStorageContainer -Context $ctx -Name $ContainerName -ErrorVariable container -ErrorAction SilentlyContinue
    }
    until
    ($container.Exception.Status -ne 409 )
}

Function Remove-FatAzDataLakeContainer {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)][PSCustomObject]$ctx,
        [parameter(Mandatory = $true)][string]$ContainerName
    )
    Remove-AzStorageContainer -Context $ctx -Name $ContainerName -Force -ErrorAction SilentlyCOntinue | Out-Null
    do {
        Start-Sleep -Seconds 2
        $delete = Get-AzStorageContainer -Context $ctx -Name $ContainerName -ErrorAction SilentlyContinue -ErrorVariable nocontainer | Out-Null
    } until ($nocontainer)
}

Function Get-FatAzContextForStorageAccount {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)][string]$resourceGroupName,
        [parameter(Mandatory = $true)][string]$dataLakeStoreName
    )
    $ErrorActionPreference = "Stop"
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $dataLakeStoreName
    $ctx = $storageAccount.Context
    return $ctx
}

Function Get-FatAclDetailsOnFolder {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)][PSCustomObject]$ctx,
        [parameter(Mandatory = $true)][string]$ContainerName,
        [parameter(Mandatory = $true)][string]$FolderName
    )
    $Gen2Item = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $ContainerName -Path $FolderName
    $aclList = [Collections.Generic.List[System.Object]]($Gen2Item.ACL)
    
    Return ($aclList | Where-Object { @("User", "Group") -contains $_.AccessControlType -and $null -ne $_.EntityId } | `
            ForEach-Object { 
            $ADGroup = Get-FatCachedAdGroupName -ObjectId $_.EntityId
            $ADGroupDisplayName = $ADGroup.DisplayName
            [PSCustomObject]@{Default = $_.DefaultScope;
                Type                  = "$($_.AccessControlType)";
                Group                 = $ADGroupDisplayName; 
                Perms                 = $_.GetSymbolicRolePermissions()
            } 
        } )
}