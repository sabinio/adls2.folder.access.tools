#Install-Module Pester -MinimumVersion 5.1.1 -MaximumVersion 5.1.1 -Scope CurrentUser -SkipPublisherCheck -Force
#Import-Module Pester -MinimumVersion 5.1.1 -MaximumVersion 5.1.1

Set-Location $PSScriptRoot
$Edition = $PSVersionTable.PSEdition
Invoke-Pester -CodeCoverage ../P*/*.ps1 -Script "./*.Tests.ps1" `
-OutputFile "TestResults-$Edition.xml" `
-OutputFormat NUnitXML `
-CodeCoverageOutputFile "coverage_$Edition.xml"
Set-Location $PSScriptRoot