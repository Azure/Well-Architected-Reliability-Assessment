<#
.CLASS
    impactedResourceObj

.SYNOPSIS
    Represents a resource type object for APRL.

.DESCRIPTION
    The `aprlResourceTypeObj` class encapsulates the details of a resource type in APRL, including the number of resources, availability in APRL/ADVISOR, assessment owner, status, and notes.

.PROPERTY Resource Type
    The type of the resource.

.PROPERTY Number Of Resources
    The number of resources of this type.

.PROPERTY Available in APRL/ADVISOR?
    Indicates whether the resource type is available in APRL or ADVISOR.

.PROPERTY Assessment Owner
    The owner of the assessment.

.PROPERTY Status
    The status of the resource type.

.PROPERTY Notes
    Additional notes about the resource type.

.NOTES
    Author: Kyle Poineal
    Date: 2023-10-07
#>
class aprlResourceTypeObj {
    [string] ${Resource Type}
    [int] ${Number Of Resources}
    [string] ${Available in APRL/ADVISOR?}
    [string] ${Assessment Owner}
    [string] $Status
    [string] $Notes
}

<#
.CLASS
    validationResourceFactory

.PROPERTY  RecommendationObject
    The recommendation object.

.PROPERTY  validationResources
    The validation resources.

.SYNOPSIS
    Factory class to create resource type objects.

.DESCRIPTION
    The `resourceTypeFactory` class is responsible for creating instances of `aprlResourceTypeObj` based on impacted resources and types not in APRL or ADVISOR.

.CONSTRUCTORS
    resourceTypeFactory([PSObject]$impactedResourceObj, [PSObject]$TypesNotInAPRLOrAdvisor)
        Initializes a new instance of the `resourceTypeFactory` class.

.NOTES
    Author: Kyle Poineal
    Date: 2023-10-07
#>
class resourceTypeFactory {
    [PSObject]$impactedResourceObj
    [PSObject]$TypesNotInAPRLOrAdvisor

    resourceTypeFactory([PSObject]$impactedResourceObj, [PSObject]$TypesNotInAPRLOrAdvisor) {
        $this.impactedResourceObj = $impactedResourceObj | Group-Object -Property type | Select-Object Name, Count
        $this.TypesNotInAPRLOrAdvisor = $TypesNotInAPRLOrAdvisor
    }

    <#
    .CLASS
        aprlResourceTypeObj

    .METHOD
        createResourceTypeObjects

    .SYNOPSIS
        Creates resource type objects.

    .DESCRIPTION
        The `createResourceTypeObjects` method creates and returns an array of `aprlResourceTypeObj` instances based on the impacted resources and types not in APRL or ADVISOR.

    .OUTPUTS
        System.Object[]. Returns an array of `aprlResourceTypeObj` instances.

    .EXAMPLE
        $factory = [resourceTypeFactory]::new($impactedResourceObj, $TypesNotInAPRLOrAdvisor)
        $resourceTypes = $factory.createResourceTypeObjects()

    .NOTES
        Author: Kyle Poineal
        Date: 2023-10-07
    #>
    [object[]] createResourceTypeObjects() {
        $return = foreach ($type in $this.impactedResourceObj) {
            $r = [aprlResourceTypeObj]::new()
            $r.'Resource Type' = $type.Name
            $r.'Number Of Resources' = $type.Count
            $r.'Available in APRL/ADVISOR?' = $(($this.TypesNotInAPRLOrAdvisor -contains $type.Name) ? "No" : "Yes")
            $r.'Assessment Owner' = ""
            $r.Status = ""
            $r.notes = ""

            $r
        }
        return $return
    }
}

<#
.CLASS
    aprlResourceObj

.SYNOPSIS
    Represents an APRL resource object.

.DESCRIPTION
    The `aprlResourceObj` class encapsulates the details of an APRL resource, including validation action, recommendation ID, name, ID, type, location, subscription ID, resource group, parameters, check name, and selector.

.PROPERTY  validationAction
    The validation action for the resource.

.PROPERTY recommendationId
    The recommendation ID for the resource.

.PROPERTY name
    The name of the resource.

.PROPERTY id
    The ID of the resource.

.PROPERTY type
    The type of the resource.

.PROPERTY location
    The location of the resource.

.PROPERTY subscriptionId
    The subscription ID of the resource.

.PROPERTY resourceGroup
    The resource group of the resource.

.PROPERTY param1
    Additional parameter 1.

.PROPERTY param2
    Additional parameter 2.

.PROPERTY param3
    Additional parameter 3.

.PROPERTY param4
    Additional parameter 4.

.PROPERTY param5
    Additional parameter 5.

