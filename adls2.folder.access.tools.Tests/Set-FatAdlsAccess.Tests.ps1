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
                [pscustomobject]@{ Container = $config.testContainerName; Folder = '/pes/'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = '/pes/ter/'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
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

            [PSCustomObject]$FolderAccess0 = @{Group = 'adlsRoot'; Perms = 'rwx'; Type = 'Group'; Default = $false }
            $zero = @{}
            $folderAccess[0].psobject.properties | ForEach-Object { $zero[$_.Name] = $_.Value }
            $compare = Compare-Object $zero.Values $FolderAccess0.Values -property "Group", "Perms", "Type", "Default"
            $compare | Should -BeNullOrEmpty
            [PSCustomObject]$FolderAccess1 = @{Group = 'adlsRoot'; Perms = 'r-x'; Type = 'Group'; Default = $true }
            $one = @{}
            $folderAccess[1].psobject.properties | ForEach-Object { $one[$_.Name] = $_.Value }
            $compare = Compare-Object $one.Values $FolderAccess1.Values -property "Group", "Perms", "Type", "Default"
            $compare | Should -BeNullOrEmpty
        }

        It "Access List on Folder is unchanged when using whatif" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccesswhatif.csv
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

        It "Access List on Folder is as expected after re-running same csv" {
            #remove one folder, access should be
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccesssave.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'same'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'same/access'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'same/access/control'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'same/access/control/list'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose
            
            $context = Get-FatAzContextForStorageAccount -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'same/access/control/list' 
            $before = @{}
            $folderAccess[0].psobject.properties | ForEach-Object { $before[$_.Name] = $_.Value }
        
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose
        
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'same/access/control/list' 
            $after = @{}
            $folderAccess[0].psobject.properties | ForEach-Object { $after[$_.Name] = $_.Value }

            $compare = Compare-Object $before.Values $after.Values -property "Group", "Perms", "Type", "Default"
            $compare | Should -BeNullOrEmpty

        }
        
        It "Access List on Folder is as expected after re-running same csv but with removeacls included" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccessremove.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'remove'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'remove/access'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'remove/access/control'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'remove/access/control/list'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose
            
            $context = Get-FatAzContextForStorageAccount -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'remove/access/control/list' 
            $before = @{}
            $folderAccess[0].psobject.properties | ForEach-Object { $before[$_.Name] = $_.Value }
        
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose -removeacls
        
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'remove/access/control/list' 
            $after = @{}
            $folderAccess[0].psobject.properties | ForEach-Object { $after[$_.Name] = $_.Value }

            $compare = Compare-Object $before.Values $after.Values -property "Group", "Perms", "Type", "Default"
            $compare | Should -BeNullOrEmpty

        }

        It "Add group to folder with default acl but not access; add different group to child folder; check permissions for access on child folder for first team should have default and access filled in" {
            $context = Get-FatAzContextForStorageAccount -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccesschildfolder.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'new'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'new/folder'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = ''; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath

            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose
            
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'new/folder' 
            $before = @{}
            $folderAccess[0].psobject.properties | ForEach-Object { $before[$_.Name] = $_.Value }
            
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'new'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'new/folder'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = ''; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'new/folder/child'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
    
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose
        
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'new/folder/child' 
            $after = @{}
            $folderAccess[1].psobject.properties | ForEach-Object { $after[$_.Name] = $_.Value }
            $compare = Compare-Object $before $after -property "Group", "Perms", "Type", "Default"
            $compare | Should -BeNullOrEmpty

            $zero = @{}
            $folderAccess[0].psobject.properties | ForEach-Object { $zero[$_.Name] = $_.Value }
            [PSCustomObject]$FolderAccess0 = @{Group = 'adlsOutput'; Perms = 'rwx'; Type = 'Group'; Default = $false }
            $compare = Compare-Object $zero.Values $FolderAccess0.Values -property "Group", "Perms", "Type", "Default"
            $compare | Should -BeNullOrEmpty
        }

        It "Mock Query AAD for ACL ID as not provided in CSV" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccess.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'query'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'query/for'; ADGroup = $config.testAADGroupName; ADGroupID = ''; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'query/for/acl'; ADGroup = $config.testAADGroupName; ADGroupID = ''; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
            )
            Mock Get-FatCachedAdGroupId {
                Return @{Id = $config.testAADGroupId }
            }
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            { Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose } | Should -Not -Throw
            Assert-MockCalled Get-FatCachedAdGroupId -Exactly 2
        }
    }
}

