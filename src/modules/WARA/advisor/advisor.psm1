<#
.SYNOPSIS
Retrieves Azure Advisor recommendations for the specified subscriptions.

.DESCRIPTION
The Get-WAFAdvisorRecommendations function queries Azure Advisor recommendations for the specified subscriptions.
It filters the recommendations to include only those in the 'HighAvailability' category and orders them by ID.

.PARAMETER Subid
An array of subscription IDs for which to retrieve the recommendations.

.PARAMETER ScopeObject
An array of scope objects used for filtering the recommendations.

.OUTPUTS
Returns an array of Azure Advisor recommendations.

.EXAMPLE
$subIds = @('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')
$scopeObject = @{}
$recommendations = Get-WAFAdvisorRecommendations -Subid $subIds -ScopeObject $scopeObject

.NOTES
This function assumes that the Invoke-WAFQuery function is defined and available in the current context.
#>
function Get-WAFAdvisorRecommendations {
    param(
        [array]$Subid,
        [array]$ScopeObject
    )
 
    $advquery = "advisorresources | where type == 'microsoft.advisor/recommendations' and tostring(properties.category) in ('HighAvailability') | order by id"
    $queryResults = Get-WAFAllAzGraphResource -Query $advquery -subscriptionId $Subid

    return $queryResults
}

<#
.SYNOPSIS
Builds a custom object for each Azure Advisor recommendation.

.DESCRIPTION
The Build-WAFAdvisorObject function processes an array of Azure Advisor recommendations and builds a custom object for each recommendation.
It includes details such as recommendation ID, type, name, subscription ID, resource group, location, category, impact, and description.

.PARAMETER AdvisorObject
An array of Azure Advisor recommendations to process.

.OUTPUTS
Returns an array of custom objects representing the Azure Advisor recommendations.

.EXAMPLE
$advisorObject = Get-WAFAdvisorRecommendations -Subid $subIds -ScopeObject $scopeObject
$advisorDetails = Build-WAFAdvisorObject -AdvisorObject $advisorObject

.NOTES
This function assumes that the Get-WAFFilteredResourceList function is defined and available in the current context.
#>
function Build-WAFAdvisorObject {
    Param($AdvisorObject)

    $AllAdvisories = foreach ($row in $AdvisorObject) {
        if (![string]::IsNullOrEmpty($row.properties.resourceMetadata.resourceId)) {
            $TempResource = ''
            $TempResource = Get-WAFFilteredResourceList -ResourceID $row.properties.resourceMetadata.resourceId -List $ScopeObject
            $result = [PSCustomObject]@{
                recommendationId = [string]$row.properties.recommendationTypeId
                type             = [string]$row.Properties.impactedField
                name             = [string]$row.properties.impactedValue
                id               = [string]$row.properties.resourceMetadata.resourceId
                subscriptionId   = [string]$TempResource.subscriptionId
                resourceGroup    = [string]$TempResource.resourceGroup
                location         = [string]$TempResource.location
                category         = [string]$row.properties.category
                impact           = [string]$row.properties.impact
                description      = [string]$row.properties.shortDescription.solution
            }
            $result
        }
    }
    return $AllAdvisories
}