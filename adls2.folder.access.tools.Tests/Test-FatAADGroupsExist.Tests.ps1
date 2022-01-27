param($ModulePath, $config)

BeforeAll {
    $CommandName = 'Test-FatAADGroupsExist.ps1'
    if (-not $config) { $config = (Get-Content (join-path $PSScriptRoot '.\config.json') | ConvertFrom-Json) }
    Get-Module adls2.folder.access.tools | remove-module
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/$CommandName)
    Import-Module $CommandNamePath -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/Get-FatCachedAdGroupId.ps1)
    Import-Module $CommandNamePath -Force
    
}

Describe "Test-FatAADGroupsExist" -Tag 'Unit' {
    Context 'Checking groups exist' {
        It "Group Exists" {
            $csvPath = Join-Path $PSScriptRoot csvs/dummy.csv

            $csvEntries = @(
                [pscustomobject]@{ Container = 'lake'; Folder = 'output'; ADGroup = 'adlsRoot'; ADGroupID = '80024941-9710-47d2-8be9-f06f4389620f'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output'; ADGroup = 'adlsOutput'; ADGroupID = '16050cad-cf12-4c2d-9ba8-57a7553184a5'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process'; ADGroup = 'adlsProcess'; ADGroupID = 'b8243406-018c-4129-9fcb-f965e916d835'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process2'; ADGroup = 'adlsProcess'; ADGroupID = 'b8243406-018c-4129-9fcb-f965e916d835'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'raw'; ADGroup = 'adlsRaw'; ADGroupID = '5b6fd483-9acc-4978-9b0f-352eebf234a7'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            Mock Get-FatCachedAdGroupId {
                Return @{Id = '9acd586e-688d-41f6-9dfb-d593941884a3' }
            }
            Test-FatAADGroupsExist -csvPath $csvPath
            Assert-MockCalled Get-FatCachedAdGroupId -Exactly 4
        }

        It "Group Does Not Exists" {
            #             lake,/raw2/howabout, thisgroupnotexist,, rwx,r-x, True
            # lake,/raw2/howabout, thisgroupnotexistaswell,,r-x, rwx, True
            $csvPath = Join-Path $PSScriptRoot csvs/missinggroup.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = 'lake'; Folder = 'output'; ADGroup = 'adlsRoot'; ADGroupID = '80024941-9710-47d2-8be9-f06f4389620f'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output'; ADGroup = 'adlsOutput'; ADGroupID = '16050cad-cf12-4c2d-9ba8-57a7553184a5'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process'; ADGroup = 'adlsProcess'; ADGroupID = 'b8243406-018c-4129-9fcb-f965e916d835'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process2'; ADGroup = 'adlsProcess'; ADGroupID = 'b8243406-018c-4129-9fcb-f965e916d835'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'raw'; ADGroup = 'adlsRaw'; ADGroupID = '5b6fd483-9acc-4978-9b0f-352eebf234a7'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process2'; ADGroup = 'noexist'; ADGroupID = ''; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'raw'; ADGroup = 'noexisteither'; ADGroupID = ''; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            Mock Get-FatCachedAdGroupId {
                Return @{Id = $null }
            }
            { Test-FatAADGroupsExist -csvPath $csvPath } | Should -Throw
            Assert-MockCalled Get-FatCachedAdGroupId -Exactly 6
        }

        It "Group Does Not Exists; Continue On Missing Groups" {
            #             lake,/raw2/howabout, thisgroupnotexist,, rwx,r-x, True
            # lake,/raw2/howabout, thisgroupnotexistaswell,,r-x, rwx, True
            $csvPath = Join-Path $PSScriptRoot csvs/missinggroup.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = 'lake'; Folder = 'output'; ADGroup = 'adlsRoot'; ADGroupID = '80024941-9710-47d2-8be9-f06f4389620f'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output'; ADGroup = 'adlsOutput'; ADGroupID = '16050cad-cf12-4c2d-9ba8-57a7553184a5'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process'; ADGroup = 'adlsProcess'; ADGroupID = 'b8243406-018c-4129-9fcb-f965e916d835'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process2'; ADGroup = 'adlsProcess'; ADGroupID = 'b8243406-018c-4129-9fcb-f965e916d835'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'raw'; ADGroup = 'adlsRaw'; ADGroupID = '5b6fd483-9acc-4978-9b0f-352eebf234a7'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process2'; ADGroup = 'noexist'; ADGroupID = ''; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'raw'; ADGroup = 'noexisteither'; ADGroupID = ''; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            Mock Get-FatCachedAdGroupId {
                Return @{Id = $null }
            }
            { Test-FatAADGroupsExist -csvPath $csvPath -continueOnNonExistingGroup } | Should -Not -Throw
            Assert-MockCalled Get-FatCachedAdGroupId -Exactly 6
        }

        It "Group Does Not Exists; Continue On Missing Groups" {
            #             lake,/raw2/howabout, thisgroupnotexist,, rwx,r-x, True
            # lake,/raw2/howabout, thisgroupnotexistaswell,,r-x, rwx, True
            $csvPath = Join-Path $PSScriptRoot csvs/missinggroup.csv
            $csvEntries = @(
                [pscustomobject]@{ Container = 'lake'; Folder = 'output'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process2'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'raw'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process2'; ADGroup = 'noexist'; ADGroupID = ''; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
                [pscustomobject]@{ Container = 'lake'; Folder = 'raw'; ADGroup = 'noexisteither'; ADGroupID = ''; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            )
            $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
            $Result = Test-FatAADGroupsExist -csvPath $csvPath -continueOnNonExistingGroup 
            $Result.Length | Should -BeExactly 2
        }
    }
}



