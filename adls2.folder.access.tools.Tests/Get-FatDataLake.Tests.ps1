param($ModulePath, $config)
BeforeAll {
    $CommandName = 'Get-FatDataLake.ps1'
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    if (-not $config) {$config = (Get-Content '.\config.json' | ConvertFrom-Json)}
    Get-Module adls2.folder.access.tools | remove-module
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/$CommandName)
    Import-Module $CommandNamePath -Force
}
Describe "Get-FatDataLake" -Tag 'Unit' {
    Context 'Checking data lake exists' {
        It "DataLake does not exist" {
            Mock Get-AzStorageAccount {
                Throw
            }
            $resourcegroupname = "resourcegroupname"
            $datalakename = "datalakename"
            {Get-FatDataLake -resourceGroupName $resourcegroupname -dataLakeName $datalakename} | Should -Throw 
        }

        It "DataLake does exist" {
            Mock Get-AzStorageAccount {
                $result = "exists"
                Return $result
            }
            $resourcegroupname = "resourcegroupname"
            $datalakename = "datalakename"
            $testresult = Get-FatDataLake -resourceGroupName $resourcegroupname -dataLakeName $datalakename 
            $testresult | Should -BeExactly "exists"
            Assert-MockCalled Get-AzStorageAccount -Exactly 1
        }
    }
}


Describe "Get-FatDataLake" -Tag 'Integration' {
    Context 'Checking data lake exists' {
        It "DataLake does exist" {
            $testresult = Get-FatDataLake -resourceGroupName $config.resourceGroupName -dataLakeName $config.dataLakeName 
            $testresult.StorageAccountName | Should -Be "fatadls"
            $testresult.ResourceGroupName | Should -Be "fat"
            $testresult.Kind | Should -Be "StorageV2"
        }

        It "DataLake does not exist" {
            $testresult = Get-FatDataLake -resourceGroupName $config.resourceGroupName -dataLakeName "noexist"
            $testresult | Should -Be $null
        }
    }
}
