## IN BETA

# Introduction

The Access Control List (ACL) authorisation mechanism supported in Azure Data Lake Storage Gen 2 allows for "fine-grained" access to specific directories or files, yet if not carefully managed can quickly become impossible to maintain. By storing the ACL's in source control and applying them via an automation pipeline you can keep track of how has access to what. This PowerShell Module uses functions in the Az.DataLakeStore and Az.Storage modules to manage applying the ACLs to folders in the Data Lake.

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

The owning user of the item by default becomes the creator of the folder. This user can change the owning group, providing the user is a member of that group. The owning user may also change permissions on that item. it is recommended that any folder that need to be created are done so by this process, or any process that creates by the folder is done by the same owning user that will apply the ACLs. If possible create folders using this process rather than via your data pipelines.

## Recursively Assigning Permissions

An important reason for creating folders via this process is because default permissions apply to objects created **after** the ACL is set. Anything that currently exists does is not included. This means for objects that already exist that you do want the default permissions to be applied to you will need to apply recursively. This _can be_ a long-running process, depending on the number of objects/folders to traverse to apply the permission to. You set the recurse at the folder level in the csv. Ideally you should alter any ```True``` entries to ```False``` after the permission has been recursively apply in order to reduce the length of time it takes to apply permissions.

## Removing Permissions

Removing permissions from folders can be tricky, depending on whether your csv is the absolute list of all permissions required on the data lake.

* If the csv contains all permissions required then you can use the ```-removeacls``` switch.
* If the csv **does NOT** contain all the permissions then **DO NOT** use the ```removeacls``` switch.

You can include the ```whatif``` switch to determine what will be dropped.

If you wish to remove permissions without including the ```-removeacls``` switch then add an entry for the group and folder with both default and access permissions set to ```---```. This will remove the ACL entry form the folder.

**If in doubt do not use the ```-removeacls``` switch as it checks the acl list of the folder against the acl entry for that folder in the csv, and if anything is not included in the csv it will be dropped.** So it does not account for entries in the csv for the same group that may have default permissions set for the folder above. See [Advice on Organising Folders](#Advice-on-Organising-Folders) for recommended folder/group organisation.

## Advice on Organising Folders

* Keep the permissions assignment to a relatively shallow directory structure. 
* Create an AAD group per folder to manage and add/remove users/groups to the folder permissions group.
* In order for groups to be able to access sub-folders they will require access on the folders above. The simplest way to manage this is to create AAD groups that do not have default access on the upper folders but r-x access permissions only. Add the sub-folder AD groups to these groups so that they can traverse the folder directory and not inherit any extra permissions along the way, and reduce the entries required in the csv. Then add default and access permissions to the sub-folder.
* Permissions from the top of the directory to the bottom of the directory do not have to be persisted in the same AD Group. This is a good thing as it allows us to organise the folders and groups as outlined above. It is also a bad thing as users can inadvertently get access to folders they should not have through over-complex group organisation.  

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
