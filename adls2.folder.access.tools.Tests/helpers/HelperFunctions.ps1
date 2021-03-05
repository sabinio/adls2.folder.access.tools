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
    New-AzStorageContainer -Context $ctx -Name $ContainerName 
}

Function Remove-FatAzDataLakeContainer {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)][PSCustomObject]$ctx,
        [parameter(Mandatory = $true)][string]$ContainerName
    )
    Remove-AzStorageContainer -Context $ctx -Name $ContainerName -Force
    do {
        Start-Sleep -Seconds 2
        $delete = Get-AzStorageContainer -Context $ctx -Name $ContainerName -ErrorAction Continue -ErrorVariable nocontainer
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