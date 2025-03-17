<#
.SYNOPSIS
    Retrieves recent outage service issue events.

.DESCRIPTION
    The Get-WAFOutage function queries the Microsoft Resource Health API to retrieve recent outage events for a specified Azure subscription. It filters the events to include only those that have updated in the last three months.

.PARAMETER SubscriptionIds
    The subscription ID for the Azure subscription to retrieve outage events.

.OUTPUTS
    Returns a list of outage events, including the name and properties of each event.

.EXAMPLE
    PS> $outageObjects = Get-WAFOutage -SubscriptionIds '11111111-1111-1111-1111-111111111111'

    This example retrieves the recent outage events for the specified Azure subscription.

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-23
#>
function Get-WAFOutage {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-WAFIsGuid -StringGuid $_ })]
        [string[]] $SubscriptionIds
    )

    $outageObjects = @()

    foreach ($subscriptionId in $SubscriptionIds) {
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
        $serviceIssueEvents = ($response.Content | ConvertFrom-Json).value

        $return = foreach ($serviceIssueEvent in $serviceIssueEvents) {
            $cmdletParams = @{
                SubscriptionId  = $subscriptionId
                TrackingId      = $serviceIssueEvent.name
                Status          = $serviceIssueEvent.properties.status
                LastUpdateTime  = $serviceIssueEvent.properties.lastUpdateTime
                StartTime       = $serviceIssueEvent.properties.impactStartTime
                EndTime         = $serviceIssueEvent.properties.impactMitigationTime
                Level           = $serviceIssueEvent.properties.level
                Title           = $serviceIssueEvent.properties.title
                Summary         = $serviceIssueEvent.properties.summary
                Header          = $serviceIssueEvent.properties.header
                ImpactedService = $serviceIssueEvent.properties.impact.impactedService
                Description     = $serviceIssueEvent.properties.description
            }
            New-WAFOutageObject @cmdletParams
        }
        $outageObjects += $return
    }

    return $outageObjects
}
