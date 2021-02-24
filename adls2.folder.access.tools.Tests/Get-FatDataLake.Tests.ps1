param($ModulePath)

BeforeAll {
    $CommandName = 'Get-FatDataLake'
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    Get-Module adls2.folder.access.tools | remove-module
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/$CommandName)
    Import-Module $CommandNamePath -Force

}
