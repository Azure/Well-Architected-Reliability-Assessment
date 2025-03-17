<#
.SYNOPSIS
    Filters a list of objects based on resource identifiers.
.DESCRIPTION
    The Get-WAFResourcesByList function takes a list of objects and filters them based on the specified resource identifiers.
    It compares the KeyColumn property of each object with the provided filter list.
.PARAMETER ObjectList
    An array of objects to be filtered.
.PARAMETER FilterList
    An array of resource identifiers to filter the objects.
.PARAMETER KeyColumn
    The name of the property in the objects that contains the resource identifier.
.PARAMETER NotIn
    Switch that, if present, reverses the filtering.
.OUTPUTS
    Returns an array of filtered resources.
.EXAMPLE
    $objectList = @( @{ Id = "/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM" },
                      @{ Id = "/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/anotherVM" } )
    $filterList = @("/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM")
    $filteredObjects = Get-WAFResourcesByList -ObjectList $objectList -FilterList $filterList -KeyColumn "Id"
.NOTES
    Author: Your Name
    Date: 2024-08-07
#>
function Get-WAFResourcesByList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array] $ObjectList,
        [Parameter(Mandatory = $true)]
        [array] $FilterList,
        [Parameter(Mandatory = $true)]
        [string] $KeyColumn,
        [parameter(Mandatory = $false)]
        [switch] $NotIn
    )
    $matchingObjects = @()
    if($NotIn.IsPresent){
        Write-Debug 'Filtering for objects not in the list'
        $matchingObjects += foreach ($obj in $ObjectList) {
            if ($obj.$KeyColumn -notin $FilterList) {
                $obj
            }
        }
    } else {
        Write-Debug 'Filtering for objects in the list'
        $matchingObjects += foreach ($obj in $ObjectList) {
            if ($obj.$KeyColumn -in $FilterList) {
                $obj
            }
        }
    }
    return ,$matchingObjects
}
