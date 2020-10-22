#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach($import in @($Public + $Private))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Export Public functions
Export-ModuleMember -Function $Public.Basename
Export-ModuleMember -Alias * -Function *

$moduleName = "Az.Storage" 
$minVersion =  "2.5.2-preview"
# https://github.com/PowerShell/PowerShell/issues/7495
$checkInstalled = Get-InstalledModule -Name $moduleName -MinimumVersion $minVersion -ErrorAction SilentlyContinue -AllowPrerelease
if ($null -eq $checkInstalled) {
    Install-Module -Name $moduleName -RequiredVersion $minVersion -Force -Scope CurrentUser -AllowPrerelease
    
}