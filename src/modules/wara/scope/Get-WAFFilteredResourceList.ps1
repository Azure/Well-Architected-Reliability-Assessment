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
.PARAMETER KeyColumn
    The property name used for filtering (default is 'Id').
.OUTPUTS
    Returns an array of filtered resources.
.EXAMPLE
    $subscriptionFilters = @("/subscriptions/12345")
    $resourceGroupFilters = @("/subscriptions/12345/resourceGroups/myResourceGroup")
    $resourceFilters = @("/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM")
    $unfilteredResources = Get-WAFUnfilteredResourceList -ImplicitSubscriptionId (Get-WAFImplicitSubscriptionId -SubscriptionFilters $subscriptionFilters -ResourceGroupFilters $resourceGroupFilters -ResourceFilters $resourceFilters)
    $filteredResources = Get-WAFFilteredResourceList -SubscriptionFilters $subscriptionFilters -ResourceGroupFilters $resourceGroupFilters -ResourceFilters $resourceFilters -UnfilteredResources $unfilteredResources
#>
function Get-WAFFilteredResourceList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]] $SubscriptionFilters = @(),
        [Parameter(Mandatory = $false)]
        [string[]] $ResourceGroupFilters = @(),
        [Parameter(Mandatory = $false)]
        [string[]] $ResourceFilters = @(),
        [Parameter(Mandatory = $true)]
        [array] $UnfilteredResources,
        [Parameter(Mandatory = $false)]
        [string] $KeyColumn = 'Id'
    )
    ##TODO: Replace all of this with something like $scopes.foreach({$allresources -match "$_*"})
    $SubscriptionFilteredResources = @()
    $SubscriptionFilters ? $($SubscriptionFilteredResources = Get-WAFSubscriptionsByList -ObjectList $UnfilteredResources -FilterList $SubscriptionFilters -KeyColumn $KeyColumn) : $(Write-Debug 'Subscription Filters not provided.')
    $ResourceGroupFilteredResources = @()
    $ResourceGroupFilters ? $($ResourceGroupFilteredResources = Get-WAFResourceGroupsByList -ObjectList $UnfilteredResources -FilterList $ResourceGroupFilters -KeyColumn $KeyColumn) : $(Write-Debug 'Resource Group Filters not provided.')
    $ResourceFilteredResources = @()
    $ResourceFilters ? $($ResourceFilteredResources = Get-WAFResourcesByList -ObjectList $UnfilteredResources -FilterList $ResourceFilters -KeyColumn $KeyColumn) : $(Write-Debug 'Resource Filters not provided.')
    $FilteredResources = @()
    $FilteredResources += $SubscriptionFilteredResources + $ResourceGroupFilteredResources + $ResourceFilteredResources
    $FilteredResources = [System.Linq.Enumerable]::Distinct([object[]]$FilteredResources).toArray()
    return ,$FilteredResources
}