Describe "Set-FatAdlsAccess" -Tag 'Integration' {
    Context "Mock ACLs" {
        It "Mock Update ACls Recursively" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccess.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'update'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'True' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'update'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'True' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'update/recursively'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'True' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'update/recursively'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'True' }
            
            )
            Mock Update-AzDataLakeGen2AclRecursive {
                Return
            }
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            { Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose } | Should -Not -Throw
            Assert-MockCalled Update-AzDataLakeGen2AclRecursive -Exactly 2
        }

        It "Update ACls Recursively" {
            $expectedSecondRun = @(
                [pscustomobject]@{Group = 'adlsOutput'; Perms = 'rwx'; Type = 'Group'; Default = $False; SideIndicator = '=>' }
                [pscustomobject]@{Group = 'adlsOutput'; Perms = 'rwx'; Type = 'Group'; Default = $True; SideIndicator = '=>' }
                [pscustomobject]@{Group = 'adlsOutput'; Perms = 'r-x'; Type = 'Group'; Default = $False; SideIndicator = '<=' }
                [pscustomobject]@{Group = 'adlsOutput'; Perms = 'r-x'; Type = 'Group'; Default = $True; SideIndicator = '<=' }
            )
            $csvPath = Join-Path $PSScriptRoot csvs/updateaaclrecurse.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively/folder'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively/folder/permissions'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively/folder/permissions/on'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively/folder/permissions/on/existing'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively/folder/permissions/on/existing/folders'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'insert/recursively/folder/permissions/on/existing/folders' 
            $folderAccess = $folderAccess | Where-Object { $_.Group -eq $config.testAADGroupName2 }

            [PSCustomObject]$FolderAccess0 = @{Group = 'adlsOutput'; Perms = 'r-x'; Type = 'Group'; Default = $false }
            $firstRunAccess = @{}
            $folderAccess[0].psobject.properties | ForEach-Object { $firstRunAccess[$_.Name] = $_.Value }
            $compare = Compare-Object $firstRunAccess.values $FolderAccess0.Values -property "Group", "Perms", "Type", "Default"
            $compare | Should -BeNullOrEmpty

            [PSCustomObject]$FolderAccess1 = @{Group = 'adlsOutput'; Perms = 'r-x'; Type = 'Group'; Default = $true }
            $firstRunDefault = @{}
            $folderAccess[1].psobject.properties | ForEach-Object { $firstRunDefault[$_.Name] = $_.Value }
            $compare = Compare-Object $firstRunDefault.values $FolderAccess1.Values -property "Group", "Perms", "Type", "Default"
            $compare | Should -BeNullOrEmpty
        
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'True' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively/folder'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively/folder/permissions'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively/folder/permissions/on'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively/folder/permissions/on/existing'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'insert/recursively/folder/permissions/on/existing/folders'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose
            $folderAccessRecurse = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'insert/recursively/folder/permissions/on/existing/folders' 
            $folderAccessRecurse = $folderAccessRecurse | Where-Object { $_.Group -eq $config.testAADGroupName2 }
            $actual = Compare-Object $folderAccess $folderAccessRecurse -property "Group", "Perms", "Type", "Default"
            $compare = Compare-Object $actual $expectedSecondRun -property "Group", "Perms", "Type", "Default"
            $compare | Should -BeNullOrEmpty
        }

        
        It "Update ACls Recursively; but with whatif no change" {
            $csvPath = Join-Path $PSScriptRoot csvs/updateaaclrecurse.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively/folder'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively/folder/permissions'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively/folder/permissions/on'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively/folder/permissions/on/existing'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively/folder/permissions/on/existing/folders'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'winsert/recursively/folder/permissions/on/existing/folders' 
            $folderAccess = $folderAccess | Where-Object { $_.Group -eq $config.testAADGroupName2 }

            [PSCustomObject]$FolderAccess0 = @{Group = 'adlsOutput'; Perms = 'r-x'; Type = 'Group'; Default = $false }
            $firstRunAccess = @{}
            $folderAccess[0].psobject.properties | ForEach-Object { $firstRunAccess[$_.Name] = $_.Value }
            $compare = Compare-Object $firstRunAccess.values $FolderAccess0.Values -property "Group", "Perms", "Type", "Default"
            $compare | Should -BeNullOrEmpty

            [PSCustomObject]$FolderAccess1 = @{Group = 'adlsOutput'; Perms = 'r-x'; Type = 'Group'; Default = $true }
            $firstRunDefault = @{}
            $folderAccess[1].psobject.properties | ForEach-Object { $firstRunDefault[$_.Name] = $_.Value }
            $compare = Compare-Object $firstRunDefault.values $FolderAccess1.Values -property "Group", "Perms", "Type", "Default"
            $compare | Should -BeNullOrEmpty

            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'True' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively/folder'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively/folder/permissions'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively/folder/permissions/on'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively/folder/permissions/on/existing'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'winsert/recursively/folder/permissions/on/existing/folders'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -Verbose -whatif
            $folderAccessRecurse = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'winsert/recursively/folder/permissions/on/existing/folders' 
            $folderAccessRecurse = $folderAccessRecurse | Where-Object { $_.Group -eq $config.testAADGroupName2 }
            $actual = Compare-Object $folderAccess $folderAccessRecurse -property "Group", "Perms", "Type", "Default"
            $actual | Should -BeNullOrEmpty
        }
    }
}

