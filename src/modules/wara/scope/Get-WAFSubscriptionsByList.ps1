<#
.SYNOPSIS
    Filters a list of objects based on subscription identifiers.
.DESCRIPTION
    The Get-WAFSubscriptionsByList function takes a list of objects and filters them based on the specified subscription identifiers.
    It compares the first three segments of the KeyColumn property of each object with the provided filter list.
.PARAMETER ObjectList
    An array of objects to be filtered.
.PARAMETER FilterList
    An array of subscription identifiers to filter the objects.
.PARAMETER KeyColumn
    The name of the property in the objects that contains the subscription identifier.
.OUTPUTS
    Returns an array of filtered resources.
.EXAMPLE
    $objectList = @( @{ Id = "/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM" },
                      @{ Id = "/subscriptions/67890/resourceGroups/anotherResourceGroup/providers/Microsoft.Compute/virtualMachines/anotherVM" } )
    $filterList = @("/subscriptions/12345")
    $filteredObjects = Get-WAFSubscriptionsByList -ObjectList $objectList -FilterList $filterList -KeyColumn "Id"
.NOTES
    Author: Kyle Poineal
    Date: 2024-08-07
#>
function Get-WAFSubscriptionsByList {
    param (
        [Parameter(Mandatory = $true)]
        [array] $ObjectList,
        [Parameter(Mandatory = $true)]
        [array] $FilterList,
        [Parameter(Mandatory = $true)]
        [string] $KeyColumn
    )
    $matchingObjects = @()
    $matchingObjects += foreach ($obj in $ObjectList) {
        if (($obj.$KeyColumn.split('/')[0..2] -join '/') -in $FilterList) {
            $obj
        }
    }
    return ,$matchingObjects
}
