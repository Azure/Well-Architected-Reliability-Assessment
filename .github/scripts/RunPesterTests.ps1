[CmdletBinding()]
param (
    [String]$moduleName
)
# Determine the base path based on the environment
if ($env:GITHUB_WORKSPACE) {
    # Running in GitHub Actions
    $basePath = "./src"
} else {
    # Running locally
    $basePath = "$PSScriptRoot/../../src"
}



if($moduleName)
{
    $moduleDirectories = Get-ChildItem -Path "$basePath/modules/wara/" -Directory | Where-Object { $_.Name -eq $moduleName }
}
else{
    # Grab directories
    $moduleDirectories = Get-ChildItem -Path "$basePath/modules/wara/" -Directory | Where-Object {$_.Name -notin @("analyzer","reports")}
}

$coveragePercent = @()
$resultOfRun = @()
$passedCount = @()
$failedCount = @()

foreach ($moduleDir in $moduleDirectories) {
    $manifestPath = "$($moduleDir.FullName)/$($moduleDir.Name).psd1"
    $modulePath = "$($moduleDir.FullName)/$($moduleDir.Name).psm1"
    $testsPath = "$basePath/tests/$($moduleDir.Name)"

    if (Test-Path $modulePath) {
        Import-Module -Name $manifestPath -Force
        $config = New-PesterConfiguration
        $config.Run.Path = $testsPath
        $config.CodeCoverage.Path = $modulePath
        $config.CodeCoverage.Enabled = $true
        $config.Run.PassThru = $true

        Write-host "-------------Running tests for module $($moduleDir.Name)-------------" -ForegroundColor Cyan
        # Run Pester with the configuration
       $result = Invoke-Pester -Configuration $config

<#         $resultOfRun = $($result.Result -eq 'Passed') ? "✅ Passed" : "❌Failed"
        $passedCount = $($result.PassedCount -eq $result.TotalCount) ? "✅ $($result.PassedCount)" : "❌ $($result.PassedCount)"
        $failedCount = $($result.FailedCount -gt 0) ? "❌ $($result.FailedCount)" : "✅ $($result.FailedCount)" #>
        $coveragePercent += $($result.CodeCoverage.CoveragePercent -ge $result.CodeCoverage.CoveragePercentTarget) ? "Passed" : "Failed"
        $resultofRun += $($result.Result -eq 'Passed') ? "Passed" : "Failed"
        $passedCount += $($result.PassedCount -eq $result.TotalCount -and $result.PassedCount -gt 0) ? "Passed" : "Failed"
        $failedCount += $($result.FailedCount -gt 0) ? "Failed" : "Passed"
        Write-host "`n-------------Finished tests for module $($moduleDir.Name)-------------`n`n" -ForegroundColor Cyan
        remove-module -name $($moduleDir.Name) -force
    }
}

If($($coveragePercent + $resultOfRun + $passedCount + $failedCount).contains("Failed"))
{
    Write-host "Failed"

    if($env:GITHUB_WORKSPACE){
        bash -c 'echo "ERROR_DETECTED=true" >> $GITHUB_ENV'
        Exit 1
    }

}
else
{
    Write-host "Passed"
}