Describe "Set-FatAdlsAccess" -Tag 'Integration' {
    Context "Checking ALDS2 Context" {

        It "UseConnectedAccount Will Not Throw" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccessnotthrow.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = '/pes/'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = '/pes/ter/'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            Mock New-AzStorageContext {
                $ctx = Get-FatAzContextForStorageAccount -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName
                return $ctx
            }
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            { Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -UseConnectedAccount } | Should -Not -Throw
            Assert-MockCalled New-AzStorageContext -Exactly 1
        }

        It "no context will throw" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccessnotthrow.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = '/pes/'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = '/pes/ter/'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            Mock New-AzStorageContext {
                $ctx = $null
                return $ctx
            }
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            { Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -UseConnectedAccount } | Should -Throw
            Assert-MockCalled New-AzStorageContext -Exactly 1
        }
    } 
}

Describe "Set-FatAdlsAccess" -Tag 'Integration' {
    Context "Removing Groups Permissions" {

        It "two groups on one folder; remove one group and set removeacls; group should be removed" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccessnotthrow.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'addgroup'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'addgroup/thenremove'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'addgroup/thenremove'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl"
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'addgroup/thenremove' 
            $folderAccess.Length | Should -BeExactly 4

            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'addgroup'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'addgroup/thenremove'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -removeacls
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'addgroup/thenremove' 
            $folderAccess.Length | Should -BeExactly 2
        }
        
        It "one group on one folder; remove folder entry; should still be on acl" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccessnotthrow.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'group'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'group/thenremove'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl"
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'group/thenremove' 
            $folderAccess.Length | Should -BeExactly 2

            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'group'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -removeacls
            $folderAccessAfter = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'group/thenremove' 
            $folderAccessAfter.Length | Should -BeExactly 2
            $folderAccessAfter | Should -Match $folderAccess
        }
        
        It "remove group by using ---;" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccessnotthrow.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'twostep'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'twostep/removalprocess'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl"
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'twostep/removalprocess' 
            $folderAccess.Length | Should -BeExactly 2

            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'twostep'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'twostep/removalprocess'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = '---'; AccessPermission = '---'; Recurse = 'False' }    
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl" -removeacls
            $folderAccessAfter = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'twostep/removalprocess' 
            $folderAccessAfter | Should -BeNullOrEmpty
        }

        It "remove group by using --- even without removeacl switch;" {
            $csvPath = Join-Path $PSScriptRoot csvs/setfataccessnotthrow.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'twostep'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'twostep/removalprocess'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'rwx'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl"
            $folderAccess = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'twostep/removalprocess' 
            $folderAccess.Length | Should -BeExactly 2

            $csvEntries = @(
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'ttwostep'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
                [pscustomobject]@{ Container = $config.testContainerName; Folder = 'ttwostep/removalprocess'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = '---'; AccessPermission = '---'; Recurse = 'False' }    
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $csv = Get-FatCsvAsArray -csvPath $csvPath
            Set-FatAdlsAccess -subscriptionName $config.subscriptionName -resourceGroupName $config.resourceGroupName -dataLakeStoreName $config.dataLakeName -aclFolders $csv -entryType "acl"
            $folderAccessAfter = Get-FatAclDetailsOnFolder -ctx $context -ContainerName $config.testContainerName -FolderName 'ttwostep/removalprocess' 
            $folderAccessAfter | Should -BeNullOrEmpty
        }
    }
}