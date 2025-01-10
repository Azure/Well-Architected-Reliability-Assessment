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

    Write-host Wrapping Report Generator
    & "$PSScriptRoot/3_wara_reports_generator.ps1" @PSBoundParameters
    Write-Host Report Generator Complete
    }