.PROPERTY checkName
    The check name for the resource.

.PROPERTY selector
    The selector for the resource.

.NOTES
    Author: Kyle Poineal
    Date: 2023-10-07
#>
class aprlResourceObj {
    [string] $validationAction
    [string] $recommendationId
    [string] $name
    [string] $id
    [string] $type
    [string] $location
    [string] $subscriptionId
    [string] $resourceGroup
    [string] $param1
    [string] $param2
    [string] $param3
    [string] $param4
    [string] $param5
    [string] $checkName
    [string] $selector
}

<#
.CLASS
    impactedResourceFactory

.PROPERTY  impactedResources
    The impacted resources.

.PROPERTY allResources
    All resources.

.PROPERTY  RecommendationObject
    The recommendation object.

.SYNOPSIS
    Factory class to create impacted resource objects.

.DESCRIPTION
    The `impactedResourceFactory` class is responsible for creating instances of `aprlResourceObj` based on impacted resources, all resources, and recommendation objects.

.CONSTRUCTORS
    impactedResourceFactory([PSObject]$impactedResources, [hashtable]$allResources, [hashtable]$RecommendationObject)
        Initializes a new instance of the `impactedResourceFactory` class.

.METHODS
    [object[]] createImpactedResourceObjects()
        Creates and returns an array of `aprlResourceObj` instances.

.NOTES
    Author: Kyle Poineal
    Date: 2023-10-07
#>
class impactedResourceFactory {
    [PSObject] $impactedResources
    [hashtable] $allResources
    [hashtable] $RecommendationObject

    impactedResourceFactory([PSObject]$impactedResources, [hashtable]$allResources, [hashtable]$RecommendationObject) {
        $this.impactedResources = $impactedResources
        $this.allResources = $allResources
        $this.RecommendationObject = $RecommendationObject
    }

    <#
    .CLASS
        impactedResourceFactory

    .METHOD
        createImpactedResourceObjects

    .SYNOPSIS
        Creates impacted resource objects.

    .DESCRIPTION
        The `createImpactedResourceObjects` method creates and returns an array of `aprlResourceObj` instances based on the impacted resources, all resources, and recommendation objects.

    .OUTPUTS
        System.Object[]. Returns an array of `aprlResourceObj` instances.

    .EXAMPLE
        $factory = [impactedResourceFactory]::new($impactedResources, $allResources, $RecommendationObject)
        $impactedResources = $factory.createImpactedResourceObjects()

    .NOTES
        Author: Kyle Poineal
        Date: 2023-10-07
    #>
    [object[]] createImpactedResourceObjects() {
        $return = foreach ($impactedResource in $this.impactedResources) {
            $r = [aprlResourceObj]::new()
            $r.validationAction = "APRL - Queries"
            $r.RecommendationId = $impactedResource.recommendationId
            $r.Name = $impactedResource.name
            $r.Id = $impactedResource.id
            $r.type = $this.RecommendationObject[$r.recommendationId].recommendationResourceType ?? $this.allResources[$r.id].type ?? "Unknown"
            $r.location = $this.allResources[$r.id].location ?? "Unknown"
            $r.subscriptionId = $this.allResources[$r.id].subscriptionId ?? $r.id.split("/")[2] ?? "Unknown"
            $r.resourceGroup = $this.allResources[$r.id].resourceGroup ?? $r.id.split("/")[4] ?? "Unknown"
            $r.Param1 = $impactedResource.param1
            $r.Param2 = $impactedResource.param2
            $r.Param3 = $impactedResource.param3
            $r.Param4 = $impactedResource.param4
            $r.Param5 = $impactedResource.param5
            $r.checkName = $impactedResource.checkName
            $r.selector = $impactedResource.selector ?? "APRL"
            $r
        }
        return $return
    }
}

<#
.CLASS
    validationResourceFactory

.SYNOPSIS
    Factory class to create validation resource objects.

.DESCRIPTION
    The `validationResourceFactory` class is responsible for creating instances of `aprlResourceObj` for validation purposes based on recommendation objects, validation resources, and types not in APRL or ADVISOR.

.CONSTRUCTORS
    validationResourceFactory([PSObject]$recommendationObject, [hashtable]$validationResources, [PSObject]$TypesNotInAPRLOrAdvisor)
        Initializes a new instance of the `validationResourceFactory` class.

.METHODS
    [object[]] createValidationResourceObjects()
        Creates and returns an array of `aprlResourceObj` instances for validation purposes.

    static [string] getValidationAction($query)
        Determines the validation action based on the query.

.PROPERTY recommendationObject
    The recommendation object.

