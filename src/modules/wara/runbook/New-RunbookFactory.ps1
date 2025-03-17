<#
.FUNCTION
    New-RunbookFactory

.SYNOPSIS
    Instantiates a new RunbookFactory object.

.DESCRIPTION
    The `New-RunbookFactory` function creates an instance of the `RunbookFactory` class,
    which is responsible for parsing runbook files and generating `Runbook` instances.

.OUTPUTS
    [RunbookFactory]
    A new instance of the RunbookFactory class.

.EXAMPLE
    $factory = New-RunbookFactory

    Creates a new instance of the RunbookFactory class, which can then be used
    to parse runbook content.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function New-RunbookFactory {
    return [RunbookFactory]::new()
}
