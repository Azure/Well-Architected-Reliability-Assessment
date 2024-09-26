<#
.SYNOPSIS
    Retrieves filtered lists of Azure resources based on provided subscription, resource group, and resource filters.

.DESCRIPTION
    This module contains functions to filter Azure resources by subscription, resource group, and resource IDs. 
    It includes the following functions:
    - Get-WAFResourceGroupsByList
    - Get-WAFSubscriptionsByList
    - Get-WAFResourcesByList
    - Get-WAFFilteredResourceList

.EXAMPLE
    $subscriptionFilters = @("/subscriptions/12345")
    $resourceGroupFilters = @("/subscriptions/12345/resourceGroups/myResourceGroup")
    $resourceFilters = @("/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM")

    $filteredResources = Get-WAFFilteredResourceList -SubscriptionFilters $subscriptionFilters -ResourceGroupFilters $resourceGroupFilters -ResourceFilters $resourceFilters

.NOTES
    Author: Kyle Poineal
    Date: 2024-08-07
#>

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER ObjectList
Parameter description

.PARAMETER FilterList
Parameter description

.PARAMETER KeyColumn
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>

<#
.SYNOPSIS
    Filters a list of objects based on resource group identifiers.

.DESCRIPTION
    The Get-WAFResourceGroupsByList function takes a list of objects and filters them based on the specified resource group identifiers.
    It compares the first five segments of the KeyColumn property of each object with the provided filter list.

.PARAMETER ObjectList
    An array of objects to be filtered.

.PARAMETER FilterList
    An array of resource group identifiers to filter the objects.

.PARAMETER KeyColumn
    The name of the property in the objects that contains the resource group identifier.

.EXAMPLE
    $objectList = @(
        @{ Id = "/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM" },
        @{ Id = "/subscriptions/12345/resourceGroups/anotherResourceGroup/providers/Microsoft.Compute/virtualMachines/anotherVM" }
    )
    $filterList = @("/subscriptions/12345/resourceGroups/myResourceGroup")

    $filteredObjects = Get-WAFResourceGroupsByList -ObjectList $objectList -FilterList $filterList -KeyColumn "Id"

.NOTES
    Author: Kyle Poineal
    Date: 2024-08-07
#>
function Get-WAFResourceGroupsByList {
    param (
      [Parameter(Mandatory = $true)]
      [array]$ObjectList,

      [Parameter(Mandatory = $true)]
      [array]$FilterList,

      [Parameter(Mandatory = $true)]
      [string]$KeyColumn
    )

    $matchingObjects = foreach ($obj in $ObjectList) {
      if (($obj.$KeyColumn.split('/')[0..4] -join '/') -in $FilterList) {
        $obj
      }
    }

    return $matchingObjects
  }

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

.EXAMPLE
    $objectList = @(
        @{ Id = "/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM" },
        @{ Id = "/subscriptions/67890/resourceGroups/anotherResourceGroup/providers/Microsoft.Compute/virtualMachines/anotherVM" }
    )
    $filterList = @("/subscriptions/12345")

    $filteredObjects = Get-WAFSubscriptionsByList -ObjectList $objectList -FilterList $filterList -KeyColumn "Id"

.NOTES
    Author: Kyle Poineal
    Date: 2024-08-07
#>
  function Get-WAFSubscriptionsByList {
    param (
      [Parameter(Mandatory = $true)]
      [array]$ObjectList,

      [Parameter(Mandatory = $true)]
      [array]$FilterList,

      [Parameter(Mandatory = $true)]
      [string]$KeyColumn
    )

    $matchingObjects = foreach ($obj in $ObjectList) {
      if (($obj.$KeyColumn.split('/')[0..2] -join '/') -in $FilterList) {
        $obj
      }
    }

    return $matchingObjects
  }

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

.EXAMPLE
    $objectList = @(
        @{ Id = "/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM" },
        @{ Id = "/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/anotherVM" }
    )
    $filterList = @("/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM")

    $filteredObjects = Get-WAFResourcesByList -ObjectList $objectList -FilterList $filterList -KeyColumn "Id"

.NOTES
    Author: Your Name
    Date: 2024-08-07
#>
  function Get-WAFResourcesByList {
    param (
      [Parameter(Mandatory = $true)]
      [array]$ObjectList,

      [Parameter(Mandatory = $true)]
      [array]$FilterList,

      [Parameter(Mandatory = $true)]
      [string]$KeyColumn
    )



    $matchingObjects = foreach ($obj in $ObjectList) {
      if ($obj.$KeyColumn -in $FilterList) {
        $obj
      }
    }

    return $matchingObjects
  }

<#
.SYNOPSIS
Retrieves unfiltered resources from Azure based on provided subscription, resource group, and resource filters.

.DESCRIPTION
The Get-WAFUnfilteredResourceList function takes an array of implicit subscription IDs and retrieves unfiltered resources from Azure using these subscription IDs.

.PARAMETER ImplicitSubscriptionId
An array of strings representing the implicit subscription IDs. Each string should be a subscription ID.

.OUTPUTS
Returns an array of unfiltered resources from Azure.

.EXAMPLE
$implicitSubscriptionIds = @('/subscriptions/11111111-1111-1111-1111-111111111111')
$unfilteredResources = Get-WAFUnfilteredResourceList -ImplicitSubscriptionId $implicitSubscriptionIds

