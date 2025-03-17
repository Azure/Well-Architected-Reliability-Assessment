<#
.SYNOPSIS
    Retrieves service health alerts from specified Azure subscriptions.

.DESCRIPTION
    The `Get-WAFServiceHealth` function queries Azure Resource Graph to retrieve service health alerts from the provided subscription IDs. It searches for activity log alerts related to 'ServiceHealth' and joins them with subscription information.

.PARAMETER SubscriptionIds
    An array of Azure subscription IDs for which to retrieve service health alerts.

.INPUTS
    None. You cannot pipe objects to this function.

.OUTPUTS
    System.Object[]. Returns an array of service health alert objects.

.EXAMPLE
    # Retrieve service health alerts for multiple subscriptions
    $subscriptions = @('59f6f1ab-6d68-4c90-b4e5-ad2d71cefc57', 'abcd1234-5678-90ab-cdef-1234567890ab')
    $serviceHealthAlerts = Get-WAFServiceHealth -SubscriptionIds $subscriptions

.EXAMPLE
    # Retrieve service health alerts for a single subscription
    $serviceHealthAlerts = Get-WAFServiceHealth -SubscriptionIds '59f6f1ab-6d68-4c90-b4e5-ad2d71cefc57'

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
function Get-WAFServiceHealth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $Servicequery = `
        "resources
| where type == 'microsoft.insights/activitylogalerts' and properties.condition has 'ServiceHealth'
| join kind=inner (
    resourcecontainers
    | where type == 'microsoft.resources/subscriptions'
    | project subscriptionId, subscriptionName = name
) on subscriptionId
| project subscriptionId, subscriptionName, eventName = name, type, location, resourceGroup, properties"

    $queryResults = Invoke-WAFQuery -Query $Servicequery -SubscriptionIds $SubscriptionIds

    $AllServiceHealth = Build-WAFServiceHealthObject -AdvQueryResult $queryResults

    return $AllServiceHealth
}
