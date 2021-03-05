param($ModulePath, $config)
BeforeAll {
    $CommandName = 'Set-FatAdlsAccess.ps1'
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    if (-not $config) {$config = (Get-Content (join-path $PSScriptRoot '.\config.json') | ConvertFrom-Json)}
    Get-Module adls2.folder.access.tools | remove-module -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/$CommandName)
    Import-Module $CommandNamePath -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/Set-FatAdlsAclEntryOnItem.ps1)
    Import-Module $CommandNamePath -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/Get-FatCachedAdGroupId.ps1)
    Import-Module $CommandNamePath -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/Get-FatCachedAdGroupName.ps1)
    Import-Module $CommandNamePath -Force
    $helpers = join-path $PSScriptRoot helpers\HelperFunctions.ps1
    Import-Module $helpers -Force
    $context = Get-FatAzContextForStorageAccount -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName
    New-FatAzDataLakeContainer -ctx $context -ContainerName $config.testContainerName
}

AfterAll{
    
    $context = Get-FatAzContextForStorageAccount -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName
    Remove-FatAzDataLakeContainer -ctx $context -ContainerName $config.testContainerName
}


Describe "Set-FatAdlsAccess" -Tag 'Integration' {
    Context "Add Permission to root folder" {
        It "Will Not Throw" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccess.csv
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose
        }

        It "Will Not Throw" {
            Return
        }
    }
}
