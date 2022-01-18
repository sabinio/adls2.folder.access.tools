param($ModulePath, $config)
BeforeAll {
    $CommandName = 'Measure-FatGroupNameLength.ps1'
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    
    Get-Module adls2.folder.access.tools | remove-module -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/$CommandName)
    Import-Module $CommandNamePath -Force
}

Describe "Check Group Lengths" {
    it "Should accept valid lengths" {
        { Measure-FatGroupNameLength -GroupName "bob" } | Should -Not -Throw
    }

    it "Should reject lengths greater than 64 chars and throw" {
        { Measure-FatGroupNameLength -GroupName "asdfasdfasdfgsdfgsdfgfdsghdhjfghjhdfghdghfggdfgfdghghjfghjdfghsdfghfdsghdhdfhsghdfghdf" } | Should -Throw
        $GroupNames = @("oieurtueriotiwe[rtp[oitrt[pyurtpoyiurtoysdfgsdfgsfdirtuyoirtuyerotpyurtopyi", "asdfasdfasdfgsdfgsdfgfdsghdhjfghjhdfghdghfggdfgfdghghjfghjdfghsdfghfdsghdhdfhsghdfghdf")
        { Measure-FatGroupNameLength -GroupName $GroupNames } | Should -Throw
        $GroupNames = @("asdf", "qwerasdfasdfasdfgsdfgsdfgfdsghdhjfghjhdfghdghfggdfgfdghghjfghjdfghsdfghfdsghdhdfhsghdfghdf")
        { Measure-FatGroupNameLength -GroupName $GroupNames } | Should -Throw
    }

    it "Should reject empty strings and throw" {
        { Measure-FatGroupNameLength -GroupName "" } |  Should -Throw
    }
}



