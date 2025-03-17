<#
.FUNCTION
    New-RunbookCheck

.SYNOPSIS
    Creates a new `RunbookCheck` instance.

.DESCRIPTION
    The `New-RunbookCheck` function returns a new instance of the `RunbookCheck` class,
    representing an individual check within a runbook. Each check is associated with a selector
    and contains parameterized logic for evaluating resource compliance.

.OUTPUTS
    [RunbookCheck]
    A new `RunbookCheck` instance.

.EXAMPLE
    $check = New-RunbookCheck

    Creates a new `RunbookCheck` instance.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function New-RunbookCheck {
    return [RunbookCheck]::new()
}
