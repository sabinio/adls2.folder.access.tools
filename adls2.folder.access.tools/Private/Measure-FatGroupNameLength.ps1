Function Measure-FatGroupNameLength {
    param (
        [parameter(Mandatory = $true)][String[]]$GroupNameList
    )
    $TooLongGroupNames = @()
    foreach ($GroupName in $GroupNameList) {
        $GroupNameLength = $GroupName.Length
        if ($GroupNameLength -gt 64) {
            Write-Error "Length of group name $GroupName is greater than 64 chars, the limit of a group name in AAD. `
        Shorten the name and try again."
            $TooLongGroupNames += $GroupName
        }
    }
    if ($TooLongGroupNames.length -ge 1) {
        Write-Error "The names of the following groups excede the character length (64) in Azure Active Directory: ` "
        foreach ($TooLongGroupName in $TooLongGroupNames) {
            Write-Error "$TooLongGroupName ` "
        }
        Throw
    }
}