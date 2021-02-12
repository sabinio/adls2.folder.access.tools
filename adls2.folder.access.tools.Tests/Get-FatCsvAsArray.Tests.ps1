param($ModulePath)

BeforeAll {
    $csvPath = Join-Path $PSScriptRoot csvs/dummy.csv
    $CommandName = 'Get-FatCsvAsArray.ps1'
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    Get-Module adls2.folder.access.tools | remove-module
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/$CommandName)
    Import-Module $CommandNamePath

}

Describe 'Discovery example' {
    Context 'Some tests' {
        It "$MyVariable is true" {
            { Get-FatCsvAsArray -csvPath $csvPath } | Should -Not -Throw
        }
    }
}
