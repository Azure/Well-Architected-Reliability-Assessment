<#
.SYNOPSIS
    Creates a list of unique subscription IDs based on provided subscription, resource group, and resource filters.
.DESCRIPTION
    The Get-WAFImplicitSubscriptionId function takes arrays of subscription filters, resource group filters, and resource filters.
    It creates a list of unique subscription IDs based on these filters by combining them, splitting them into subscription IDs, and removing duplicates.
.PARAMETER SubscriptionFilters
    An array of strings representing the subscription filters.
.PARAMETER ResourceGroupFilters
    An array of strings representing the resource group filters.
.PARAMETER ResourceFilters
    An array of strings representing the resource filters.
.OUTPUTS
    Returns an array of unique subscription IDs.
.EXAMPLE
    $subscriptionFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111')
    $resourceGroupFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/test1')
    $resourceFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/test1/providers/Microsoft.Compute/virtualMachines/TestVM1')
    $implicitSubscriptionIds = Get-WAFImplicitSubscriptionId -SubscriptionFilters $subscriptionFilters -ResourceGroupFilters $resourceGroupFilters -ResourceFilters $resourceFilters
#>
function Get-WAFImplicitSubscriptionId {
    param (
        [array] $SubscriptionFilters = @(),
        [array] $ResourceGroupFilters = @(),
        [array] $ResourceFilters = @()
    )
    $ImplicitSubscriptionIds = (($SubscriptionFilters + $ResourceGroupFilters + $ResourceFilters) | ForEach-Object { $_.split("/")[0..2] -join "/" } | Group-Object | Select-Object Name).Name
    return $ImplicitSubscriptionIds
}
