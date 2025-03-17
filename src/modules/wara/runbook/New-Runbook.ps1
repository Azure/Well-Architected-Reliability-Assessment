<#
.FUNCTION
    New-Runbook

.SYNOPSIS
    Creates a new Runbook instance.

.DESCRIPTION
    The `New-Runbook` function returns a new instance of the `Runbook` class.
    It can optionally be initialized from a JSON string (-FromJson) or a JSON file (-FromJsonFile),
    but not both.

.PARAMETER FromJson
    JSON content to initialize the runbook. Cannot be used with -FromJsonFile.

.PARAMETER FromJsonFile
    Path to a JSON file to initialize the runbook. Cannot be used with -FromJson.

.OUTPUTS
    [Runbook]
    A new `Runbook` instance.

.EXAMPLE
    $runbook = New-Runbook

    Creates an empty `Runbook` instance.

.EXAMPLE
    $runbook = New-Runbook -FromJson $jsonContent

    Initializes a `Runbook` instance from JSON content.

.EXAMPLE
    $runbook = New-Runbook -FromJsonFile "C:\runbook.json"

    Initializes a `Runbook` instance from a JSON file.

.NOTES
    - If neither `-FromJson` nor `-FromJsonFile` is specified, an empty `Runbook` instance is returned.
    - If both `-FromJson` and `-FromJsonFile` are specified, the function throws an error.
    - The provided JSON must be valid and match the expected `Runbook` schema.

    Author: Casey Watson
    Date: 2025-02-27
#>
function New-Runbook {
    param(
        [Parameter(Mandatory = $false)]
        [string] $FromJson,

        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-FileExists -Path $_ })]
        [string] $FromJsonFile
    )

    if ($FromJson -or $FromJsonFile) {
        if ($FromJson -and $FromJsonFile) {
            throw "Cannot specify both -FromJson and -FromJsonFile."
        }
        else {
            $runbookFactory = New-RunbookFactory

            if ($FromJson) {
                return $runbookFactory.ParseRunbookContent($FromJson)
            }
            elseif ($(Test-RunbookFile -Path $FromJsonFile)) {
                return $runbookFactory.ParseRunbookFile($FromJsonFile)
            }
        }
    }
    else {
        return [Runbook]::new()
    }
}