.PROPERTY validationResources
    The validation resources.

.PROPERTY TypesNotInAPRLOrAdvisor
    Resource types that we want to create a recommendation for but do not have a recommendation for.

.NOTES
    Author: Kyle Poineal
    Date: 2023-10-07
#>
class validationResourceFactory {
    # This class is used to create validationResourceObj objects

    # Properties
    [PSObject] $recommendationObject # The recommendation object
    [hashtable] $validationResources # The validation resources
    [PSObject] $TypesNotInAPRLOrAdvisor # Resource types that we want to create a recommendation for but do not have a recommendation for.

    validationResourceFactory([PSObject]$recommendationObject, [hashtable]$validationResources, [PSObject]$TypesNotInAPRLOrAdvisor) {
        $this.recommendationObject = $recommendationObject
        $this.validationResources = $validationResources
        $this.TypesNotInAPRLOrAdvisor = $TypesNotInAPRLOrAdvisor
    }

    <#
    .CLASS
        validationResourceFactory

    .METHOD
        createValidationResourceObjects

    .SYNOPSIS
        Creates validation resource objects.

    .DESCRIPTION
        The `createValidationResourceObjects` method creates and returns an array of `aprlResourceObj` instances for validation purposes based on the recommendation objects, validation resources, and types not in APRL or ADVISOR.

    .OUTPUTS
        System.Object[]. Returns an array of `aprlResourceObj` instances for validation purposes.

    .EXAMPLE
        $factory = [validationResourceFactory]::new($recommendationObject, $validationResources, $TypesNotInAPRLOrAdvisor)
        $validationResources = $factory.createValidationResourceObjects()

    .NOTES
        Author: Kyle Poineal
        Date: 2023-10-07
    #>
    [object[]] createValidationResourceObjects() {
        $return = @()

        $return = foreach ($v in $this.validationResources.GetEnumerator()) {

            $impactedResource = $v.value

            $recommendationByType = $this.recommendationObject.where({ $_.automationAvailable -eq $false -and $impactedResource.type -eq $_.recommendationResourceType -and $_.recommendationMetadataState -eq "Active" -and [string]::IsNullOrEmpty($_.recommendationTypeId) })

            if ($recommendationByType) {
                foreach ($rec in $recommendationByType) {
                    $r = [aprlResourceObj]::new()
                    $r.validationAction = [validationResourceFactory]::getValidationAction($rec.query)
                    $r.recommendationId = $rec.aprlGuid
                    $r.name = $impactedResource.name
                    $r.id = $impactedResource.id
                    $r.type = $impactedResource.type
                    $r.location = $impactedResource.location
                    $r.subscriptionId = $impactedResource.subscriptionId
                    $r.resourceGroup = $impactedResource.resourceGroup
                    $r.param1 = ''
                    $r.param2 = ''
                    $r.param3 = ''
                    $r.param4 = ''
                    $r.param5 = ''
                    $r.checkName = ''
                    $r.selector = $impactedResource.selector ?? "APRL"
                    $r
                }
            }
            elseif ($impactedResource.type -in $this.TypesNotInAPRLOrAdvisor) {
                $r = [aprlResourceObj]::new()
                $r.validationAction = [validationResourceFactory]::getValidationAction("No Recommendations")
                $r.recommendationId = ''
                $r.name = $impactedResource.name
                $r.id = $impactedResource.id
                $r.type = $impactedResource.type
                $r.location = $impactedResource.location
                $r.subscriptionId = $impactedResource.subscriptionId
                $r.resourceGroup = $impactedResource.resourceGroup
                $r.param1 = ''
                $r.param2 = ''
                $r.param3 = ''
                $r.param4 = ''
                $r.param5 = ''
                $r.checkName = ''
                $r.selector = $impactedResource.selector ?? "APRL"
                $r
            }
            else {
                Write-Error "No recommendation found for $($impactedResource.type) with resource id $($impactedResource.id)"
            }
        }

        return $return
    }

    <#
    .CLASS
        validationResourceFactory

    .METHOD
        getValidationAction

    .SYNOPSIS
        Determines the validation action based on the query.

    .DESCRIPTION
        The `getValidationAction` method determines the validation action based on the provided query string.

    .PARAMETER query
        The query string to evaluate.

    .OUTPUTS
        System.String. Returns the validation action as a string.

    .EXAMPLE
        $action = [validationResourceFactory]::getValidationAction("No Recommendations")

