<#
.SYNOPSIS
    Retrieves recent outage events for a given Azure subscription.

.DESCRIPTION
    The Get-WAFOldOutage function queries the Microsoft Resource Health API to retrieve recent outage events for a specified Azure subscription. It filters the events to include only those that have updated in the last three months.
    This function is used for backwards compatibility with current versions of the Analyzer script.

.PARAMETER SubscriptionIds
    The subscription ID for the Azure subscription to retrieve outage events.

.OUTPUTS
    Returns a list of outage events, including the name and properties of each event.

.EXAMPLE
    PS> $outageObjects = Get-WAFOldOutage -SubscriptionIds '11111111-1111-1111-1111-111111111111'

    This example retrieves the recent outage events for the specified Azure subscription.

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-16
#>
function Get-WAFOldOutage {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-WAFIsGuid -StringGuid $_ })]
        [string[]] $SubscriptionIds
    )

    $serviceIssueEvents = foreach ($subscriptionId in $SubscriptionIds) {
        # NOTE:
        # ARG query with ServiceHealthResources returns last 3 months of events.
        # Azure portal shows last 3 months of events maximum.
        $cmdletParams = @{
            Method               = 'GET'
            SubscriptionId       = $subscriptionId
            ResourceProviderName = 'Microsoft.ResourceHealth'
            ResourceType         = 'events'
            ApiVersion           = '2024-02-01'
            QueryString          = @(
                ('queryStartTime={0}' -f (Get-Date).AddMonths(-3).ToString('yyyy-MM-ddT00:00:00')),
                '$filter=(properties/eventType eq ''ServiceIssue'')'
            ) -join '&'
        }
        $response = Invoke-AzureRestApi @cmdletParams
        ($response.Content | ConvertFrom-Json).value | Select-Object name, properties
    }

    return $serviceIssueEvents
}
