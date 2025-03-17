<#
.SYNOPSIS
    Invokes an Azure Resource Graph query.

.DESCRIPTION
    The `Invoke-WAFQuery` function executes an Azure Resource Graph query and returns the results. It handles pagination and consolidates results from multiple subscriptions if provided.

.PARAMETER Query
    The Kusto query string to execute against Azure Resource Graph.

.PARAMETER SubscriptionId
    An array of subscription IDs to scope the query to.

.INPUTS
    System.String. The query string.
    System.String[]. The array of subscription IDs.

.OUTPUTS
    System.Object[]. Returns an array of query results.

.EXAMPLE
    PS> $query = "Resources | where type =~ 'Microsoft.Compute/virtualMachines'"
    PS> $results = Invoke-WAFQuery -Query $query -SubscriptionId @("59f6f1ab-6d68-4c90-b4e5-ad2d71cefc57")

    This example retrieves all virtual machines within the specified subscription.

.EXAMPLE
    PS> $results = Invoke-WAFQuery -Query $query -SubscriptionId $subscriptionIds

    This example executes the query across multiple subscriptions.

.NOTES
    Author: Kyle Poineal
    Date: [Today's Date]
#>
function Invoke-WAFQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds,

        [Parameter(Mandatory = $false)]
        [string] $Query = 'resources | project name, type, location, resourceGroup, subscriptionId, id'
    )

    $result = $SubscriptionIds ? (Search-AzGraph -Query $Query -First 1000 -Subscription $SubscriptionIds) : (Search-AzGraph -Query $Query -First 1000 -UseTenantScope)

    # Collection to store all resources
    $allResources = @($result)

    # Loop to paginate through the results using the skip token
    $result = while ($result.SkipToken) {
        # Retrieve the next set of results using the skip token
        $result = $SubscriptionIds ? (Search-AzGraph -Query $Query -SkipToken $result.SkipToken -Subscription $SubscriptionIds -First 1000) : (Search-AzGraph -Query $Query -SkipToken $result.SkipToken -First 1000 -UseTenantScope)
        # Add the results to the collection
        Write-Output $result
    }

    $allResources += $result

    # Output all resources
    return , $allResources
}
