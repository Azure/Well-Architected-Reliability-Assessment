<#
.SYNOPSIS
    Retrieves active retirement health advisory events.

.DESCRIPTION
    This module contains functions related to the capturing and collecting to active retirement health advisory events.
    It includes the following functions:
    - Get-WAFResourceRetirement
    - New-WAFResourceRetirementObject

.EXAMPLE
    PS> $retirementObjects = Get-WAFResourceRetirement -SubscriptionId '11111111-1111-1111-1111-111111111111'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-02

    This function requires the Az.ResourceGraph module to be installed and imported.
#>

<#
.SYNOPSIS
    Retrieves active retirement health advisory events based on the specified subscription ID.

.DESCRIPTION
    The Get-WAFResourceRetirement function takes a subscription ID and retrieves active retirement health advisory events.

.PARAMETER SubscriptionId
    A subscription ID to retrieves active retirement health advisory events.

.PARAMETER ProgressAction
    This is a common parameter, but this cmdlet does not use this parameter.

.OUTPUTS
    Returns a list of retirement events, including the name and properties of each event.

.EXAMPLE
    PS> $retirementObjects = Get-WAFResourceRetirement -SubscriptionId '11111111-1111-1111-1111-111111111111'

    This example retrieves the recent retirement events for the specified Azure subscription.

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-02

    This function requires the Az.ResourceGraph module to be installed and imported.
#>
function Get-WAFResourceRetirement {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}$')]
        [string] $SubscriptionId
    )

    Import-Module -Name 'Az.ResourceGraph'

    $argQuery = @'
ServiceHealthResources
| where properties.EventSubType =~ "Retirement"  // Filter retirement events.
| where properties.Status =~ "Active"
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
    | where properties.EventSubType =~ "Retirement"
    | where properties.Status =~ "Active"
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

    $retirementEvents = Search-AzGraph -Subscription $SubscriptionId -First 1000 -Query $argQuery

    $retirementObjects = foreach ($retirementEvent in $retirementEvents) {
        $cmdletParams = @{
            SubscriptionId  = $retirementEvent.subscriptionId
            TrackingId      = $retirementEvent.trackingId
            Status          = $retirementEvent.status
            LastUpdateTime  = $retirementEvent.lastUpdateTime
            StartTime       = $retirementEvent.impactStartTime
            EndTime         = $retirementEvent.impactMitigationTime
            Level           = $retirementEvent.level
            Title           = $retirementEvent.title
            Summary         = $retirementEvent.summary
            Header          = $retirementEvent.header
            ImpactedService = $retirementEvent.impactedServices
            Description     = $retirementEvent.summary  # Use the summary as the description, it's by design..
        }
        New-WAFResourceRetirementObject @cmdletParams
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

.PARAMETER ProgressAction
    This is a common parameter, but this cmdlet does not use this parameter.

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
