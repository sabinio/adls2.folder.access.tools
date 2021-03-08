param($ModulePath)

BeforeAll {
    $csvPath = Join-Path $PSScriptRoot csvs/array.csv

    $csvEntries = @(
        [pscustomobject]@{ Container = 'lake'; Folder = 'output'; ADGroup = 'adlsRoot'; ADGroupID = '80024941-9710-47d2-8be9-f06f4389620f'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
        [pscustomobject]@{ Container = 'lake'; Folder = 'output'; ADGroup = 'adlsOutput'; ADGroupID = '16050cad-cf12-4c2d-9ba8-57a7553184a5'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
        [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process'; ADGroup = 'adlsProcess'; ADGroupID = 'b8243406-018c-4129-9fcb-f965e916d835'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
        [pscustomobject]@{ Container = 'lake'; Folder = 'output2/process2'; ADGroup = 'adlsProcess'; ADGroupID = 'b8243406-018c-4129-9fcb-f965e916d835'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
        [pscustomobject]@{ Container = 'lake'; Folder = 'raw'; ADGroup = 'adlsRaw'; ADGroupID = '5b6fd483-9acc-4978-9b0f-352eebf234a7'; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
    )
    $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
    $csvPath = Join-Path $PSScriptRoot csvs/array.csv
    $CommandName = 'Get-FatCsvAsArray.ps1'
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    Get-Module adls2.folder.access.tools | remove-module
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/$CommandName)
    Import-Module $CommandNamePath -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/Test-FatCsvHeaders.ps1)
    Import-Module $CommandNamePath -Force
}

Describe "Get-FatCsvAsArray" -Tag 'Unit' {
    Context 'Using valid CSV' {
        It "Function does not throw" {
            { Get-FatCsvAsArray -csvPath $csvPath } | Should -Not -Throw
        }
        It "Recurse only results does not throw" {
            { Get-FatCsvAsArray -csvPath $csvPath -RecurseOnly } | Should -Not -Throw
        }
    }
}
