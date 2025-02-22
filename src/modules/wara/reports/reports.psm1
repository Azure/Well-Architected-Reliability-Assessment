<#
.SYNOPSIS
Well-Architected Reliability Assessment Report Generator Function

.DESCRIPTION
The function `Start-WARAReport` processes the Excel file created by the `Start-WARAAnalyzer` command and generates the final PowerPoint and Word reports for the Well-Architected Reliability Assessment.

.PARAMETER Help
Switch to display help information.

.PARAMETER CustomerName
Name of the customer for whom the report is being generated.

.PARAMETER WorkloadName
Name of the workload being assessed.

.PARAMETER includeLow
Option to also consider Low Impact recommendations.

.PARAMETER ExpertAnalysisFile
Path to the Excel file created by the "2_wara_data_analyzer" script.

.PARAMETER PPTTemplateFile
Path to the PowerPoint template file.

.EXAMPLE
Start-WARAReport -ExpertAnalysisFile 'C:\WARA_Script\WARA Action Plan 2024-03-07_16_06.xlsx' -CustomerName 'ABC Customer' -WorkloadName 'SAP On Azure' -Heavy -PPTTemplateFile 'C:\Templates\Template.pptx'

.LINK
https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2
#>
function Start-WARAReport {
    [CmdletBinding()]
    param (
        [switch] $Help,
        #[switch] $csvExport,
        [switch] $includeLow,
        [string] $CustomerName,
        [string] $WorkloadName,
        [Parameter(mandatory = $true)]
        [Alias('ExcelFile')]
        [string] $ExpertAnalysisFile,
        [string] $AssessmentFindingsFile,
        [string] $PPTTemplateFile
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

    Write-Host 'Wrapping Report Generator' -ForegroundColor Cyan
    & "$PSScriptRoot/3_wara_reports_generator.ps1" @PSBoundParameters
    Write-Host Report Generator Complete -ForegroundColor Cyan
}
