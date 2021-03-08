param($ModulePath, $config)
BeforeAll {
    $CommandName = 'Set-FatAdlsAccess.ps1'
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    if (-not $config) { $config = (Get-Content (join-path $PSScriptRoot '.\config.json') | ConvertFrom-Json) }
    Get-Module adls2.folder.access.tools | remove-module -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/$CommandName)
    Import-Module $CommandNamePath -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/Get-FatCsvAsArray.ps1)
    Import-Module $CommandNamePath -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/Test-FatCsvHeaders.ps1)
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

AfterAll {
    $context = Get-FatAzContextForStorageAccount -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName
    Remove-FatAzDataLakeContainer -ctx $context -ContainerName $config.testContainerName
}


Describe "Set-FatAdlsAccess" -Tag 'Integration' {
    Context "Add Permission to root folder" {
        It "Will Not Throw" {
            [PSCustomObject]$FolderAccess0 = @{Default=$false; Type='Group'; Group='adlsRoot'; Perms='rwx'}
            [PSCustomObject]$FolderAccess1 = @{Default=$true; Type='Group'; Group='adlsRoot'; Perms='r-x'}
            $context = Get-FatAzContextForStorageAccount -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccess.csv
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName $config.testFolderName 
            $zero = @{}
            $folderAccess[0].psobject.properties | ForEach-Object  { $zero[$_.Name] = $_.Value }
            $compare = Compare-Object $zero.Values $FolderAccess0.Values 
            $compare | Should -BeNullOrEmpty
            $one = @{}
            $folderAccess[1].psobject.properties | ForEach-Object  { $one[$_.Name] = $_.Value }
            $compare = Compare-Object $one.Values $FolderAccess1.Values 
            $compare | Should -BeNullOrEmpty
        }
        It "Will Not Throw" {
            Return
        }
    }
}