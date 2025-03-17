# ...existing comment-based help and code extracted from retirement.psm1...
<#
.SYNOPSIS
    Retrieves active retirement health advisory events based on the specified subscription ID.

.DESCRIPTION
    The Get-WAFResourceRetirement function takes a subscription ID and retrieves active retirement health advisory events.

.PARAMETER SubscriptionIds
    A subscription ID to retrieves active retirement health advisory events.

.OUTPUTS
    Returns a list of retirement events, including the name and properties of each event.

.EXAMPLE
    PS> $retirementObjects = Get-WAFResourceRetirement -SubscriptionIds '11111111-1111-1111-1111-111111111111'

    This example retrieves the recent retirement events for the specified Azure subscription.

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-02
#>
function Get-WAFResourceRetirement {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-WAFIsGuid -StringGuid $_ })]
        [string[]] $SubscriptionIds
    )

    $retirementObjects = @()

    foreach ($subscriptionId in $SubscriptionIds) {
        # NOTE:
        # ARG query with ServiceHealthResources returns last 3 months of events.
        # Azure portal shows last 1 months of events.
        $cmdletParams = @{
            Method               = 'GET'
            SubscriptionId       = $subscriptionId
            ResourceProviderName = 'Microsoft.ResourceHealth'
            ResourceType         = 'events'
            ApiVersion           = '2024-02-01'
            QueryString          = @(
                ('queryStartTime={0}' -f (Get-Date).AddMonths(-3).ToString('yyyy-MM-ddT00:00:00')),
                '$filter=(properties/eventType eq ''HealthAdvisory'') and (properties/eventSubType eq ''Retirement'') and (Properties/Status eq ''Active'')'
            ) -join '&'
        }
        $response = Invoke-AzureRestApi @cmdletParams
        $retirementEvents = ($response.Content | ConvertFrom-Json).value

        $return = foreach ($retirementEvent in $retirementEvents) {
            $cmdletParams = @{
                SubscriptionId  = $subscriptionId
                TrackingId      = $retirementEvent.name
                Status          = $retirementEvent.properties.status
                LastUpdateTime  = $retirementEvent.properties.lastUpdateTime
                StartTime       = $retirementEvent.properties.impactStartTime
                EndTime         = $retirementEvent.properties.impactMitigationTime
                Level           = $retirementEvent.properties.level
                Title           = $retirementEvent.properties.title
                Summary         = $retirementEvent.properties.summary
                Header          = $retirementEvent.properties.header
                ImpactedService = $retirementEvent.properties.impact.impactedService
                Description     = $retirementEvent.properties.description
            }
            New-WAFResourceRetirementObject @cmdletParams
        }
        $retirementObjects += $return
    }
    return $retirementObjects
}
