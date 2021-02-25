param($ModulePath)

BeforeAll {
    $CommandName = 'Test-FatAADGroupsExist.ps1'
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
            Mock Get-FatCachedAdGroupId {
                Return @{Id = '9acd586e-688d-41f6-9dfb-d593941884a3' }
            }
            Test-FatAADGroupsExist -csvPath $csvPath
            Assert-MockCalled Get-FatCachedAdGroupId -Exactly 4
        }

        It "Group Does Not Exists" {
            $csvPath = Join-Path $PSScriptRoot csvs/missinggroup.csv
            Mock Get-FatCachedAdGroupId {
                Return @{Id = $null }
            }
            {Test-FatAADGroupsExist -csvPath $csvPath} | Should -Throw
            Assert-MockCalled Get-FatCachedAdGroupId -Exactly 6
        }
    }
}



