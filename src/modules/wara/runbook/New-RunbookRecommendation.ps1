<#
.FUNCTION
    New-RunbookRecommendation

.SYNOPSIS
    Creates a new `RunbookRecommendation` instance.

.DESCRIPTION
    The `New-RunbookRecommendation` function initializes and returns a new instance of
    the `RunbookRecommendation` class, which encapsulates metadata for a specific runbook
    check, including its associated recommendation.

.OUTPUTS
    [RunbookRecommendation]
    A new `RunbookRecommendation` object.

.EXAMPLE
    $runbookRecommendation = New-RunbookRecommendation

    Creates a new `RunbookRecommendation` instance.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function New-RunbookRecommendation {
    return [RunbookRecommendation]::new()
}
