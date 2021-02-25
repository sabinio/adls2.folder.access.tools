Function Get-FatDataLake {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)][string]$resourceGroupName,
        [parameter(Mandatory = $true)][string]$dataLakeName
    )
    $noDataLake4U = $null
    $noDataLake4U = Test-AzDataLakeStoreAccount -resourceGroupName $resourceGroupName -Name $dataLakeName
    if ($null -eq $nodatalake4u ) {
        Write-Host "No datalake with name $dataLakeName in Resource Group $resourceGroupName found. Please create by calling 'New-FatDataLake'."
        Return $null
    }
    else {
        Write-Verbose "Azure DataLake with the name $dataLakeName exists."
        $DataLakeStoreAccount = Get-AzDataLakeStoreAccount -ResourceGroupName $resourceGroupName -Name $dataLakeName
        return $DataLakeStoreAccount
    }
}