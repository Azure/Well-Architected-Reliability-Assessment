<#
.SYNOPSIS
    Retrieves recent outage service issue events.

.DESCRIPTION
    This module contains functions related to the capturing and collecting to recent outage service issue events.
    It includes the following functions:
    - Get-WAFOutage
    - New-WAFOutageObject

.EXAMPLE
    PS> $outageObjects = Get-WAFOutage -SubscriptionId '11111111-1111-1111-1111-111111111111'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-23

    This module requires the Az.ResourceGraph module to be installed and imported.
#>

<#
.SYNOPSIS
    Retrieves recent outage events for a given Azure subscription.

.DESCRIPTION
    The Get-WAFOutage function queries the Microsoft Resource Health API to retrieve recent outage events for a specified Azure subscription. It filters the events to include only those that have updated in the last three months.

.PARAMETER SubscriptionId
    The subscription ID for the Azure subscription to retrieve outage events.

.PARAMETER ProgressAction
    This is a common parameter, but this cmdlet does not use this parameter.

.OUTPUTS
    Returns a list of outage events, including the name and properties of each event.

.EXAMPLE
    PS> $outageObjects = Get-WAFOutage -SubscriptionId '11111111-1111-1111-1111-111111111111'

    This example retrieves the recent outage events for the specified Azure subscription.

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-23

    This function requires the Az.ResourceGraph module to be installed and imported.
#>
function Get-WAFOutage {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}$')]
        [string] $SubscriptionId
    )

    $argQuery = @'
ServiceHealthResources
| where properties.EventType =~ "ServiceIssue"  // Filter outage events.
| project
    subscriptionId       = split(id, "/", 2)[0],
    trackingId           = tostring(properties.TrackingId),
    status               = properties.Status,
    lastUpdateTime       = todatetime(properties.LastUpdateTime),        // UTC
    impactStartTime      = todatetime(properties.ImpactStartTime),       // UTC
    impactMitigationTime = todatetime(properties.ImpactMitigationTime),  // UTC
    level                = properties.Level,
    ["title"]            = properties.Title,  // Enclosed the column name because "title" is a reserved keyword.
    summary              = properties.Summary,
    header               = properties.Header
| where lastUpdateTime >= datetime_add("Month", -3, now())  // Last 3 months (not the same as 90 days).
| join kind = leftouter (
    // Retrieve the tracking ID and impacted services pairs.
    ServiceHealthResources
    | where properties.EventType =~ "ServiceIssue"
    | mv-expand impact = properties.Impact
    | project trackingId = tostring(properties.TrackingId), impactedService = tostring(impact.ImpactedService)
    | distinct trackingId, impactedService
    | summarize impactedServices = make_list(impactedService) by trackingId
    )
    on trackingId
| project
    subscriptionId,
    trackingId,
    status,
    lastUpdateTime,
    impactStartTime,
    impactMitigationTime,
    level,
    ["title"],
    summary,
    header,
    impactedServices
'@

    $serviceIssueEvents = Search-AzGraph -Subscription $SubscriptionId -First 1000 -Query $argQuery

    $outageObjects = foreach ($serviceIssueEvent in $serviceIssueEvents) {
        $cmdletParams = @{
            SubscriptionId  = $serviceIssueEvent.subscriptionId
            TrackingId      = $serviceIssueEvent.trackingId
            Status          = $serviceIssueEvent.status
            LastUpdateTime  = $serviceIssueEvent.lastUpdateTime
            StartTime       = $serviceIssueEvent.impactStartTime
            EndTime         = $serviceIssueEvent.impactMitigationTime
            Level           = $serviceIssueEvent.level
            Title           = $serviceIssueEvent.title
            Summary         = $serviceIssueEvent.summary
            Header          = $serviceIssueEvent.header
            ImpactedService = $serviceIssueEvent.impactedServices
            Description     = $serviceIssueEvent.summary  # Use the summary as the description.
        }
        New-WAFOutageObject @cmdletParams
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

.PARAMETER ProgressAction
    This is a common parameter, but this cmdlet does not use this parameter.

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