    .NOTES
        Author: Kyle Poineal
        Date: 2023-10-07
    #>
    static [string] getValidationAction($query) {
        $return = switch -wildcard ($query) {
            "*development*" { 'IMPORTANT - Query under development - Validate Resources manually' }
            "*cannot-be-validated-with-arg*" { 'IMPORTANT - Recommendation cannot be validated with ARGs - Validate Resources manually' }
            "*Azure Resource Graph*" { 'IMPORTANT - Query under development - Validate Resources manually' }
            "No Recommendations" { 'IMPORTANT - Resource Type is not available in either APRL or Advisor - Validate Resources manually if applicable, if not delete this line' }
            default { "IMPORTANT - Query does not exist - Validate Resources Manually" }
        }
        return $return
    }
}

<#
.CLASS
    specializedResourceFactory

.PROPERTY recommendationObject
    The recommendation object.

.PROPERTY specializedResources
    The specialized resources.

.SYNOPSIS
    Factory class to create specialized resource objects.

.DESCRIPTION
    The `specializedResourceFactory` class is responsible for creating instances of `aprlResourceObj` for specialized resources based on recommendation objects.

.CONSTRUCTORS
    specializedResourceFactory([PSObject]$specializedResources, [PSObject]$RecommendationObject)
    Initializes a new instance of the `specializedResourceFactory` class.

.EXAMPLE
    $factory = [specializedResourceFactory]::new($specializedResources, $RecommendationObject)
    $specializedResources = $factory.createSpecializedResourceObjects()

.NOTES
    Author: Kyle Poineal
    Date: 2023-10-07
#>
class specializedResourceFactory {
    # This class is used to create specializedResourceObj objects

    # Properties
    [PSObject] $specializedResources # The specialized resources
    [PSObject] $RecommendationObject # The recommendation object

    specializedResourceFactory([PSObject]$specializedResources, [PSObject]$RecommendationObject) {
        $this.specializedResources = $specializedResources
        $this.RecommendationObject = $RecommendationObject
    }

    <#
    .CLASS
        specializedResourceFactory

    .METHOD
        createSpecializedResourceObjects

    .SYNOPSIS
        Creates specialized resource objects.

    .DESCRIPTION
        The `createSpecializedResourceObjects` method creates and returns an array of `aprlResourceObj` instances for specialized resources based on the recommendation objects.

    .OUTPUTS
        System.Object[]. Returns an array of `aprlResourceObj` instances for specialized resources.

    .EXAMPLE
        $factory = [specializedResourceFactory]::new($specializedResources, $RecommendationObject)
        $specializedResources = $factory.createSpecializedResourceObjects()

    .NOTES
        Author: Kyle Poineal
        Date: 2023-10-07
    #>
    [object[]] createSpecializedResourceObjects() {
        $return = foreach ($s in $this.specializedResources) {

            $thisType = $this.RecommendationObject.where({ $s -in $_.tags -and $_.recommendationMetadataState -eq "Active" })
            foreach ($type in $thisType) {
                $r = [aprlResourceObj]::new()
                $r.validationAction = [specializedResourceFactory]::getValidationAction($type.query)
                $r.recommendationId = $type.aprlGuid
                $r.name = ''
                $r.id = ''
                $r.type = $type.recommendationResourceType
                $r.location = ''
                $r.subscriptionId = ''
                $r.resourceGroup = ''
                $r.param1 = ''
                $r.param2 = ''
                $r.param3 = ''
                $r.param4 = ''
                $r.param5 = ''
                $r.checkName = ''
                $r.selector = "APRL"
                $r
            }
        }
        return $return
    }

    <#
    .CLASS
        specializedResourceFactory

    .METHOD
        getValidationAction

    .SYNOPSIS
        Determines the validation action based on the query.

    .DESCRIPTION
        The `getValidationAction` method determines the validation action based on the provided query string.

    .PARAMETER query
        The query string to evaluate.

    .OUTPUTS
        System.String. Returns the validation action as a string.

    .EXAMPLE
        $action = [specializedResourceFactory]::getValidationAction("No Recommendations")

    .NOTES
        Author: Kyle Poineal
        Date: 2023-10-07
    #>
    static [string] getValidationAction($query) {
        $return = switch -wildcard ($query) {
            "*development*" { 'IMPORTANT - Query under development - Validate Resources manually' }
            "*cannot-be-validated-with-arg*" { 'IMPORTANT - Recommendation cannot be validated with ARGs - Validate Resources manually' }
            "*Azure Resource Graph*" { 'IMPORTANT - Query under development - Validate Resources manually' }
            "No Recommendations" { 'IMPORTANT - Resource Type is not available in either APRL or Advisor - Validate Resources manually if applicable, if not delete this line' }
            default { "IMPORTANT - Query does not exist - Validate Resources Manually" }
        }
        return $return
    }
}
