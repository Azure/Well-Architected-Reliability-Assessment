function Start-WARAAnalyzer {
    [CmdletBinding()]
    param
    (
        [switch]$Debugging,
        [switch]$Help,
        [string]$CustomRecommendationsYAMLPath,

        [ValidatePattern('^https:\/\/.+$')]
        [string]$RepoUrl = 'https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2',

        [Parameter(mandatory = $true)]
        [string] $JSONFile
    )

    Write-host Wrapping Analyzer
    & "$PSScriptRoot/2_wara_data_analyzer.ps1" @PSBoundParameters
    Write-Host Analyzer Complete
    }

