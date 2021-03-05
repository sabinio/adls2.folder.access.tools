Function Set-FatAdlsAccess {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] [string]$subscriptionName,
        [parameter(Mandatory = $true)] [Alias("RGName")] [string]$resourceGroupName,
        [parameter(Mandatory = $true)] [string]$dataLakeStoreName,
        [parameter(Mandatory = $true)] $aclFolders,
        [parameter(Mandatory = $true)][ValidateSet('Acl', 'Permission')][string]$entryType,
        [switch]$UseConnectedAccount,
        [switch]$WhatIf
    )
    if (($PSBoundParameters.ContainsKey('UseConnectedAccount')) -eq $False) {
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $dataLakeStoreName
        $ctx = $storageAccount.Context
    }
    else{
        $ctx = New-AzStorageContext -StorageAccountName $dataLakeStoreName -UseConnectedAccount
    }

    if ($null -eq $ctx) {
        Write-Error "no context."
    }
    Write-Verbose "Azure DataLake Store Name: $dataLakeStoreName"
    $ErrorActionPreference = "Stop"

    foreach ($folder in $aclFolders) {
        Write-Verbose "[*] Checking if $($folder.Folder) exists in container $($folder.Container)..."

        if (-Not (Get-AzDataLakeGen2Item -context $ctx -FileSystem $folder.Container -Path $folder.Folder -ErrorAction "SilentlyContinue")) {
            Write-Verbose "[*] Creating folder $($folder.Folder) in $dataLakeStoreName..."
            $Params = @{
                context    = $ctx;
                FileSystem = $folder.Container
                Path       = $folder.Folder
                Directory  = $True

            }
            New-AzDataLakeGen2Item @Params | out-null
        }
        $FatAdlsAclEntryOnItem = @{
            ctx               = $ctx;
            subscriptionName  = $subscriptionName;
            dataLakeStoreName = $dataLakeStoreName;
            aclEntry          = $folder;
        }
        if (($PSBoundParameters.ContainsKey('WhatIf')) -eq $True) {
            Write-Host "Running WhatIf"
            $FatAdlsAclEntryOnItem.Add('WhatIf', $True)
        }
        if (($PSBoundParameters.ContainsKey('removeAcls')) -eq $True) {
            Write-Host "Removing ACL's"
            $FatAdlsAclEntryOnItem.Add('removeAcls', $True)
        }
        Set-FatAdlsAclEntryOnItem @FatAdlsAclEntryOnItem
    }
}
