<#
.SYNOPSIS
    Retrieves high availability recommendations from Azure Advisor.

.DESCRIPTION
    The Get-WAFAdvisorRecommendations function queries Azure Advisor for recommendations related to high availability.
    It uses Azure Resource Graph to fetch and join relevant resource data.

.PARAMETER Subid
    The subscription ID for which to retrieve recommendations.

.PARAMETER ScopeObject
    The scope object to filter the recommendations (not currently used in the query).

.EXAMPLE
    $subId = "22222222-2222-2222-2222-222222222222"

.NOTES
    Author: Claudio Merola
    Date: 2024-08-07
#>
function Get-WAFAdvisorRecommendations {
    [CmdletBinding()]
    Param(
        [array]$Subid,
        [switch]$HighAvailability,
        [switch]$Security,
        [switch]$Cost,
        [switch]$Performance,
        [switch]$OperationalExcellence

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


    $advquery = "advisorresources 
                | where type == 'microsoft.advisor/recommendations' and tostring(properties.category) in ('$categoriesString') 
                | extend resId = tolower(tostring(properties.resourceMetadata.resourceId)) 
                | join kind=leftouter (resources 
                | project ['resId']=tolower(id), subscriptionId, resourceGroup ,location) on resId
                | project recommendationTypeId = properties.recommendationTypeId, type = tolower(properties.impactedField), name = properties.impactedValue, id = resId1, subscriptionId = subscriptionId1, location = location1, category = properties.category, impact = properties.impact, description = properties.shortDescription.solution
                | order by ['id']"
   
    $queryResults = Get-WAFAllAzGraphResource -Query $advquery -subscriptionId $Subid

    return $queryResults
}


<#
.SYNOPSIS
    Builds a list of advisory objects from Azure Advisor query results.

.DESCRIPTION
    The Build-WAFAdvisorObject function processes the results of an Azure Advisor query and constructs a list of advisory objects.
    Each advisory object contains details such as recommendation ID, type, name, resource ID, subscription ID, resource group, location, category, impact, and description.

.PARAMETER AdvQueryResult
    An array of query results from Azure Advisor.

.EXAMPLE
    $advQueryResult = Get-WAFAdvisorRecommendations -Subid "12345"

.NOTES
    Author: Claudio Merola
    Date: 2024-08-07
#>
function Build-WAFAdvisorObject {
    Param($AdvQueryResult)

    $AllAdvisories = foreach ($row in $AdvQueryResult) {
            $result = [PSCustomObject]@{
            recommendationId = [string]$row.properties.recommendationTypeId
            type             = [string]$row.Properties.impactedField
            name             = [string]$row.properties.impactedValue
            id               = [string]$row.resId1
            subscriptionId   = [string]$row.subscriptionId1
            resourceGroup    = [string]$row.resourceGroup1
            location         = [string]$row.location1
            category         = [string]$row.properties.category
            impact           = [string]$row.properties.impact
            description      = [string]$row.properties.shortDescription.solution
            }
            $result
        }
    return $AllAdvisories
}

