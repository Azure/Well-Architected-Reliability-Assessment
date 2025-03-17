# ...existing comment-based help and code extracted from retirement.psm1...
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
