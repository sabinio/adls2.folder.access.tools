Function Set-FatAdlsAclEntryOnItem {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)][string]$subscriptionName,
        [parameter(Mandatory = $true)][string]$dataLakeStoreName,
        [parameter(Mandatory = $true)][PSCustomObject]$aclEntry,
        [parameter(Mandatory = $true)][PSCustomObject]$ctx,
        [parameter(Mandatory = $false)][switch]$removeAcls,
        [parameter(Mandatory = $false)][switch]$WhatIf)

    $ErrorActionPreference = "Stop"
    try {
        Write-Host "[*] Setting the ACLs for $($aclEntry.container) $($aclEntry.folder)"  -NoNewLine

        $Gen2Item = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $AclEntry.container -Path $aclEntry.folder
        Write-Verbose "Owner = $($Gen2Item.Owner)"
        $aclList = [Collections.Generic.List[System.Object]]($Gen2Item.ACL)


        Write-Verbose "Current Acl"
        Write-Verbose ($aclList | Where-Object { @("User", "Group") -contains $_.AccessControlType -and $null -ne $_.EntityId } | ForEach-Object { 
                [PSCustomObject]@{Default = $_.DefaultScope;
                    Type = $_.AccessControlType;
                    EntityId = $_.EntityId; Group = (Get-CachedAdGroupName -ObjectId $_.EntityId).DisplayName; Perms = $_.GetSymbolicRolePermissions()
                } 
            } | Format-Table | out-string  )
        Write-Verbose "ACL Entry $($aclEntry.Items.Count)"
        Write-Verbose ($aclEntry.Items | Format-Table | out-string)
        
        if ($removeAcls) {
            Write-Verbose "[***] Checking Acls to remove"
            for ($i = $aclList.Count; $i -gt 0; $i-- ) {
                $currentAcl = $aclList[$i]
                if (@("User", "Group") -contains $currentAcl.AccessControlType -and $null -ne $currentAcl.EntityId) {
                    $ADGroup = Get-CachedAdGroupName -ObjectId $currentAcl.EntityId#
                    Write-Verbose "Looking for Acl for $($currentAcl.EntityId)# $($ADGroup.DisplayName) $($currentAcl.DefaultScope)"

                    $matchingAcls = @($AclEntry.Items | Where-Object { $AdGroup.DisplayName -eq $_.ADGroup })
                    Write-Verbose "Acls matching on Group $($matchingACls.Count)"
                    if ($matchingACls.Count -gt 1) {
                        if ($currentAcl.DefaultScope) {
                            $matchingACls = @($matchingACls | Where-Object { $null -ne $_.DefaultPermission })
                        } 
                        else {
                            $matchingACls = @($matchingACls | Where-Object { $null -ne $_.AccessPermission })
                        } 
                        Write-Verbose "Acls matching on Scope $($matchingACls.Count)"
                    }
 
                    if ($matchingAcls.Count -eq 0) {
                        Write-Output "[*] Removing acl for Group $($ADGroup.DisplayName) from $($AclEntry.Folder)"
                        $aclList.RemoveAt($i) | out-null;
                        Write-Verbose "AclList count = $($aclList.Count)"
                    }
                }
            }
        }
        else { Write-Verbose "Removing Acls set to $false skipping removing of extra acls " }
        
        Write-Verbose "AclList count = $($aclList.Count)"
        Write-Verbose "[***] Checking Acls to Add"

        foreach ( $acl in $aclEntry.Items) { 
            Write-Verbose ($acl | Format-Table | Out-String)
            if ($acl.ADGroupId) {
                $ADGroupId = $acl.ADGroupId
            }
            else {
                Write-Verbose "[*] Getting the GroupId from AAD"
                $ADGroup = Get-CachedAdGroupId -DisplayName $acl.ADGroup
                $ADGroupId = $ADGroup.Id
            }
            if (-not [string]::IsNullOrWhitespace($acl.DefaultPermission)) {
                $aclCountBefore = $aclList.Count
                Write-Verbose "Adding Default Acl $($acl.DefaultPermission) for $AdGroupId ($($acl.AdGroup))"
                $aclList = set-AzDataLakeGen2ItemAclObject -AccessControlType group -EntityID $AdGroupId  -Permission $acl.DefaultPermission -InputObject $aclList -DefaultScope 
                Write-Verbose "Count of Acls before and After $aclCountBefore-$($AclList.Count) "
            }
            if ( -not [string]::IsNullOrWhitespace($acl.AccessPermission)) {
                Write-Verbose "Adding Access Acl $($acl.AccessPermission) for $AdGroupId  ($($acl.AdGroup))"
                $aclList = set-AzDataLakeGen2ItemAclObject -AccessControlType group -EntityID $AdGroupId  -Permission $acl.AccessPermission -InputObject $aclList
                Write-Verbose "Count of Acls before and After $aclCountBefore-$($AclList.Count) "
            }
        }
     
        $aclList = [Collections.Generic.List[System.Object]]($aclList)

        for ($i = $aclList.Count - 1; $i -gt 0; $i-- ) {
            Write-Verbose "Checking for --- permissions $i"
            $currentAcl = $aclList[$i]
            if (@("User", "Group") -contains $currentAcl.AccessControlType -and $null -ne $currentAcl.EntityId) {
                if ($currentAcl.GetSymbolicRolePermissions() -eq '---') {
                    Write-Verbose "Removing --- $((Get-CachedAdGroupName -ObjectId $currentAcl.EntityId).DisplayName) $($currentAcl.DefaultScope)"
                    $aclList.RemoveAt($i) | out-null;    
                }
            }
        }

        Write-Verbose ($aclList | Where-Object { @("User", "Group") -contains $_.AccessControlType -and $null -ne $_.EntityId } | ForEach-Object { 
                [PSCustomObject]@{Default = $_.DefaultScope;
                    Type = $_.AccessControlType;
                    EntityId = $_.EntityId; Group = (Get-CachedAdGroupName -ObjectId $_.EntityId).DisplayName; Perms = $_.GetSymbolicRolePermissions()
                } 
            } | Format-Table | out-string  )
        $Comparison = Compare-Object  $Gen2Item.ACL $aclList -property "EntityId", "Permissions", "AccessControlType", "DefaultScope"
        if ($null -ne $Comparison) {
            write-Host " - Changes $($Comparison.Count)"
            write-Host "<= to be removed, => to be set "
            $Comparison | ForEach-Object { [pscustomObject]@{Permissions = $_.Permissions;
                    Default                                              = $_.DefaultScope;
                    Type                                                 = $_.AccessControlType;
                    Group                                                = (Get-CachedAdGroupName -objectId $_.EntityId).DisplayName;
                    Change                                               = $_.SideIndicator
                } } | Format-Table Group, Type, Default, Permissions, Change

            $UpdateParams = @{
                Context    = $ctx;
                FileSystem = $AclEntry.Container;
                Path       = $AclEntry.folder;
                Acl        = $aclList;
                verbose    = $VerbosePreference;
            }
            if (($PSBoundParameters.ContainsKey('WhatIf')) -eq $True) {
                Write-Host "Running WhatIf"
                $UpdateParams.Add('WhatIf', $True)
            }
            Update-AzDataLakeGen2Item @UpdateParams | Out-null
        
            if ($aclEntry.recurse -eq "True") {
                try {
                    Write-Verbose "[**] Updating $($AclEntry.folder) recursively..."
                    $RecurseParams = @{
                        Context    = $ctx;
                        FileSystem = $AclEntry.Container;
                        Path       = $AclEntry.folder;
                        Acl        = $aclList;
                        verbose    = $VerbosePreference;
                    }
                    if (($PSBoundParameters.ContainsKey('WhatIf')) -eq $True) {
                        Write-Host "Running WhatIf"
                        $RecurseParams.Add('WhatIf', $True)
                    }
                    Update-AzDataLakeGen2AclRecursive @RecurseParams
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Host "Most likely timed out... Am going to have to do this the slow way (which is not included here as pipeline will time out!)"
                    Write-Error $ErrorMessage
                }
            }
        }
        else { 
            Write-Host " - No Changes" 
        }
    }
    catch {
        Write-Host "Hello"
        Write-Error $_
        
        Throw
    }
    
}