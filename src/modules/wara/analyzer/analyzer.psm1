<#
.SYNOPSIS
Well-Architected Reliability Assessment Script

.DESCRIPTION
The function `Start-WARAAnalyzer` will process the JSON file created by the `Start-WARACollector` function and will create the core WARA Action Plan Excel file.

.PARAMETER Help
Switch to display help information.

.PARAMETER RepoUrl
Specifies the git repository URL that contains APRL contents if you want to use custom APRL repository.

.PARAMETER JSONFile
Path to the JSON file created by the "1_wara_collector" script.

.EXAMPLE
Start-WARAAnalyzer -JSONFile 'C:\Temp\WARA_File_2024-04-01_10_01.json' -Debug

.LINK
https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2
#>
function Start-WARAAnalyzer {
    [CmdletBinding()]
    param (
        [ValidatePattern('^https:\/\/.+$')]
        [string] $RecommendationDataUri = 'https://azure.github.io/WARA-Build/objects/recommendations.json',
        [Parameter(mandatory = $true)]
        [string] $JSONFile,
        [string] $ExpertAnalysisFile
    )

    Write-Host 'Checking Version..' -ForegroundColor Cyan
    $LocalVersion = (Get-Module -Name $MyInvocation.MyCommand.ModuleName).Version
    $GalleryVersion = (Find-Module -Name $MyInvocation.MyCommand.ModuleName).Version

    if ($LocalVersion -lt $GalleryVersion) {
        Write-Host "A newer version of the module is available. Please update the module to the latest version and re-run the command." -ForegroundColor Cyan
        Write-Host "  1. Run 'Update-Module -Name $($MyInvocation.MyCommand.ModuleName)' to update the module to the latest version." -ForegroundColor Cyan
        Write-Host "  2. Start a new PowerShell session. (Open a new PowerShell window/tab)" -ForegroundColor Cyan
        Write-Host "  3. Re-run the command:" -ForegroundColor Cyan
        Write-Host "     $($MyInvocation.Statement)" -ForegroundColor Cyan
        Write-Host "Local Install Version            : $LocalVersion" -ForegroundColor Yellow
        Write-Host "PowerShell Gallery Latest Version: $GalleryVersion" -ForegroundColor Green
        throw 'Module is out of date.'
    }

    Write-Host 'Wrapping Analyzer' -ForegroundColor Cyan
    & "$PSScriptRoot/2_wara_data_analyzer.ps1" @PSBoundParameters
    Write-Host Analyzer Complete -ForegroundColor Cyan
}
