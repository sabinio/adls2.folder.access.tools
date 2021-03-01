param($ModulePath)

BeforeAll {
    $CommandName = 'Get-FatCachedAdGroupName.ps1'
    Get-Module adls2.folder.access.tools | remove-module
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/$CommandName)
    Import-Module $CommandNamePath -Force    
    $global:AdGroupCache = @{}
}

Describe "Get-FatCachedAdGroupName" -Tag 'Unit' {
    Context 'Get' {
        It "Group Exists" {
            Mock Get-AzADGroup {
                Return @{DisplayName = 'FakeGroup' }
            }
            $groupName = Get-FatCachedAdGroupName -objectId '9acd586e-688d-41f6-9dfb-d593941884a3'
            $groupName.DisplayName -eq "FakeGroup"
            Assert-MockCalled Get-AzADGroup -Exactly 1
        }
    }
}
