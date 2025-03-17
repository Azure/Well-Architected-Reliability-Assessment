<#
.SYNOPSIS
    Invokes a loop to run queries for each recommendation object.

.DESCRIPTION
    The Invoke-WAFQueryLoop function runs queries for each recommendation object and retrieves the resources.

.PARAMETER RecommendationObject
    An array of recommendation objects to query.

.PARAMETER subscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of resources for each recommendation object.

.EXAMPLE
    $resources = Invoke-WAFQueryLoop -RecommendationObject $recommendations -subscriptionIds @('sub1', 'sub2')

.NOTES
    This function uses the Invoke-WAFQuery function to perform the queries.
#>
function Invoke-WAFQueryLoop {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $RecommendationObject,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]] $AddedTypes,

        [Parameter(Mandatory = $false)]
        [int] $ProgressId = 1
    )

    $Types = Get-WAFResourceType -SubscriptionIds $SubscriptionIds

    $QueryObject = Get-WAFQueryByResourceType -ObjectList $RecommendationObject -FilterList $Types.type -KeyColumn 'recommendationResourceType'

    # Add additional types to query based on specialized workloads (This works even if it's empty.)
    $QueryObject += $AddedTypes.Foreach({
        $type = $_
        $RecommendationObject.where({$_.tags -contains $type})
    }) | Sort-Object -Property "APRLGuid" | Get-Unique -AsString

    $return = $QueryObject.Where({ $_.automationAvailable -eq $true -and $_.recommendationMetadataState -eq "Active" -and [string]::IsNullOrEmpty($_.recommendationTypeId) }) | ForEach-Object {
        Write-Progress -Activity 'Running Queries' -Status "Running Query for $($_.recommendationResourceType) - $($_.aprlGuid)" -PercentComplete (($QueryObject.IndexOf($_) / $QueryObject.Count) * 100) -Id $ProgressId
        try {
            $recommendation = $_
            (Invoke-WAFQuery -Query $recommendation.query -SubscriptionIds $subscriptionIds -ErrorAction Stop)
        }
        catch {
            Write-Error "Error running query for - $($recommendation.recommendationResourceType) - $($recommendation.aprlGuid)"
        }
    }
    Write-Progress -Activity 'Running Queries' -Status 'Completed' -Completed -Id $ProgressId

    return $return
}
