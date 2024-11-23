using module ../utils/utils.psm1

<#
.SYNOPSIS
    Retrieves active retirement health advisory events.

.DESCRIPTION
    This module contains functions related to the capturing and collecting to active retirement health advisory events.
    It includes the following functions:
    - Get-WAFResourceRetirement
    - New-WAFResourceRetirementObject

.EXAMPLE
    PS> $retirementObjects = Get-WAFResourceRetirement -SubscriptionIds '11111111-1111-1111-1111-111111111111'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-02
#>

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
        [ValidatePattern('^[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}$')]
        [string[]] $SubscriptionIds
    )

    $retirementObjects = @()
    # NOTE:
    # ARG query with ServiceHealthResources returns last 3 months of events.
    # Azure portal shows last 1 months of events.
    foreach ($SubscriptionId in $SubscriptionIds) {
        $cmdletParams = @{
            Method               = 'GET'
            SubscriptionId       = $SubscriptionId
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
                SubscriptionId  = $SubscriptionId
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


<#
.SYNOPSIS
    Creates a retirement object.

.DESCRIPTION
    The New-WAFResourceRetirementObject function creates a retirement object based on the specified parameters.

.PARAMETER SubscriptionId
    The subscription ID of the retirement event.

.PARAMETER TrackingId
    The tracking ID of the retirement event. It's usually as the XXXX-XXX format.

.PARAMETER Status
    The status of the retirement event. It's usually Active or Resolved.

.PARAMETER LastUpdateTime
    The last update time of the retirement event.

.PARAMETER StartTime
    The impact start time of the retirement event.

.PARAMETER EndTime
    The impact mitigation time of the retirement event.

.PARAMETER Level
    The level of the retirement event such as Warning, etc.

.PARAMETER Title
    The title of the retirement event.

.PARAMETER Summary
    The summary of the retirement event.

.PARAMETER Header
    The header of the retirement event.

.PARAMETER ImpactedService
    The impacted services of the retirement event.

.PARAMETER Description
    The description of the retirement event.

.OUTPUTS
    Returns a ResourceRetirementObject as a PSCustomObject.

.EXAMPLE
    PS> $retirementObject = New-WAFResourceRetirementObject -SubscriptionId $subscriptionId -TrackingId 'XXXX-XXX' -Status 'Active' -LastUpdateTime $lastUpdateTime -StartTime $startTime -EndTime $endTime -Level 'Warning' -Title $title -Summary $summary -Header $header -ImpactedService $impactedServices -Description $description

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-02
#>
function New-WAFResourceRetirementObject {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}$')]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string] $TrackingId,

        [Parameter(Mandatory = $true)]
        [string] $Status,

        [Parameter(Mandatory = $true)]
        [datetime] $LastUpdateTime,

        [Parameter(Mandatory = $true)]
        [datetime] $StartTime,

        [Parameter(Mandatory = $true)]
        [datetime] $EndTime,

        [Parameter(Mandatory = $true)]
        [string] $Level,

        [Parameter(Mandatory = $true)]
        [string] $Title,

        [Parameter(Mandatory = $true)]
        [string] $Summary,

        [Parameter(Mandatory = $true)]
        [string] $Header,

        [Parameter(Mandatory = $true)]
        [string[]] $ImpactedService,

        [Parameter(Mandatory = $true)]
        [string] $Description
    )

    return [PSCustomObject] @{
        Subscription    = $SubscriptionId
        TrackingId      = $TrackingId
        Status          = $Status
        LastUpdateTime  = $LastUpdateTime.ToString('yyyy-MM-dd HH:mm:ss')
        StartTime       = $StartTime.ToString('yyyy-MM-dd HH:mm:ss')
        EndTime         = $EndTime.ToString('yyyy-MM-dd HH:mm:ss')
        Level           = $Level
        Title           = $Title
        Summary         = $Summary
        Header          = $Header
        ImpactedService = $ImpactedService -join ', '
        Description     = $Description
    }
}
