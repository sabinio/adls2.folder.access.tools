## IN BETA

# Introduction 

Set users permissions to folders on a Data Lake; permisions are set in a csv.

## SetUp
1. Create a csv with following headers (see sample.csv)

```
Folder,ADGroup,Permission,GroupID,IncludeInDefault, Recursive
```
 - Folder - access path of the folder
 - ADGroup - ADGroup to add permissions to
 - Permissions - one of "None", "Execute", "Write", "WriteExecute", "Read", "ReadExecute", "ReadWrite", "All"
 - GroupID - optional. Group ID of Azure Active Directory group. By providing this you do not need to assign AAD permissions to the service principal, but does limit you to execute the csv against one Azure Active Directory Tenant as the Group ID will be different for identically named AAD Groups in different Azure Acitve Directory Tenants.
 - IncludeInDefault - boolean. If included then the permission is added as a default to the folder. What this means in plain speak is that any objects created underneath the folder will automatically inherit the same level of permissions.
 - Recurse - boolean. Determines if the permissions should be applied recursively to all child items of folder. This takes longer to run.

 Add the permissions as required.

 ## Execute

```powershell
Run setadls.ps -SubscriptionName <subscription-name> -dataLakeStoreName <name-of-data-lake> -csv <path-to-csv-file>
```
where ```<subscription-name>``` set to name of subscription that data lake is in, ```<name-of-data-lake>``` the name of the data lake (ie 'devadls4u' NOT 'devadls4u.azuredatalakestore.net') and the path to the csv file that you want the permission entries to be added against.

If folders do not exist then they are created. All folders must be created by the executing user/sp and not via any other process - see [Data lake Permisions Required to Execute](#Data-lake-Permisions-Required-to-Execute)

## Data lake Permisions Required to Execute
This can be executed by a user or service principal (sp) via Azure DevOps Pipeline.

When executing script user/sp needs to be either a super user of the Data Lake or the owner of the parent folder that subsequent folders are created in. For this reason, folders must be created by the same user/sp.

## Azure Active Directory Permissions
If not supplying GroupId user/sp needs one of the following:
 - to be a member of the GlobalRead role in Azure Active Directory (preference is this option)
 - have "Directory.ReadAll" permission granted from the Graph API.
