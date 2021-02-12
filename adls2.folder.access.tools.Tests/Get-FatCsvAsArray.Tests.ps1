
Set-Location $PSScriptRoot
Import-Module "..\adls2.folder.access.tools\adls2.folder.access.tools\public\Get-FatCsvAsArray.ps1" -Force

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
