param($ModulePath)
$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools\Public" }
Get-Module adls2.folder.access.tools | remove-module
. $ModulePath/$CommandName.ps1

BeforeAll {
    $csvPath = Join-Path $PSScriptRoot csvs/dummy.csv
}

Describe 'Discovery example' {
    Context 'Some tests' {
        It "$MyVariable is true" {
            { Get-FatCsvAsArray -csvPath $csvPath } | Should -Not -Throw
        }
    }
}
