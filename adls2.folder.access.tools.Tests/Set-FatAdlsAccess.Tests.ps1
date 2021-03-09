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
    Context "Add Permission to folders" {
        It "Will Not Throw" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccessnotthrow.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'pes'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'pes/ter'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
               )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            { Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" } | Should -Not -Throw
        }
    
        It "Access List on Folder is as expected" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccess.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what/is'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what/is/going'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what/is/going/on'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose
        
            $context = Get-FatAzContextForStorageAccount -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName $config.testFolderName 

            [PSCustomObject]$FolderAccess0 = @{Group = 'adlsRoot'; Perms = 'rwx'; Type = 'Group'; Default = $false}
            $zero = @{}
            $folderAccess[0].psobject.properties | ForEach-Object {$zero[$_.Name] = $_.Value}
            $compare = Compare-Object $zero.Values $FolderAccess0.Values 
            $compare | Should -BeNullOrEmpty
            [PSCustomObject]$FolderAccess1 = @{Group = 'adlsRoot'; Perms = 'r-x'; Type = 'Group'; Default = $true}
            $one = @{}
            $folderAccess[1].psobject.properties | ForEach-Object {$one[$_.Name] = $_.Value}
            $compare = Compare-Object $one.Values $FolderAccess1.Values 
            $compare | Should -BeNullOrEmpty
        }

        It "Access List on Folder is as expected" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccess.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'whatif'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'whatif/makes'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'whatif/makes/no'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'whatif/makes/no/changes'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose -whatif
        
            $context = Get-FatAzContextForStorageAccount -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'whatif/makes/no/changes' 
            $folderAccess | Should -BeNullOrEmpty
        }
    }
}