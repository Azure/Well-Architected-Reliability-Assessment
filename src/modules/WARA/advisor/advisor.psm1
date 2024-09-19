function Get-WAFAdvisorRecommendations {
    Param($Subid,$ScopeObject)

    $advquery = "advisorresources | where type == 'microsoft.advisor/recommendations' and tostring(properties.category) in ('HighAvailability') | order by id"
    $queryResults = Invoke-WAFQuery  -Query $advquery -subscriptionId $Subid

    $AllAdvisories = foreach ($row in $queryResults) {
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