<#
.FUNCTION
    New-RunbookCheckSet

.SYNOPSIS
    Creates a new `RunbookCheckSet` instance.

.DESCRIPTION
    The `New-RunbookCheckSet` function returns a new instance of the `RunbookCheckSet` class,
    which represents a logical grouping of related runbook checks.

.OUTPUTS
    [RunbookCheckSet]
    A new `RunbookCheckSet` instance.

.EXAMPLE
    $checkSet = New-RunbookCheckSet

    Creates a new `RunbookCheckSet` instance.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function New-RunbookCheckSet {
    return [RunbookCheckSet]::new()
}
