Function Get-FatAdlsAccessIntoCsv {
    param(
        [parameter(Mandatory = $true)] [string]$dataLakeStoreName,
        [parameter(Mandatory = $true)] [string]$adlsPath,
        [parameter(Mandatory = $true)] [string]$csvOutputPath,
        [parameter(Mandatory = $true)] [string]$csvFileName,
        [parameter(Mandatory = $false)] [switch]$recurse
    )
    if ($dataLakeStoreName.EndsWith(".azuredatalakestore.net") -eq $false) {
        Write-Verbose "Adding FQDN to value of `$dataLakeStoreName"
        $dataLakeStoreName = $dataLakeStoreName + ".azuredatalakestore.net"
    }
    Write-Verbose "Azure DataLake Store Name: $dataLakeStoreName"
    $ErrorActionPreference = "Continue"

    if ($csvFileName.EndsWith("csv") -eq $false) {
        Write-Verbose "Adding .csv to value of `$csvFileName"
        $csvFileName = $csvFileName + ".csv"
    }
    if ($adlsPath.EndsWith("/") -eq $false) {
        Write-Verbose "Adding terminating / to value of `$adlsPath"
        $adlsPath = $adlsPath + "/"
    }
    if ($adlsPath.StartsWith("/") -eq $false) {
        Write-Verbose "Adding leading / to value of `$adlsPath"
        $adlsPath = "/" + $adlsPath
    }
    try {
        $csvOutputPath = Resolve-Path $csvOutputPath 
    }
    catch {
        Write-Host "Creating $csvOutputPath as it does not exist..."
        New-Item -path $csvOutputPath -ItemType Directory
        $csvOutputPath = Resolve-Path $csvOutputPath
    }
    $csvFullDirectoryPath = (Join-Path -Path $csvOutputPath -ChildPath $csvFileName)
    Write-Verbose "Full directory path set to $csvFullDirectoryPath." 
    $csvStreamWriter = New-Object IO.StreamWriter $csvFullDirectoryPath
    $csvStreamWriter.WriteLine("Folder, ADGroup, ADGroupID, Permission, IncludeInDefault, Recurse")
    if ($PSBoundParameters.ContainsKey('recurse') -eq $true) {
        Get-FatAdlsFolderPermissions -dataLakeStoreName $dataLakeStoreName -path $adlsPath -csvStreamWriter $csvStreamWriter -recurse
    }
    else {
        Get-FatAdlsFolderPermissions -dataLakeStoreName $dataLakeStoreName -path $adlsPath -csvStreamWriter $csvStreamWriter
    }
    if ($csvStreamWriter.BaseStream) {
        $csvStreamWriter.Dispose()
    }
}