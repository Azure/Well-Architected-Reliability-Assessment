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

