<#
.SYNOPSIS
    Validates whether a string is a valid GUID.

.DESCRIPTION
    The `Test-WAFIsGuid` function checks if the input string is a valid GUID format.

.PARAMETER StringGuid
    The string to validate as a GUID.

.INPUTS
    System.String. The function accepts a string representing the GUID to validate.

.OUTPUTS
    System.Boolean. Returns `$true` if the input is a valid GUID, `$false` otherwise.

.EXAMPLE
    Test-WAFIsGuid -StringGuid "59f6f1ab-6d68-4c90-b4e5-ad2d71cefc57"

    Output:
    True

    This example checks if the provided string is a valid GUID.

.EXAMPLE
    Test-WAFIsGuid -StringGuid "invalid-guid"

    Output:
    False

    This example demonstrates that an invalid GUID returns `$false`.

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
function Test-WAFIsGuid {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $StringGuid
    )

    $ObjectGuid = [System.Guid]::Empty
    if (-not [System.Guid]::TryParse($StringGuid, [ref]$ObjectGuid)) {
        throw "The provided string [$StringGuid] is not a valid GUID."
    }
    return $true
}
