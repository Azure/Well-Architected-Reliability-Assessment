<#
.SYNOPSIS
    Retrieves high availability recommendations from Azure Advisor.

.DESCRIPTION
    The Get-WAFAdvisorRecommendation function queries Azure Advisor for recommendations related to high availability.
    It uses Azure Resource Graph to fetch and join relevant resource data.

.PARAMETER SubscriptionIds
    The subscription IDs for which to retrieve recommendations.

.PARAMETER AdditionalRecommendationIds
    Additional recommendation IDs to include in the query. In the WARA we use this to include Advisor recommendations that are not categorized as high availability but are still relevant.

.PARAMETER HighAvailability
    Switch to filter recommendations related to high availability.

.PARAMETER Security
    Switch to filter recommendations related to security.

.INPUTS
    None. You cannot pipe objects to this function.

.OUTPUTS
    System.Object. The function returns a list of recommendations.

.EXAMPLE
    $subId = "22222222-2222-2222-2222-222222222222"
    Get-WAFAdvisorRecommendation -SubscriptionIds $subId -HighAvailability

.EXAMPLE
    $subId = "22222222-2222-2222-2222-222222222222"
    $AddtionalRecommendationIds = @("82219546-1110-4f5d-a1c2-7defb204663c", "693e2dbf-cdec-47a2-8e54-79752cd7e3fc")
    Get-WAFAdvisorRecommendation -SubscriptionIds $subId -HighAvailability -AdditionalRecommendationIds $AddtionalRecommendationIds

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
function Get-WAFAdvisorRecommendation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array] $SubscriptionIds,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [array] $AdditionalRecommendationIds,

        [switch] $HighAvailability,

        [switch] $Security,

        [switch] $Cost,

        [switch] $Performance,

        [switch] $OperationalExcellence
    )

    # Initialize an array to hold the selected categories
    $categories = @()

    # Add categories based on the selected switches
    switch ($PSBoundParameters.Keys) {
        'HighAvailability' { $categories += 'HighAvailability' }
        'Security' { $categories += 'Security' }
        'Cost' { $categories += 'Cost' }
        'Performance' { $categories += 'Performance' }
        'OperationalExcellence' { $categories += 'OperationalExcellence' }
    }

    # Convert the categories array to a comma-separated string
    $categoriesString = $categories -join "','"
    $AdditionalRecommendationIdsString = $AdditionalRecommendationIds -join "','"

    $advquery = `
        "advisorresources
| where type == 'microsoft.advisor/recommendations'
| where tostring(properties.category) in ('$categoriesString') or properties.recommendationTypeId in ('$AdditionalRecommendationIdsString')
| where properties.tracked !~ 'true'
| extend resId = tolower(tostring(properties.resourceMetadata.resourceId))
| join kind=leftouter (resources | project ['resId']=tolower(id), subscriptionId, resourceGroup, location, type) on resId
| extend id = iff(properties.impactedField =~ 'microsoft.subscriptions/subscriptions', strcat('/subscriptions/', subscriptionId), resId1)
| extend subscriptionId = coalesce(subscriptionId,subscriptionId1)
| extend resourceGroup = iff(properties.impactedField =~ 'microsoft.subscriptions/subscriptions', 'N/A', resourceGroup)
| extend location = iff(properties.impactedField =~ 'microsoft.subscriptions/subscriptions', 'global', coalesce(location,location1))
| extend type = iff(properties.impactedField =~ 'microsoft.subscriptions/subscriptions', 'microsoft.subscription/subscriptions', tolower(properties.impactedField))
| project recommendationId = properties.recommendationTypeId, type, name = properties.impactedValue, id, subscriptionId, resourceGroup, location, category = properties.category, impact = properties.impact, description = properties.shortDescription.solution
| order by ['id']"

    $queryResults = Invoke-WAFQuery -Query $advquery -SubscriptionId $SubscriptionIds

    $return = Build-WAFAdvisorObject -AdvQueryResult $queryResults

    return $return
}
