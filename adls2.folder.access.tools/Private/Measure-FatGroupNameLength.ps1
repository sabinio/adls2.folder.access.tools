Function Measure-FatGroupNameLength {
    param (
        [parameter(Mandatory = $true)][psobject]$GroupNameList
    )
    $TooLongGroupNames = @()
    foreach ($GroupName in $GroupNameList) {
        $GroupNameLength = $GroupName.Length
        if ($GroupNameLength -gt 120) {
            $TooLongGroupNames += $GroupName
        }
        if ($GroupNameLength -eq 0) {
            Write-Error "No entry for name."
            Throw
        }
    }
    if ($TooLongGroupNames.length -ge 1) {
        Write-Error "The names of the following groups excede the character length (120) in Azure Active Directory: ` "
        foreach ($TooLongGroupName in $TooLongGroupNames) {
            Write-Error "$TooLongGroupName ` "
        }
        Write-Error "Shorten the name(s) and try again."
        Throw
    }
}