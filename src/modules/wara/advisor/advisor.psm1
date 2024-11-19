using module ../utils/utils.psd1

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


    $advquery = `
"advisorresources 
| where type == 'microsoft.advisor/recommendations' and tostring(properties.category) in ('$categoriesString') 
| extend resId = tolower(tostring(properties.resourceMetadata.resourceId)) 
| join kind=leftouter (resources 
| project ['resId']=tolower(id), subscriptionId, resourceGroup ,location) on resId
| project recommendationId = properties.recommendationTypeId, type = tolower(properties.impactedField), name = properties.impactedValue, id = resId1, subscriptionId = subscriptionId1,resourceGroup = resourceGroup, location = location1, category = properties.category, impact = properties.impact, description = properties.shortDescription.solution
| order by ['id']"
   
    $queryResults = Invoke-WAFQuery -Query $advquery -subscriptionId $Subid

    $return = Build-WAFAdvisorObject -AdvQueryResult $queryResults

    return $return
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

    $return = $AdvQueryResult.ForEach({ [advisorResourceObj]::new($_) })

    return $return

}

class advisorResourceObj {
    <# Define the class. Try constructors, properties, or methods. #>
    [string]    $recommendationId
    [string]    $type
    [string]    $name
    [string]    $id
    [string]    $subscriptionId
    [string]    $resourceGroup
    [string]    $location
    [string]    $category
    [string]    $impact
    [string]    $description

    advisorResourceObj([PSObject]$psObject) {
        $this.RecommendationId = $psObject.recommendationId
        $this.Type = $psObject.type
        $this.Name = $psObject.name
        $this.Id = $psObject.id
        $this.SubscriptionId = $psObject.subscriptionId
        $this.ResourceGroup = $psObject.resourceGroup
        $this.Location = $psObject.location
        $this.Category = $psObject.category
        $this.Impact = $psObject.impact
        $this.Description = $psObject.description 
    }
}

