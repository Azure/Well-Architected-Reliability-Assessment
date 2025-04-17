using module ../utils/utils.psd1

<#
.SYNOPSIS
    Retrieves high availability recommendations from Azure Advisor.

.DESCRIPTION
    The Get-WAFAdvisorRecommendations function queries Azure Advisor for recommendations related to high availability.
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
$AddtionalRecommendationIds = @()"82219546-1110-4f5d-a1c2-7defb204663c","693e2dbf-cdec-47a2-8e54-79752cd7e3fc")
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
| where tostring(properties.category) in ('$categoriesString') or properties.recommendationTypeId in ('$additionalRecommendationIdsString')
| where properties.tracked !~ 'true' and properties.extendedProperties.recommendationControl != 'ServiceUpgradeAndRetirement'
| extend resId = tolower(tostring(properties.resourceMetadata.resourceId))
| join kind=leftouter (resources | project ['resId']=tolower(id), subscriptionId, resourceGroup, location, type) on resId
| extend id = iff(properties.impactedField =~ 'microsoft.subscriptions/subscriptions', strcat('/subscriptions/', subscriptionId), resId1)
| extend subscriptionId = coalesce(subscriptionId,subscriptionId1)
| extend resourceGroup = iff(properties.impactedField =~ 'microsoft.subscriptions/subscriptions', 'N/A', resourceGroup)
| extend location = iff(properties.impactedField =~ 'microsoft.subscriptions/subscriptions', 'global', coalesce(location,location1))
| extend type = iff(properties.impactedField =~ 'microsoft.subscriptions/subscriptions', 'microsoft.subscription/subscriptions', tolower(properties.impactedField))
| project recommendationId = properties.recommendationTypeId, type, name = properties.impactedValue, id, subscriptionId, resourceGroup, location, category = properties.category, impact = properties.impact, description = properties.shortDescription.solution
| order by ['id']"

    <#  $advquery = `
"advisorresources
| where type == 'microsoft.advisor/recommendations' and tostring(properties.category) in ('$categoriesString')
| extend resId = tolower(tostring(properties.resourceMetadata.resourceId))
| join kind=leftouter (resources
| project ['resId']=tolower(id), subscriptionId, resourceGroup ,location) on resId
| project recommendationId = properties.recommendationTypeId, type = tolower(properties.impactedField), name = properties.impactedValue, id = resId1, subscriptionId = subscriptionId1,resourceGroup = resourceGroup, location = location1, category = properties.category, impact = properties.impact, description = properties.shortDescription.solution
| order by ['id']" #>

    $queryResults = Invoke-WAFQuery -Query $advquery -SubscriptionId $SubscriptionIds

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
    Author: Kyle Poineal
    Date: 2024-12-12
#>

<#
.SYNOPSIS
    Builds a list of Advisor resource objects from Azure Advisor query results.

.DESCRIPTION
    The `Build-WAFAdvisorObject` function processes the results of an Azure Advisor query and constructs a list of `advisorResourceObj` objects. Each object contains detailed information about an Advisor recommendation, including IDs, resource details, category, impact, and descriptions.

.PARAMETER AdvQueryResult
    An array of query results from Azure Advisor.

.INPUTS
    System.Object[]. You can pipe an array of Advisor query results to this function.

.OUTPUTS
    advisorResourceObj[]. The function returns an array of `advisorResourceObj` instances representing Advisor recommendations.

.EXAMPLE
    $advQueryResult = Get-WAFAdvisorRecommendation -SubscriptionIds "12345" -HighAvailability
    $advisorObjects = Build-WAFAdvisorObject -AdvQueryResult $advQueryResult

    This example builds Advisor resource objects from the query results.

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
function Build-WAFAdvisorObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $AdvQueryResult
    )

    # Initialize an array to hold the processed objects
    $return = $AdvQueryResult.ForEach({ [advisorResourceObj]::new($_) })

    # Return the processed objects
    return $return
}

<#
.SYNOPSIS
    Represents an Azure Advisor recommendation resource object.

