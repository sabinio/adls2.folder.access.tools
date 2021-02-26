#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Export Public functions
Export-ModuleMember -Function $Public.Basename
Export-ModuleMember -Alias * -Function *

if (Get-PSRepository PowershellGalleryTest  -ErrorAction SilentlyContinue) { Unregister-PSRepository PowershellGalleryTest }

if ($PSVersionTable.PsEdition -eq "Core") {
    $mydocsPath = join-path ([System.Environment]::GetFolderPath("MyDocuments")) "PowerShell/Modules"
}
else {
    $mydocsPath = join-path ([System.Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell/Modules"
}

$LatestVersion = (Find-Module Pipeline.Tools -Repository "PSGallery").Version
Write-Host "Getting Pipeline.Tools module $LatestVersion"

If ("$($env:PSModulePath)".Split([IO.Path]::PathSeparator) -notcontains $mydocsPath) {
    Write-Host "Adding LocalModule folder to PSModulePath"
    $env:PSModulePath = "$mydocsPath$([IO.Path]::PathSeparator)$($env:PSModulePath)"
}

if (-not ((get-module Pipeline.Tools -ListAvailable).Version -eq $LatestVersion)) {
    Write-Host "Installing Pipeline.Tools module $LatestVersion"
    Get-Module Pipeline.Tools | Remove-Module
    Install-Module Pipeline.Tools -Scope CurrentUser -RequiredVersion $LatestVersion -Force -Repository PSGallery -Verbose:$VerbosePreference -SkipPublisherCheck -AllowClobber -ErrorAction "Stop"
}
if (-not ((get-module Pipeline.Tools -Verbose:$VerbosePreference).Version -eq $LatestVersion)) {
    Write-Host "Importing Pipeline.Tools module  $LatestVersion"
    Get-Module Pipeline.Tools | Remove-Module
    Import-Module Pipeline.Tools -RequiredVersion $LatestVersion -Verbose:$VerbosePreference -ErrorAction "Stop"
}

#Powershell Get needs to be first otherwise it gets loaded by use of import-module
$Modules = `
@{Module = "Az.Storage"; RequiredVersion = "3.2.0" }, `
@{Module = "Az.DataLakeStore"; Version = 1.2.8 }
$Modules  | ForEach-Object { Install-PsModuleFast @_ -Verbose:$VerbosePreference }

Write-Host "Modules loaded "
Write-Host (Get-Module $modules.module | Format-Table Name, Version, ModuleType, Path | Out-String)
