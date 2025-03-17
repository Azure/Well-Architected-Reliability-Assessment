<#
.FUNCTION
    Write-RunbookFile

.SYNOPSIS
    Saves a `Runbook` object to a JSON file.

.DESCRIPTION
    The `Write-RunbookFile` function validates the provided `Runbook` object
    and serializes it into a JSON file at the specified path.

.PARAMETER Runbook
    The `Runbook` object to be saved.

.PARAMETER Path
    The file path where the `Runbook` JSON should be written.

.OUTPUTS
    None

.EXAMPLE
    Write-RunbookFile -Runbook $myRunbook -Path "C:\runbook.json"

    Saves the provided `Runbook` object to "C:\runbook.json".

.NOTES
    - Ensures the `Runbook` is valid before saving.
    - The output file is formatted in JSON.

    Author: Casey Watson
    Date: 2025-02-27
#>
function Write-RunbookFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Runbook] $Runbook,

        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $Runbook.Validate()

    $runbookFileContents = @{
        query_paths = $Runbook.QueryPaths
        parameters  = $Runbook.Parameters
        variables   = $Runbook.Variables
        selectors   = $Runbook.Selectors
        checks      = @{}
    }

    foreach ($checkSetKey in $Runbook.CheckSets.Keys) {
        $checkSet = $Runbook.CheckSets[$checkSetKey]
        $checkSetContents = @{}

        foreach ($checkKey in $checkSet.Checks.Keys) {
            $check = $checkSet.Checks[$checkKey]

            $checkContents = @{
                parameters = ($check.Parameters ?? @{})
                selector   = $check.SelectorName
                tags       = ($check.Tags ?? @())
            }

            $checkSetContents[$checkKey] = $checkContents
        }

        $runbookFileContents.checks[$checkSetKey] = $checkSetContents
    }

    $runbookFileJson = $runbookFileContents | ConvertTo-Json -Depth 15
    $runbookFileJson | Out-File -FilePath $Path -Force
}
