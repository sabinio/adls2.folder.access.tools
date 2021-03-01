param($ModulePath)

BeforeAll {
    $CommandName = 'Get-FatCachedAdGroupId.ps1'
    Get-Module adls2.folder.access.tools | remove-module
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/$CommandName)
    Import-Module $CommandNamePath -Force    
    $global:AdGroupCache = @{}
}

Describe "Get-FatCachedAdGroupId" -Tag 'Unit' {
    Context 'Get' {
        It "Group Exists" {
            Mock Get-AzADGroup {
                Return @{Id = '9acd586e-688d-41f6-9dfb-d593941884a3' }
            }
            $groupName = Get-FatCachedAdGroupId -DisplayName 'FakeGroup'
            $groupName.Id -eq "9acd586e-688d-41f6-9dfb-d593941884a3"
            Assert-MockCalled Get-AzADGroup -Exactly 1
        }
    }
}
