param($ModulePath, $config)
BeforeAll {
    $CommandName = 'Measure-FatGroupNameLength.ps1'
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    if (-not $config) { $config = (Get-Content (join-path $PSScriptRoot '.\config.json') | ConvertFrom-Json) }
    
    Get-Module adls2.folder.access.tools | remove-module -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/$CommandName)
    Import-Module $CommandNamePath -Force

    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/Get-FatCsvAsArray.ps1)
    Import-Module $CommandNamePath -Force

    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/Test-FatCsvHeaders.ps1)
    Import-Module $CommandNamePath -Force
}

Describe "Check Group Lengths" {
    it "Should accept valid lengths" {
        $GroupNames = [PSCustomObject]@{
            ADGroup = 'Bob'
        }
        { Measure-FatGroupNameLength -GroupName $GroupNames.ADGroup } | Should -Not -Throw
    }

    it "Should reject lengths greater than 120 chars and throw" {
        { 
            $GroupNames = [PSCustomObject]@{
                ADGroup = 'asdfasdfasdfgsdfgsdsdfdsfadfafasdfasdfadsfsdfasdfsdfasdfasdfsadfasdfasfgfdsghdhjfghjhdfghdghfggdfgfdghghjfghjdfghsdfghfdsghdhdfhsghdfghdf'
            }
            Measure-FatGroupNameLength -GroupName $GroupNames.ADGroup } | Should -Throw
    }

    it "Should reject empty strings and throw" {
        {
            $GroupNames = [PSCustomObject]@{
                ADGroup = ''
            }
            Measure-FatGroupNameLength -GroupName $GroupNames.ADGroup } |  Should -Throw
    }

    it "should work with csv" {
        $csvPath = Join-Path $PSScriptRoot csvs/measuregroupnames.csv
        $csvEntries = @(
            [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
            [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what/is'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
            [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what/is/going'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
            [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what/is/going/on'; ADGroup = $config.testAADGroupName; ADGroupID = $config.testAADGroupId; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
            [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
            [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what/is'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
            [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what/is/going'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'r-x'; Recurse = 'False' }
            [pscustomobject]@{ Container = $config.testContainerName; Folder = 'what/is/going/on'; ADGroup = $config.testAADGroupName2; ADGroupID = $config.testAADGroupId2; DefaultPermission = 'r-x'; AccessPermission = 'rwx'; Recurse = 'False' }
        )
        $csvEntries | Export-Csv -Path $csvpath -UseQuotes Never
        { $csv = Get-FatCsvAsArray -csvPath $csvPath } | Should -Not -Throw
            
    }
}


