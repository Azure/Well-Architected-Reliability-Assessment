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
    $moduleDirectories = Get-ChildItem -Path "$basePath/modules/wara/" -Directory
}

$coveragePercent = @()
$resultOfRun = @()
$passedCount = @()
$failedCount = @()

foreach ($moduleDir in $moduleDirectories) {
    $modulePath = "$($moduleDir.FullName)/$($moduleDir.Name).psm1"
    $testsPath = "$basePath/tests/$($moduleDir.Name)"
    
    if (Test-Path $modulePath) {
        $config = New-PesterConfiguration
        $config.Run.Path = $testsPath
        $config.CodeCoverage.Path = $modulePath
        $config.CodeCoverage.Enabled = $true
        $config.Run.PassThru = $true

        # Run Pester with the configuration
       $result = Invoke-Pester -Configuration $config

<#         $resultOfRun = $($result.Result -eq 'Passed') ? "✅ Passed" : "❌Failed"
        $passedCount = $($result.PassedCount -eq $result.TotalCount) ? "✅ $($result.PassedCount)" : "❌ $($result.PassedCount)"
        $failedCount = $($result.FailedCount -gt 0) ? "❌ $($result.FailedCount)" : "✅ $($result.FailedCount)" #>
        $coveragePercent += $($result.CodeCoverage.CoveragePercent -ge $result.CodeCoverage.CoveragePercentTarget) ? "Passed" : "Failed"
        $resultofRun += $($result.Result -eq 'Passed') ? "Passed" : "Failed"
        $passedCount += $($result.PassedCount -eq $result.TotalCount -and $result.PassedCount -gt 0) ? "Passed" : "Failed"
        $failedCount += $($result.FailedCount -gt 0) ? "Failed" : "Passed"
    }
}

If($($coveragePercent + $resultOfRun + $passedCount + $failedCount).contains("Failed")){Write-host "Failed";Exit 1}else{Write-host "Passed";Exit 0}