.NOTES
This function assumes that the Get-WAFAllAzGraphResource function is defined and available in the current context. It also assumes that Azure authentication has been set up.
#>
function Get-WAFUnfilteredResourceList {
    param(
        [array]$ImplicitSubscriptionId
    )
    # Grab all resources in the implicit subscription ids
    $UnfilteredResources = Get-WAFAllAzGraphResource -subscriptionId ($ImplicitSubscriptionIds -replace ("/subscriptions/",""))
    return $UnfilteredResources
}

<#
.SYNOPSIS
Creates a list of unique subscription IDs based on provided subscription, resource group, and resource filters.

.DESCRIPTION
The Get-WAFImplicitSubscriptionId function takes arrays of subscription filters, resource group filters, and resource filters.
It creates a list of unique subscription IDs based on these filters by combining them, splitting them into subscription IDs, and removing duplicates.

.PARAMETER SubscriptionFilters
An array of strings representing the subscription filters. Each string should be a subscription ID or a part of a subscription ID.

.PARAMETER ResourceGroupFilters
An array of strings representing the resource group filters. Each string should be a resource group ID or a part of a resource group ID.

.PARAMETER ResourceFilters
An array of strings representing the resource filters. Each string should be a resource ID or a part of a resource ID.

.OUTPUTS
Returns an array of unique subscription IDs.

.EXAMPLE
$subscriptionFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111')
$resourceGroupFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/test1')
$resourceFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/test1/providers/Microsoft.Compute/virtualMachines/TestVM1')
$implicitSubscriptionIds = Get-WAFImplicitSubscriptionId -SubscriptionFilters $subscriptionFilters -ResourceGroupFilters $resourceGroupFilters -ResourceFilters $resourceFilters

.NOTES
This function assumes that the input filters are valid and properly formatted.
#>
function Get-WAFImplicitSubscriptionId {
    param(
        [array]$SubscriptionFilters,
        [array]$ResourceGroupFilters,
        [array]$ResourceFilters
    )
    # Create a list of subscription ids based on the filters. Adds all the filters together then splits them into subscription Ids. Groups them to remove duplicates and returns a string array.
    $ImplicitSubscriptionIds = (($SubscriptionFilters + $ResourceGroupFilters + $ResourceFilters) | ForEach-Object {$_.split("/")[0..2] -join "/"} | Group-Object | Select-Object Name).Name
    return $ImplicitSubscriptionIds
}

<#
.SYNOPSIS
Retrieves a filtered list of Azure resources based on subscription, resource group, and resource filters.

.DESCRIPTION
The Get-WAFFilteredResourceList function filters Azure resources by combining subscription, resource group, and resource filters.
It generates a list of implicit subscription IDs from the provided filters, retrieves unfiltered resources, and then applies the filters to return the matching resources.

.PARAMETER SubscriptionFilters
An array of subscription identifiers to filter the resources.

.PARAMETER ResourceGroupFilters
An array of resource group identifiers to filter the resources.

.PARAMETER ResourceFilters
An array of resource identifiers to filter the resources.

.PARAMETER UnfilteredResources
An array of unfiltered resources to be filtered.

.OUTPUTS
Returns an array of filtered resources from Azure.

.EXAMPLE
$subscriptionFilters = @("/subscriptions/12345")
$resourceGroupFilters = @("/subscriptions/12345/resourceGroups/myResourceGroup")
$resourceFilters = @("/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM")
$unfilteredResources = Get-WAFUnfilteredResourceList -ImplicitSubscriptionId (Get-WAFImplicitSubscriptionId -SubscriptionFilters $subscriptionFilters -ResourceGroupFilters $resourceGroupFilters -ResourceFilters $resourceFilters)
$filteredResources = Get-WAFFilteredResourceList -SubscriptionFilters $subscriptionFilters -ResourceGroupFilters $resourceGroupFilters -ResourceFilters $resourceFilters -UnfilteredResources $unfilteredResources

.NOTES
Author: Your Name
Date: 2024-08-07
#>
function Get-WAFFilteredResourceList {
    param(
        [array]$SubscriptionFilters,
        [array]$ResourceGroupFilters,
        [array]$ResourceFilters,
        [array]$UnfilteredResources
    )
    # TODO: ADD FILTERS FOR TAGS

    $SubscriptionFilters ? $($SubscriptionFilteredResources = Get-WAFSubscriptionsByList -ObjectList $UnfilteredResources -FilterList $SubscriptionFilters -KeyColumn "Id") : $(Write-Debug "Subscription Filters not provided.")

    $ResourceGroupFilters ? $($ResourceGroupFilteredResources = Get-WAFResourceGroupsByList -ObjectList $UnfilteredResources -FilterList $ResourceGroupFilters -KeyColumn "Id") : $(Write-Debug "Resource Group Filters not provided.")

    $ResourceFilters ? $($ResourceFilteredResources = Get-WAFResourcesByList -ObjectList $UnfilteredResources -FilterList $ResourceFilters -KeyColumn "Id") : $(Write-Debug "Resource Filters not provided.")

    # Originally used to remove duplicates but there was some weird interaction with the return object that caused it to duplicate the entire array. 
    # This just needs to be sorted outside of this function using | Sort-Object -Property Id,RecommendationId -Unique
    $FilteredResources = $SubscriptionFilteredResources + $ResourceGroupFilteredResources + $ResourceFilteredResources

    return $FilteredResources
}
