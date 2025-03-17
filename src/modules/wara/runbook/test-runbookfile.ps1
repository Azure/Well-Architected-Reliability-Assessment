<#
.FUNCTION
    Test-RunbookFile

.SYNOPSIS
    Validates a runbook file.

.DESCRIPTION
    The `Test-RunbookFile` function checks whether a specified runbook JSON file is
    valid according to the runbook schema. It ensures the JSON structure is correct
    and adheres to expected schema requirements.

.PARAMETER Path
    The full file path to the runbook JSON file.

.OUTPUTS
    [bool]
    Returns `$true` if the file is valid; otherwise, an error is thrown.

.EXAMPLE
    $isValid = Test-RunbookFile -Path "C:\runbook.json"

    Returns `$true` if the runbook is valid.

.NOTES
    - Uses `Test-Json` to validate JSON structure.
    - If validation fails, an error is thrown.

    Author: Casey Watson
    Date: 2025-02-27
#>
function Test-RunbookFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-FileExists $_ })]
        [string] $Path
    )

    $fileContent = Get-Content -Path $Path -Raw

    if (-not ($fileContent | Test-Json -ErrorAction SilentlyContinue)) {
        throw "[$Path] is not a valid JSON file."
    }

    if (-not ($fileContent | Test-Json -ErrorAction SilentlyContinue -Schema $(Get-RunbookSchema))) {
        throw "[$Path] does not adhere to the runbook JSON schema. Run [Get-RunbookSchema] to get the schema."
    }

    $runbookFactory = New-RunbookFactory
    $runbookFactory.ParseRunbookContent($fileContent).Validate()

    return $true
}
