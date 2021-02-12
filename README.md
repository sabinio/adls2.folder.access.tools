## IN BETA

# Introduction 

Set users permissions to folders on a Data Lake; permisions are set in a csv.

## SetUp
1. Create a csv with following headers


```
Folder, ADGroup, ADGroupID, Permission, IncludeInDefault, Recurse

```
 - Folder - access path of the folder
 - ADGroup - ADGroup to add permissions to
 - Permissions - one of "None", "Execute", "Write", "WriteExecute", "Read", "ReadExecute", "ReadWrite", "All"
 - GroupID - optional. Group ID of Azure Active Directory group. By providing this you do not need to assign AAD permissions to the service principal, but does limit you to execute the csv against one Azure Active Directory Tenant as the Group ID will be different for identically named AAD Groups in different Azure Acitve Directory Tenants.
 - IncludeInDefault - boolean. If included then the permission is added as a default to the folder. What this means in plain speak is that any objects created underneath the folder will automatically inherit the same level of permissions.
 - Recurse - boolean. Determines if the permissions should be applied recursively to all child items of folder. This takes longer to run.

 Add the permissions as required.


Example below - 
```
Folder, ADGroup, ADGroupID, Permission, IncludeInDefault, Recurse
/,adlsRoot,80024941-9710-47d2-8be9-f06f4389620f,---,False,True
/output2,adlsOutput,16050cad-cf12-4c2d-9ba8-57a7553184a5,rwx,False,False
/output2/whatis,adlsProcess,b8243406-018c-4129-9fcb-f965e916d835,rwx,False,False
/process2,adlsProcess,b8243406-018c-4129-9fcb-f965e916d835,rwx,False,False
/raw2,adlsRaw,5b6fd483-9acc-4978-9b0f-352eebf234a7,rwx,True,False
/raw2/howabout,adlsOutput,16050cad-cf12-4c2d-9ba8-57a7553184a5,rwx,False,False
```

 ## Execute

```powershell
Run setadls.ps -SubscriptionName <subscription-name> -dataLakeStoreName <name-of-data-lake> -csv <path-to-csv-file>
```
where ```<subscription-name>``` set to name of subscription that data lake is in, ```<name-of-data-lake>``` the name of the data lake (ie 'devadls4u' NOT 'devadls4u.azuredatalakestore.net') and the path to the csv file that you want the permission entries to be added against.

If folders do not exist then they are created. All folders must be created by the executing user/sp and not via any other process - see [Data lake Permisions Required to Execute](#Data-lake-Permisions-Required-to-Execute)

## How Can I Check Changes to ACl First?

The 

## Data lake Permisions Required to Execute
This can be executed by a user or service principal (sp) via Azure DevOps Pipeline.

When executing script user/sp needs to be either a super user of the Data Lake or the owner of the parent folder that subsequent folders are created in. For this reason, folders must be created by the same user/sp.

## Azure Active Directory Permissions
If not supplying GroupId user/sp needs one of the following:
 - to be a member of the GlobalRead role in Azure Active Directory (preference is this option)
 - have "Directory.ReadAll" permission granted from the Graph API.


## How To Run In An AzDo Pipeline

Use an Azure PowerShell Task. Ensure you are usinghte latest version of the Az PowerShell cmdlets.

```powershell

Set-Location $(System.DefaultWorkingDirectory);
$ErrorActionPreference="Stop"
$sandboxSet = Get-Item .\stages\devadls4u.csv
$dataLakeName = "devadls4u"
$subscriptionName = "dev4usub"
$rgName = "dev4u"

Install-Module adls2.folder.access.tools -Force -AllowPrerelease

$csv =  Get-FatCsvAsArray -csvPath $sandboxSet
Set-FatAdlsAccess -subscriptionName $subscriptionName -RgName $rgName -dataLakeStoreName $dataLakeName -aclFolders $csv -entryType "acl" -Verbose
```

## How To Run Locally/Interractive

```powershell
Write-Host "Loading modules"
import-module Az.Accounts -minimumVersion 1.9.1 -Force -ErrorAction Continue
import-module Az.Resources -Force
Import-Module .\adls2.folder.access.tools -Force

$ErrorActionPreference="Stop"
$sandboxSet = Get-Item .\stages\devadls4u.csv
$dataLakeName = "devadls4u"
$subscriptionName = "dev4usub"
$rgName = "dev4u"

Connect-AzAccount -UseDeviceAuthentication

Write-Host "Ensuring connected to correct subscription"
if ((Get-AzContext).Subscription.Name -ne $subscriptionName) {
    Set-AzContext -SubscriptionName $subscriptionName
}

Get-AzConnection  -SubscriptionName $subscriptionName

Write-Host "Loading csv"
$csv = Get-FatCsvAsArray -csvPath $sandboxSet

$csv | Format-Table
Write-Host "Processing Acls $($csv.Count)"

try {
    Set-FatAdlsAccess -subscriptionName $subscriptionName -RgName $rgName -dataLakeStoreName $dataLakeName -aclFolders $csv -entryType "acl" -Verbose -RemoveAcls:$removeAcls -WhatIf:$WhatIf
}
catch {
    throw $_.Exception
}

```