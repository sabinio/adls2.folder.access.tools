param($ModulePath)

BeforeAll {
    $CommandName = 'Get-FatDataLake.ps1'

    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    Get-Module adls2.folder.access.tools | remove-module
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/$CommandName)
    Import-Module $CommandNamePath -Force
}
Describe '$CommandName' -Tag 'Unit' {
    Context 'Checking data lake exists' {
        It "DataLake does not exist" {
            Mock Test-AzDataLakeStoreAccount {
                Return $null
            }
            $resourcegroupname = "resourcegroupname"
            $datalakename = "datalakename"
            $testresult =  Get-FatDataLake -resourceGroupName $resourcegroupname -dataLakeName $datalakename 
            $testresult | Should -Be $null
            Assert-MockCalled Test-AzDataLakeStoreAccount -Exactly 1
        }
    }
}



