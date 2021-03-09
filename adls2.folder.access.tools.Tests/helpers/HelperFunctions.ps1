if ( $null -ne (Get-AzContext)) {
    Write-Host "[Helper] - Connected to Azure."
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
    Write-Host "[Helper] - Checking if Container $ContainerName exists before attempting to create..."
    $getCounter = 0
    do {
        Start-Sleep -Seconds 3
        $getCounter ++
        Write-Verbose "[Helper] - Running Get-AzStorageContainer attempt $getCounter of 10..."
        $container = Get-AzStorageContainer -Context $ctx -Name $ContainerName -ErrorAction SilentlyContinue -ErrorVariable nocontainer | Out-Null
    }
    until ($nocontainer -or $getCounter -eq 10)
    if ($newCounter -eq 10) {
        Write-Error "[Helper] - Something has gone wrong in running Get-AzStorageContainer in New-FatAzDataLakeContainer"
    }
    Write-Host "[Helper] - Attempting to create Container $ContainerName..."
    $newCounter = 0
    Do {
        Start-Sleep -Seconds 3
        $newCounter ++
        if ($newCounter -gt 1) {
            Write-Host "[Helper] - Creation failed because container is being deleted from previous test run. Re-attempt running New-AzStorageContainer $newCounter of 10 ..."
        }
        else {
            Write-Verbose "[Helper] - Running New-AzStorageContainer..."
        }
        New-AzStorageContainer -Context $ctx -Name $ContainerName -ErrorVariable container -ErrorAction SilentlyContinue
    }
    until
    ($container.Exception.Status -ne 409 -or $newCounter -eq 10 )
    if ($newCounter -eq 10) {
        Write-Error "[Helper] - Something has gone wrong in running New-AzStorageContainer in New-FatAzDataLakeContainer"
    }
}

Function Remove-FatAzDataLakeContainer {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)][PSCustomObject]$ctx,
        [parameter(Mandatory = $true)][string]$ContainerName
    )
    $getCounter = 0
    Write-Host "[Helper] - Attempting to remove Container $ContainerName..."
    Remove-AzStorageContainer -Context $ctx -Name $ContainerName -Force -ErrorAction SilentlyCOntinue | Out-Null
    do {
        Write-Verbose "[Helper] - Running Get-AzStorageContainer attempt $getCounter of 10..."
        Start-Sleep -Seconds 3
        Get-AzStorageContainer -Context $ctx -Name $ContainerName -ErrorAction SilentlyContinue -ErrorVariable nocontainer | Out-Null
    } until ($nocontainer -or $getCounter -eq 10 )
    if ($getCounter -eq 10) {
        Write-Error "[Helper] - Something has gone wrong in Remove-FatAzDataLakeContainer"
    }
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