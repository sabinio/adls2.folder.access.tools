Function Get-FatDataLake {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)][string]$resourceGroupName,
        [parameter(Mandatory = $true)][string]$dataLakeName
    )
    Write-Verbose "Azure DataLake with the name $dataLakeName exists."
    $DataLakeStoreAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $dataLakeName -ErrorVariable nodatalake4u -ErrorAction Continue
    if ($nodatalake4u) {
        Write-Host "No Storage Account called $dataLakeName found in Resource Group $resourceGroupName"
    }
    return $DataLakeStoreAccount
}