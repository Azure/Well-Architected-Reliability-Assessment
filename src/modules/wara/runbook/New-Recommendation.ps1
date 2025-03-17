<#
.FUNCTION
    New-Recommendation

.SYNOPSIS
    Creates a new `Recommendation` instance.

.DESCRIPTION
    The `New-Recommendation` function initializes and returns a new instance of the `Recommendation` class.
    This object contains metadata and evaluation logic for a specific runbook check.

.OUTPUTS
    [Recommendation]
    A new `Recommendation` object.

.EXAMPLE
    $recommendation = New-Recommendation

    Creates a new `Recommendation` instance.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function New-Recommendation {
    return [Recommendation]::new()
}
