Function Test-FatCsvHeaders {
    param(
        [parameter(Mandatory = $true)] [string]$csvPath

    )
    $headers = (get-content $csvPath)[0] -split ',' -replace '\s+', ''
    if ($headers.Length -ne 7) {
        Throw
    }
    if ( (Compare-Object $headers "Container,Folder,ADGroup,ADGroupID,DefaultPermission,AccessPermission,Recurse".Split(",")) ) {
        Write-Host 'Headers are different!'
        Throw
    }
}