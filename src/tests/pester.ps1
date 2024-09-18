$config = New-PesterConfiguration
$config.Run.Path = './'
$config.CodeCoverage.Path = "$PSScriptRoot/../modules/wara/scope/scope.psm1"
$config.CodeCoverage.Enabled = $true
#$config.CodeCoverage.OutputFormat = 'JaCoCo'
#$config.CodeCoverage.OutputPath = './coverage.xml'
$config.Run.PassThru = $true

# Run Pester with the configuration
$result = Invoke-Pester -Configuration $config

$resultOfRun = $($result.Result -eq 'Passed') ? "✅ Passed" : "❌Failed"
$passedCount = $($result.PassedCount -eq $result.TotalCount) ? "✅ $($result.PassedCount)" : "❌ $($result.PassedCount)"
$failedCount = $($result.FailedCount -gt 0) ? "❌ $($result.FailedCount)" : "✅ $($result.FailedCount)"
$coveragePercent = $($result.CodeCoverage.CoveragePercent -ge $result.CodeCoverage.CoveragePercentTarget) ? "✅ $($result.CodeCoverage.CoveragePercent)" : "❌ $($result.CodeCoverage.CoveragePercent)"


$markdown = @"
# Code Coverage Report - Scope.psm1
| Metric          | Value       |
|-----------------|-------------|
| Result          | $resultofRun |
| Passed Count         | $passedCount |
| Failed Count         | $failedCount |
| Coverage (%)    | $coveragePercent |
| Target Coverage (%) | $($result.CodeCoverage.CoveragePercentTarget) |
"@

$markdown | Out-File -FilePath './coverage.md'