<#
.FUNCTION
    Build-SelectorResourceGraphQuery

.SYNOPSIS
    Constructs an Azure Resource Graph query from a selector.

.DESCRIPTION
    The `Build-SelectorResourceGraphQuery` function creates a Resource Graph query
    that filters resources based on the provided selector expression.

.PARAMETER Selector
    The filter expression used to scope resources in the query.

.OUTPUTS
    [string]
    The formatted Azure Resource Graph query.

.EXAMPLE
    $query = Build-SelectorResourceGraphQuery -Selector "type == 'Microsoft.Compute/virtualMachines'"

    Generates a query to filter virtual machines.

.NOTES
    - The selector should be a valid KQL (Kusto Query Language) expression.
    - The output query can be executed using Azure Resource Graph API.

    Author: Casey Watson
    Date: 2025-02-27
#>
function Build-SelectorResourceGraphQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Selector
    )

    return @"
resources
| where $Selector
| project id, type, location, name, resourceGroup, tags
"@
}
