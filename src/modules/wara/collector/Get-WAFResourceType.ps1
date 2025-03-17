<#
.SYNOPSIS
    Retrieves all resource types in the specified subscriptions.

.DESCRIPTION
    The Get-WAFResourceType function queries Azure Resource Graph to retrieve all resource types in the specified subscriptions.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of resource types.

.EXAMPLE
    $resourceTypes = Get-WAFResourceType -SubscriptionIds @('sub1', 'sub2')

.NOTES
    This function uses the Invoke-WAFQuery function to perform the query.
#>
function Get-WAFResourceType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $q = "Resources
| summarize count() by type
| project type"

    $r = $SubscriptionIds ? (Invoke-WAFQuery -Query $q -SubscriptionIds $SubscriptionIds) : (Invoke-WAFQuery -Query $q)

    return $r
}
