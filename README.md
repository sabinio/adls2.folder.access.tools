## IN BETA

# Introduction

The Access Control List (ACL) authorisation mechanism supported in Azure Data Lake Storage Gen 2 allows for "fine-grained" access to specific directories or files, yet if not carefully managed can quickly become impossible to maintain. By storing the ACL's in source control and applying them via an automation pipeline you can keep track of how has access to what. This PowerShell Module uses functions in the Az.DataLakeStore and Az.Storage modules to amange applying the ACLs to folders in the Data Lake.

## Currently Implemented

* Create directory if they do not exist
* Apply Default ACLs
* Apply Access ACLs
* ApplyDefault and Access ACLs Recursively
* Check That AAD Group Exists

## CSV Setup

1. Create a csv with following headers

```text
Container,Folder,ADGroup,ADGroupID,DefaultPermission,AccessPermission,Recurse
```

* Container - name of container the folder is located
* Folder - full access path of the folder
* ADGroup - ADGroup to add permissions to
* ADGroupID - optional. Group ID of Azure Active Directory group. By providing this you do not need to assign AAD permissions to the service principal, but does limit you to execute the csv against one Azure Active Directory Tenant as the Group ID will be different for identically named AAD Groups in different Azure Acitve Directory Tenants.
* DefaultPermission - The permissions that need to be set on the default ACL, if any.
* AccessPermission - The permissions that need to be set on the access ACL, if any.
* Recurse - boolean. Determines if the permissions should be applied recursively to all child items of folder. This takes longer to run, and in some cases much longer to run.

The CSV then needs to be turned into a ```pscustomobject``` and grouped in such a way that optimises the ACLs being set. To do this execute ```Get-CsvAsArray``` passing the path to the csv. You can optionally set to include recurse or not, as setting recurse permissions can take a long time.

## Run Against Lake

Run ```Set-FatAdlsAccess```, specifying Lake, Subscription and Resource Group, and the ```pscustomobject``` from the previous step.

## How Can I Check Changes to ACL First?

The ```Set-FatAdlsAccess``` cmdlet has a "whatif" option. This will run and print out the changes that will be applied.

## Azure Active Directory Permissions

If not supplying ADGroupID user/sp needs to be a member of the GlobalRead role in Azure Active Directory.

## Item Ownership

The owning user of the item by default becomes the creator of the folder. This user can change the owning group, providing the user is a member of that group. The owning user may also change permissions on that item. it is recommended that any folder that need to be created are done so by this process, or any process that creates by the folder is done by the same owning user that will apply the ACLs.

## How To Run In An AzDo Pipeline

By using a service connection in Azure DevOps, you can run pipelines and connect to Azure with the service principal that will be the owning user of the folders on the Data Lake.

To run in an Azure DevOps pipeline you need to connect to Azure. If you use the Azure PowerShell task you will need Az 5.3.0 installed on the build agent, which currently is not supported on the Azure hosted Build Agents. This is because the cmdlet to apply permissions recursively was only made available in Az.Storage 3.2.0, and the minimum version of the Az Module that contains this version is 5.3.0. And because Az.Storage 3.2.0 module requires a later version of Az.Account, and that is already in use in the Azure PowerShell tasks session, it is not possible to install and import the latest version of Az.Storage: the session would need to be terminated. And in the context of the Azure PowerShell tasks that deals with authentication to Azure, this would not be possible.

Assuming you have your own build agent set up and you're logged in as sudo and have PowerShell already installed, these are the steps to get 5.3.0 installed.

```powershell
sudo pwsh
Find-Module -Name Az -Repository 'PSGallery' | Save-Module -Path '/usr/share' -Force -Verbose
cd /usr/share
mkdir az_5.3.0
cp -RT Az/5.3.0 az_5.3.0
cd .. 
cp -R share/Az share/az_5.3.0
cp -R share/Az.* share/az_5.3.0
```

Alternately use a PowerShell task and install Az 5.3.0 and Connect to Azure using Az cmdlets.

## Example: Apply ACLs to Folders

To apply the permissions, assuming your csv is stored in a folder call "stages" at the root of your repo:

```powershell
        Install-Module adls2.folder.access.tools -Scope CurrentUser -AllowPrerelease -Force
        Import-Module adls2.folder.access.tools -Force
        $ErrorActionPreference="Stop"
        $dataLakeName = "marsanalyticsprodadls"
        $csvPath = Get-Item .\stages\$dataLakeName.csv
        $subscriptionName = "sub-of-datalake"
        $rgName = "rg-of-datalake"
        $csv =  Get-FatCsvAsArray -csvPath $csvPath
        Set-FatAdlsAccess -subscriptionName $subscriptionName -RgName $rgName -dataLakeStoreName $dataLakeName -aclFolders $csv -entryType "acl" -Verbose
```