.DESCRIPTION
    The `advisorResourceObj` class encapsulates the details of an Azure Advisor recommendation resource. It contains properties such as recommendation ID, type, name, resource ID, subscription ID, resource group, location, category, impact, and description.

.PARAMETER Recommendation
    A recommendation object returned from Azure Advisor.

    The attributes of the object are used to populate the properties of the `advisorResourceObj` instance.

    [string] $recommendationId
    [string] $type
    [string] $name
    [string] $id
    [string] $subscriptionId
    [string] $resourceGroup
    [string] $location
    [string] $category
    [string] $impact
    [string] $description

.INPUTS
    None. You cannot pipe input to this class.

.OUTPUTS
    advisorResourceObj. An instance representing an Advisor recommendation.

.EXAMPLE
    $advisorRecommendation = [advisorResourceObj]::new($recommendation)

    This example creates a new instance of `advisorResourceObj` using a recommendation object.

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
class advisorResourceObj : IComparable, IEquatable[object] {
    <# Define the class. Try constructors, properties, or methods. #>
    [string] $recommendationId
    [string] $type
    [string] $name
    [string] $id
    [string] $subscriptionId
    [string] $resourceGroup
    [string] $location
    [string] $category
    [string] $impact
    [string] $description

    # Default Constructor that takes a PSObject as input
    # Right now this is just a simple assignment of properties, but can be expanded to include more complex logic in the future.
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

    # Implement the Equals method to equate two advisorResourceObj objects
    [bool] Equals([object] $other) {
        if ($other -isnot [advisorResourceObj]) {
            throw "Expected an advisorResourceObj object"
        }
        foreach ($property in $this.PSObject.Properties.Name) {
            if ($this.$property -ne $other.$property) {
                return $false
            }
        }
        return $true
    }

    # Implement the CompareTo method to compare two advisorResourceObj objects
    [int] CompareTo([object] $other) {
        if ($other -isnot [advisorResourceObj]) {
            throw "Expected an advisorResourceObj object"
        }
        foreach ($property in $this.PSObject.Properties.Name) {
            if ($this.$property -ne $other.$property) {
                return $this.$property.CompareTo($other.$property)
            }
        }
        return 0
    }

    # Implements the GetHashCode method to generate a hash code for the advisorResourceObj object
    #[int] GetHashCode() {
    #    return [System.HashCode]::Combine($this.RecommendationId, $this.Type, $this.Name, $this.Id, $this.SubscriptionId, $this.ResourceGroup, $this.Location, $this.Category, $this.Impact, $this.Description)
    #}

}


<#
.SYNOPSIS
    Retrieves metadata from Azure Advisor.

.DESCRIPTION
    The Get-WAFAdvisorMetadata function retrieves metadata from Azure Advisor using the Azure REST API.
    It uses an access token to authenticate and fetch the metadata.

.INPUTS
    None. You cannot pipe objects to this function.

.OUTPUTS
    System.Object. The function returns the supported values from the Advisor metadata.

.EXAMPLE
    $AdvisorMetadata = Get-WAFAdvisorMetadata

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
Function Get-WAFAdvisorMetadata {
    param($ResourceURL = "https://management.azure.com/" )

    # Get an access token for the Azure REST API
    $securetoken = Get-AzAccessToken -AsSecureString -ResourceUrl $ResourceURL -WarningAction SilentlyContinue

    # Convert the secure token to a plain text token
    $token = ConvertFrom-SecureString -SecureString $securetoken.token -AsPlainText

    # Create the authorization headers
    $authHeaders = @{
        'Authorization' = 'Bearer ' + $token
    }

    # Define the URI for the Advisor metadata
    $AdvisorMetadataURI = $ResourceUrl+"providers/Microsoft.Advisor/metadata?api-version=2023-01-01" #&%24expand=ibiza will return the full metadata. Use this soon to pull in the long description.

    # Invoke the REST API to get the metadata
    $r = Invoke-RestMethod -Uri $AdvisorMetadataURI -Headers $authHeaders -Method Get

    # Return the supported values from the metadata
    return $r.value.properties[0].supportedValues
}
