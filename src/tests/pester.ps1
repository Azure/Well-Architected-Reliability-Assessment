# Get all module directories under modules/wara
$moduleDirectories = Get-ChildItem -Path "$PSScriptRoot/../modules/wara" -Directory

foreach ($moduleDir in $moduleDirectories) {
    $modulePath = "$($moduleDir.FullName)/$($moduleDir.Name).psm1"
    
    if (Test-Path $modulePath) {
        $config = New-PesterConfiguration
        $config.Run.Path = "./$($moduleDir.Name)"
        $config.CodeCoverage.Path = $modulePath
        $config.CodeCoverage.Enabled = $true
        #$config.CodeCoverage.OutputFormat = 'JaCoCo'
        #$config.CodeCoverage.OutputPath = "./coverage_$($moduleDir.Name).xml"
        $config.Run.PassThru = $true

        # Run Pester with the configuration
        $result = Invoke-Pester -Configuration $config

        $resultOfRun = $($result.Result -eq 'Passed') ? "✅ Passed" : "❌Failed"
        $passedCount = $($result.PassedCount -eq $result.TotalCount) ? "✅ $($result.PassedCount)" : "❌ $($result.PassedCount)"
        $failedCount = $($result.FailedCount -gt 0) ? "❌ $($result.FailedCount)" : "✅ $($result.FailedCount)"
        $coveragePercent = $($result.CodeCoverage.CoveragePercent -ge $result.CodeCoverage.CoveragePercentTarget) ? "✅ $([Math]::Round($result.CodeCoverage.CoveragePercent, 2))" : "❌ $([Math]::Round($result.CodeCoverage.CoveragePercent, 2))"

        $markdown = @"
# Code Coverage Report - $($moduleDir.Name).psm1
| Metric          | Value       |
|-----------------|-------------|
| Result          | $resultOfRun |
| Passed Count    | $passedCount |
| Failed Count    | $failedCount |
| Coverage (%)    | $coveragePercent |
| Target Coverage (%) | $($result.CodeCoverage.CoveragePercentTarget) |
"@

        $markdown | Out-File -FilePath "./$($moduledir.Name)/coverage_$($moduleDir.Name).md"
    } else {
        Write-Warning "Module file not found: $modulePath"
    }
}