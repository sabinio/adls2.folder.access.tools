
BeforeAll {
    $CommandName = 'Test-FatCsvHeaders.ps1'
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    Get-Module adls2.folder.access.tools | remove-module
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/$CommandName)
    Import-Module $CommandNamePath -Force
}

Describe "Test-FatCsvHeaders" -Tag 'Unit' {
    Context 'Valid Headers' {
        It "Function does not throw" {
            $csvPath = Join-Path $PSScriptRoot csvs/dummy.csv
            {Test-FatCsvHeaders -csvPath $csvPath } | Should -Not -Throw
        }
        It "Function does not throw" {
            $csvPath = Join-Path $PSScriptRoot csvs/wrongheaders.csv
            {Test-FatCsvHeaders -csvPath $csvPath} | Should -Throw 
        }
    }
}


