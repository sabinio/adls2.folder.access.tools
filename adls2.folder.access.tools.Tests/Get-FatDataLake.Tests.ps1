param($ModulePath)

BeforeAll {
    $CommandName = 'Get-FatDataLake.ps1'
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    Get-Module adls2.folder.access.tools | remove-module
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/$CommandName)
    Import-Module $CommandNamePath -Force
}
Describe "Get-FatDataLake" -Tag 'Unit' {
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

        It "DataLake does not exist" {
            Mock Test-AzDataLakeStoreAccount {
                $result = "exists"
                Return $result
            }

            Mock Get-AzDataLakeStoreAccount{
                $result = "exists"
                Return $result
            }
            $resourcegroupname = "resourcegroupname"
            $datalakename = "datalakename"
            $testresult =  Get-FatDataLake -resourceGroupName $resourcegroupname -dataLakeName $datalakename 
            $testresult | Should -BeExactly "exists"
            Assert-MockCalled Test-AzDataLakeStoreAccount -Exactly 1
            Assert-MockCalled Get-AzDataLakeStoreAccount -Exactly 1
        }

    }
}

