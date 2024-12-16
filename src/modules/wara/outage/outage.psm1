using module ../utils/utils.psd1

<#
.SYNOPSIS
    Retrieves recent outage service issue events.

.DESCRIPTION
    This module contains functions related to the capturing and collecting to recent outage service issue events.
    It includes the following functions:
    - Get-WAFOutage
    - New-WAFOutageObject

.EXAMPLE
    PS> $outageObjects = Get-WAFOutage -SubscriptionIds '11111111-1111-1111-1111-111111111111'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-23
#>

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
        ($response.Content | ConvertFrom-Json).value | select name, properties
    }

    return $serviceIssueEvents
}

<#
.SYNOPSIS
    Retrieves recent outage service issue events.

.DESCRIPTION
    This module contains functions related to the capturing and collecting to recent outage service issue events.
    It includes the following functions:
    - Get-WAFOutage
    - New-WAFOutageObject

.EXAMPLE
    PS> $outageObjects = Get-WAFOutage -SubscriptionIds '11111111-1111-1111-1111-111111111111'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-23
#>

<#
.SYNOPSIS
    Retrieves recent outage events for a given Azure subscription.

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

<#
.SYNOPSIS
    Creates an outage object.

.DESCRIPTION
    The New-WAFOutageObject function creates an outage object based on the specified parameters.

.PARAMETER SubscriptionId
    The subscription ID of the outage event.

.PARAMETER TrackingId
    The tracking ID of the outage event. It's usually as the XXXX-XXX format.

.PARAMETER Status
    The status of the outage event. It's usually Active or Resolved.

.PARAMETER LastUpdateTime
    The last update time of the outage event.

.PARAMETER StartTime
    The impact start time of the outage event.

.PARAMETER EndTime
    The impact mitigation time of the outage event.

.PARAMETER Level
    The level of the outage event such as Warning, etc.

.PARAMETER Title
    The title of the outage event.

.PARAMETER Summary
    The summary of the outage event.

.PARAMETER Header
    The header of the outage event.

.PARAMETER ImpactedService
    The impacted services of the outage event.

.PARAMETER Description
    The description of the outage event.

.OUTPUTS
    Returns an OutageObject as a PSCustomObject.

.EXAMPLE
    PS> $outageObject = New-WAFOutageObject -SubscriptionId $subscriptionId -TrackingId 'XXXX-XXX' -Status 'Active' -LastUpdateTime $lastUpdateTime -StartTime $startTime -EndTime $endTime -Level 'Warning' -Title $title -Summary $summary -Header $header -ImpactedService $impactedServices -Description $description

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-23
#>
function New-WAFOutageObject {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-WAFIsGuid -StringGuid $_ })]
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
