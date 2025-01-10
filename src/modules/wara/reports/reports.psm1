function Start-WARAReport {
    [CmdletBinding()]
    Param(
    [switch] $Help,
    #[switch] $GenerateCSV,
    #[switch] $includeLow,
    #[switch] $byPassValidationStatus,
    [switch] $Debugging,
    [string] $CustomerName,
    [string] $WorkloadName,
    [Parameter(mandatory = $true)]
    [string] $ExcelFile,
    [switch] $Heavy,
    [string] $PPTTemplateFile,
    [string] $WordTemplateFile
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

    Write-host Wrapping Report Generator -ForegroundColor Cyan
    & "$PSScriptRoot/3_wara_reports_generator.ps1" @PSBoundParameters
    Write-Host Report Generator Complete -ForegroundColor Cyan
    }
