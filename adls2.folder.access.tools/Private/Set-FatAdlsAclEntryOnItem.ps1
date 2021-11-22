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
        Write-Host "Setting the ACLs for $($aclEntry.container) $($aclEntry.folder)"

        $Gen2Item = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $AclEntry.container -Path $aclEntry.folder
        Write-Verbose "Owner = $($Gen2Item.Owner)"
        $aclList = [Collections.Generic.List[System.Object]]($Gen2Item.ACL)
        Write-Verbose "Current Acl"
        Write-Verbose ($aclList | Where-Object { @("User", "Group") -contains $_.AccessControlType -and $null -ne $_.EntityId } | `
                ForEach-Object { 
                $ADGroup = Get-FatCachedAdGroupName -ObjectId $_.EntityId
                $ADGroupDisplayName = $ADGroup.DisplayName
                [PSCustomObject]@{Default = $_.DefaultScope;
                    Type                  = $_.AccessControlType;
                    EntityId              = $_.EntityId; 
                    Group                 = $ADGroupDisplayName; 
                    Perms                 = $_.GetSymbolicRolePermissions()
                } 
            } | Format-Table | Out-String  )
        Write-Verbose "ACL Entry $($aclEntry.Items.Count)"

        if ($removeAcls) {
            Write-Host "Checking Acls to Remove..."
            for ($i = $aclList.Count; $i -gt 0; $i-- ) {
                $currentAcl = $aclList[$i]
                if (@("User", "Group") -contains $currentAcl.AccessControlType -and $null -ne $currentAcl.EntityId) {
                    $ADGroup = Get-FatCachedAdGroupName -ObjectId $currentAcl.EntityId
                    Write-Verbose "Checking `$ACLEntry for $($currentAcl.EntityId) $($ADGroup.DisplayName)"
                    $matchingACls = @($AclEntry.Items | Where-Object { $AdGroup.DisplayName -eq $_.ADGroup })
                    if ($matchingACls.Count -eq 0 ) {
                        Write-Verbose "AclList count = $($aclList.Count)"
                        Write-Host "Removing acl for Group $($ADGroup.DisplayName) from $($AclEntry.Folder)"
                        $aclList.RemoveAt($i) | out-null;
                        Write-Verbose "AclList count = $($aclList.Count)"
                    }
                }
            }
        }

        Write-Host "Checking Acls to Add..."

        foreach ( $acl in $aclEntry.Items) { 
            Write-Verbose ($acl | Format-Table | Out-String)
            if ($acl.ADGroupId) {
                $ADGroupId = $acl.ADGroupId
            }
            else {
                Write-Verbose "Getting the GroupId from AAD"
                $ADGroup = Get-FatCachedAdGroupId -DisplayName $acl.ADGroup
                if (@($AdGroup).Count -eq 1){
                    $ADGroupId = $ADGroup.Id
                }
                else{
                    Write-Host "$($AdGroup.Count) entries found for group ($($acl.ADGroup)). Pick the right groupId from the list below and specify it directly in the Acl entry"
                    (0..($AdGroup.Count-1))| ForEach-Object{Write-Host "  Duplicate $_ : $($AdGroup[$_].Id)" }
                    Throw "Cannot determine group. Found $($AdGroup.Count) duplicate entries. See previous output for resolution options."
                }
            }
            if ($null -ne $AdGroupId){
                if (-not [string]::IsNullOrWhitespace($acl.DefaultPermission)) {
                    $aclCountBefore = $aclList.Count
                    Write-Verbose "Adding Default Acl $($acl.DefaultPermission) for $AdGroupId ($($acl.AdGroup))"
                    $aclList = set-AzDataLakeGen2ItemAclObject -AccessControlType group -EntityID $AdGroupId  -Permission $acl.DefaultPermission -InputObject $aclList -DefaultScope 
                    Write-Verbose "Count of Acls before and After $aclCountBefore-$($AclList.Count) "
                }
                if ( -not [string]::IsNullOrWhitespace($acl.AccessPermission)) {
                    $aclCountBefore = $aclList.Count
                    Write-Verbose "Adding Access Acl $($acl.AccessPermission) for $AdGroupId ($($acl.AdGroup))"
                    $aclList = set-AzDataLakeGen2ItemAclObject -AccessControlType group -EntityID $AdGroupId  -Permission $acl.AccessPermission -InputObject $aclList
                    Write-Verbose "Count of Acls before and After $aclCountBefore-$($AclList.Count) "
                }
            }
        }
     
        $aclList = [Collections.Generic.List[System.Object]]($aclList)
        Write-Verbose "Checking for --- permissions. If any are found they will be removed."
        for ($i = $aclList.Count - 1; $i -gt 0; $i-- ) {
            $currentAcl = $aclList[$i]
            if (@("User", "Group") -contains $currentAcl.AccessControlType -and $null -ne $currentAcl.EntityId) {
                if ($currentAcl.GetSymbolicRolePermissions() -eq '---') {
                    Write-Verbose "Removing --- $((Get-FatCachedAdGroupName -ObjectId $currentAcl.EntityId).DisplayName) $($currentAcl.DefaultScope)"
                    $aclList.RemoveAt($i) | Out-Null;    
                }
            }
        }

        Write-Verbose ($aclList | Where-Object { @("User", "Group") -contains $_.AccessControlType -and $null -ne $_.EntityId } | ForEach-Object { 
                [PSCustomObject]@{Default = $_.DefaultScope;
                    Type = $_.AccessControlType;
                    EntityId = $_.EntityId; Group = (Get-FatCachedAdGroupName -ObjectId $_.EntityId).DisplayName; Perms = $_.GetSymbolicRolePermissions()
                } 
            } | Format-Table | Out-String  )
        $Comparison = Compare-Object  $Gen2Item.ACL $aclList -property "EntityId", "Permissions", "AccessControlType", "DefaultScope"
        if ($null -ne $Comparison) {
            Write-Host " - Changes to ACLs on $($AclEntry.folder) $($Comparison.Count)"
            Write-Host "<= to be removed, => to be set "
            Write-Host ($Comparison | ForEach-Object { [pscustomObject]@{Permissions = $_.Permissions;
                    Default                                              = $_.DefaultScope;
                    Type                                                 = $_.AccessControlType;
                    Group                                                = (Get-FatCachedAdGroupName -objectId $_.EntityId).DisplayName;
                    Change                                               = $_.SideIndicator
                } } | Format-Table Group, Type, Default, Permissions, Change | Out-String)

            $UpdateParams = @{
                Context    = $ctx;
                FileSystem = $AclEntry.Container;
                Path       = $AclEntry.folder;
                Acl        = $aclList;
                verbose    = $VerbosePreference;
            }
            if (($PSBoundParameters.ContainsKey('WhatIf')) -eq $True) {
                Write-Verbose "Running WhatIf"
                $UpdateParams.Add('WhatIf', $True)
            }
            Update-AzDataLakeGen2Item @UpdateParams | Out-null
        
            if ($aclEntry.recurse -eq "True") {
                try {
                    Write-Verbose "Updating $($AclEntry.folder) recursively..."
                    $RecurseParams = @{
                        Context    = $ctx;
                        FileSystem = $AclEntry.Container;
                        Path       = $AclEntry.folder;
                        Acl        = $aclList;
                        verbose    = $VerbosePreference;
                    }
                    if (($PSBoundParameters.ContainsKey('WhatIf')) -eq $True) {
                        Write-Verbose "Running WhatIf"
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
        Throw
    }
}