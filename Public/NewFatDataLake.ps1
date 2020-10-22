Function New-FatDataLake {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)][string]$resourceGroupName,
        [parameter(Mandatory = $true)][string]$dataLakeName,
        [parameter(Mandatory = $true)][string]$Location
    )

    Get-AzResourceGroup -Name $resourceGroupName -ErrorVariable noResourceGroup4U -ErrorAction SilentlyContinue
    if ($noResourceGroup4U) {
        Write-Verbose "Creating Resource Group $resourceGroupName"
        New-AzResourceGroup -Name $resourceGroupName -Location $Location
    }
    else {
        Write-Verbose "ResourceGroup with the name $resourceGroupName already exists."
    }
    $noDataLake4U = Test-AzDataLakeStoreAccount -resourceGroupName $resourceGroupName -Name $dataLakeName
    if ($nodatalake4u -eq $false) {
        Write-Verbose "Creating Azure DataLake $dataLakeName"
        New-AzDataLakeStoreAccount -Name $dataLakeName -resourceGroupName $resourceGroupName -Location $Location
    }
    else {
        Write-Verbose "Azure DataLake with the name $dataLakeName already exists."
    }
}