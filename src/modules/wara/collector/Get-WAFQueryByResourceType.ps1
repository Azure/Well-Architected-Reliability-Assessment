<#
.SYNOPSIS
    Filters objects by resource type.

.DESCRIPTION
    The Get-WAFQueryByResourceType function filters a list of objects by resource type.

.PARAMETER ObjectList
    An array of objects to filter.

.PARAMETER FilterList
    An array of resource types to filter by.

.PARAMETER KeyColumn
    The key column to use for filtering.

.OUTPUTS
    Returns an array of objects that match the specified resource types.

.EXAMPLE
    $filteredObjects = Get-WAFQueryByResourceType -ObjectList $objects -FilterList $types -KeyColumn "type"
#>
function Get-WAFQueryByResourceType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $ObjectList,

        [Parameter(Mandatory = $true)]
        [string[]] $FilterList,

        [Parameter(Mandatory = $true)]
        [string] $KeyColumn
    )

    $matchingObjects = foreach ($obj in $ObjectList) {
        if ($obj.$KeyColumn -in $FilterList) {
            $obj
        }
    }

    return $matchingObjects
}
