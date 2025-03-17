<#
.SYNOPSIS
    Validates an array of tag patterns.

.DESCRIPTION
    The `Test-WAFTagPattern` function checks if each tag pattern in the input array follows the required format. Tags should be specified in the format 'Key!~Value||Key2!~Value2'.

.PARAMETER InputValue
    An array of tag patterns to validate.

.INPUTS
    System.String[]. The function accepts an array of tag pattern strings.

.OUTPUTS
    None. Throws an error if validation fails.

.EXAMPLE
    PS> Test-WAFTagPattern -InputValue @("Env!~Prod||Test", "Owner!~JohnDoe")

    This example validates valid tag patterns.

.EXAMPLE
    PS> Test-WAFTagPattern -InputValue @("InvalidTagPattern")

    Error:
    The tag pattern 'InvalidTagPattern' is invalid.

    This example demonstrates validation failure for an invalid tag pattern.

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
function Test-WAFTagPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $InputValue
    )

    $pattern = '^[^<>&%\\?/]+=~[^<>&%\\?/]+$|[^<>&%\\?/]+!~[^<>&%\\?/]+$'

    $allMatch = $true
    foreach ($value in $InputValue) {
        if ($value -notmatch $pattern) {
            $allMatch = $false
            throw "Tag pattern [$value] is not valid."
            break
        }
    }
    return $allMatch
}
