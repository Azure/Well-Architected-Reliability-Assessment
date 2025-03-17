<#
.FUNCTION
    Read-RunbookFile

.SYNOPSIS
    Reads and parses a runbook file.

.DESCRIPTION
    The `Read-RunbookFile` function validates and loads a runbook from a JSON file.
    If the file is valid, it returns a parsed `Runbook` instance.

.PARAMETER Path
    The file path to the runbook JSON file.

.OUTPUTS
    [Runbook]
    A parsed `Runbook` object.

.EXAMPLE
    $runbook = Read-RunbookFile -Path "C:\runbook.json"

    Reads and parses the specified runbook file.

.NOTES
    - Uses `Test-RunbookFile` to validate the file before parsing.
    - If validation fails, an error is thrown.
    - The runbook is parsed using `RunbookFactory`.

    Author: Casey Watson
    Date: 2025-02-27
#>
function Read-RunbookFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-FileExists $_ })]
        [string] $Path
    )

    if (Test-RunbookFile -Path $Path) {
        $runbookFactory = New-RunbookFactory
        return $runbookFactory.ParseRunbookFile($Path)
    }
}
