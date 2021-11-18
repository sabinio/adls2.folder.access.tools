param($ModulePath, $config)
BeforeAll {
    $CommandName = 'Set-FatAdlsAclEntryOnItem.ps1'
    if (-not $ModulePath) { $ModulePath = join-path (join-path $PSScriptRoot "..") "adls2.folder.access.tools" }
    
    Get-Module adls2.folder.access.tools | remove-module -Force
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Private/$CommandName)
    Import-Module $CommandNamePath -Force

    . (Join-Path $ModulePath "Private" "Get-FatCachedAdGroupId.ps1" )
    . (Join-Path $ModulePath "Private" "Get-FatCachedAdGroupName.ps1")
}

AfterAll {
}

Describe "Set-FatAdlsAclEntryOnItem" -Tag 'Integration' {
    BeforeAll{
    }
    Context "Can handle duplicate groups in AAD" {
        It "Will Not Throw" {
            Mock Get-AzDataLakeGen2Item { @{Acl=new-object Collections.Generic.List[System.Object] }  }
            Mock set-AzDataLakeGen2ItemAclObject {@()}
            Mock Update-AzDataLakeGen2Item 
            Mock Update-AzDataLakeGen2AclRecursive
            Mock Get-FatCachedAdGroupName {"foo"}
            Mock  Get-FatCachedAdGroupId {@(@{Id=New-Guid},@{Id=New-Guid})}
            $ctx = New-AzStorageContext "ds" -Anonymous

$entry= [PSCustomObject]@{Container = "ContainerName"; Folder = "FolderName"; Items = @(@{ADGroup="SomGroup";DefaultPermission="rwx";AccessPermission="rwx"}) }

            {Set-FatAdlsAclEntryOnItem -subscriptionName "Name Of Subscription"  `
                -dataLakeStoreName "data lake store name"  `
                -aclEntry $entry `
                -ctx $ctx } | should -Throw "Cannot determine group. Found 2 duplicate entries. See previous output for resolution options."

                
                }
    }
}