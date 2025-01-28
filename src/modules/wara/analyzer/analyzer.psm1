<#
.SYNOPSIS
Well-Architected Reliability Assessment Script

.DESCRIPTION
The function `Start-WARAAnalyzer` will process the JSON file created by the `Start-WARACollector` function and will create the core WARA Action Plan Excel file.

.PARAMETER Debugging
Switch to enable debugging mode.

.PARAMETER Help
Switch to display help information.

.PARAMETER RepoUrl
Specifies the git repository URL that contains APRL contents if you want to use custom APRL repository.

.PARAMETER JSONFile
Path to the JSON file created by the "1_wara_collector" script.

.EXAMPLE
Start-WARAAnalyzer -JSONFile 'C:\Temp\WARA_File_2024-04-01_10_01.json' -Debugging

.LINK
https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2
#>
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


    Write-host "Checking Version.." -ForegroundColor Cyan
    $LocalVersion = $(Get-Module -Name $MyInvocation.MyCommand.ModuleName).Version
    $GalleryVersion = (Find-Module -Name $MyInvocation.MyCommand.ModuleName).Version

    if($LocalVersion -lt $GalleryVersion){
        Write-Host "A newer version of the module is available. Please update the module to the latest version and re-run the command." -ForegroundColor Cyan -
        Write-host "You can update by running 'Update-Module -Name $($MyInvocation.MyCommand.ModuleName)'" -ForegroundColor Cyan
        Write-Host "Local Install Version: $LocalVersion" -ForegroundColor Yellow
        Write-Host "PowerShell Gallery Version: $GalleryVersion" -ForegroundColor Green
        throw 'Module is out of date.'
    }

    Write-host Wrapping Analyzer -ForegroundColor Cyan
    & "$PSScriptRoot/2_wara_data_analyzer.ps1" @PSBoundParameters
    Write-Host Analyzer Complete -ForegroundColor Cyan
    }

